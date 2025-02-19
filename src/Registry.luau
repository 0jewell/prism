--!native
--!optimize 2

local Package = script.Parent
local Types = require(Package.Common.Types)

local Clean = require(Package.Common.Clean)
type Cleaning = Types.Cleaning

type Entity = Types.Entity
type Piece<D = unknown> = Types.Piece<D>

type UsedAsEntity<D = unknown> = Types.UsedAsEntity<D>

type Query<Q... = ...any> = Types.Query<Q...>

type BitMap = Types.BitMap
type Record = Types.Record

type EntityData<D = any | never> = Types.EntityData<D>

type Registry = Types.Registry

local Registry = {}
Registry.__index = Registry

function Registry.New(): Registry
    local self = {
        nextId = 1,
        cachedPieces = {},
        entityRecords = {},
        bitMaps = {},
        storage = {},
        queryStorage = {},
        queryMaps = {},
        consumedQueries = {}
    }

    return setmetatable(self, Registry)
end

function Registry.entity(
    self: Registry
): Entity

    return self:entityAt(self.nextId)
end

function GenerateRecord(
    entity: Entity
): Record

    local wordIndex = math.floor((entity - 1) / 64) + 1
    local bitPosition = (entity - 1) % 64

    local record = {
        word = wordIndex,
        mask = bit32.lshift(1, bitPosition)
    }

    return record
end

function Registry.entityAt(
    self: Registry,
    at: number
): Entity

    if self:contains(at) then
        error('Invalid id: entity already exist')
    end

    if at >= self.nextId then
        self.nextId = at + 1
    end

    local record = GenerateRecord(at)
    self.entityRecords[at] = record

    return at
end

local function CastToEntity<D>(
    registry: Registry,
    target: UsedAsEntity<D>
): Entity
    
    if typeof(target) == 'number' then
        return target
    end

    assert(
        typeof(target) == 'table',
        'Invalid entity: not a piece or id'
    )

    local cached = registry.cachedPieces[target]
    if cached then return cached end

    local castedEntity = registry:entity()
    registry.cachedPieces[target] = castedEntity

    return castedEntity
end

local function AssembleQueryMap(
    registry: Registry,
    entities: { UsedAsEntity }
): BitMap

    local map = {}

    for _, entity in entities do
        local castedEntity = CastToEntity(registry, entity)

        local record = registry.entityRecords[castedEntity]
            or error('Invalid entity: no record')

        map[record.word] = bit32.bor(map[record.word] or 0, record.mask)
    end

    return map
end

function Registry.include<Q...>(
    self: Registry,
    queries: { Query<Q...> }
)
    for _, query in queries do

        local priority = query.settings.priority
            or error('Invalid query: must have priority')

        local queryStorage = self.queryStorage
        queryStorage[priority] = queryStorage[priority] or {}

        table.insert(queryStorage[priority], query)
        
        local querying = { query.settings.query() }
        local map = AssembleQueryMap(self, querying)

        self.queryMaps[query] = map
    end
end

local function CompareMapEntries(
    registry: Registry,
    targetMap: BitMap,
    queryMap: BitMap
): boolean

    for word, bits in queryMap do
        if bit32.band(targetMap[word], bits) ~= bits then
            return false
        end
    end

    return true
end

local function CallQueryRow(
    registry: Registry,
    row: { Query },
    target: Entity
)
    local consumed = registry.consumedQueries
    local BitMap = registry.bitMaps[target]

    local function callTraitsFromQuery(
        query: Query
    )

        for _, traitRecord in query.traits do
            local cleaning = {}
            local entityDatas = {}

            local data = {
                registry = registry,
                entity = target
            }

            for _, entity in { query.settings.query() } do
                local storedData = registry:ask(target, entity)
    
                table.insert(entityDatas, storedData)
            end
    
            task.spawn(traitRecord.trait, data, unpack(entityDatas))
    
            consumed[query] = consumed[query] or {}
            consumed[query][target] = cleaning
        end
    end

    local function cleanupTraitsFromQuery(
        query: Query
    )
        for _, traitRecord in query.traits do

            local cleaning = consumed[query] and consumed[query][target]
            if not cleaning then continue end

            consumed[query][target] = nil

            if not next(consumed[query]) then
                consumed[query] = nil
            end

            Clean(cleaning)
        end
    end

    local function tryMatching(
        query: Query
    )
        if consumed[query] and consumed[query][target] then return end
        
        local queryMap = registry.queryMaps[query]
        local canMatch = CompareMapEntries(registry, BitMap, queryMap)

        return if canMatch
            then callTraitsFromQuery(query)
            else cleanupTraitsFromQuery(query)
    end

    for _, query in row do
        tryMatching(query)
    end
end

function Registry.match(
    self: Registry,
    target: UsedAsEntity
)
    local castedTarget = CastToEntity(self, target)

    for priority, row in self.queryStorage do
        CallQueryRow(self, row, castedTarget)
    end
end

function Registry.add<D>(
    self: Registry,
    target: UsedAsEntity,
    entity: UsedAsEntity<D>,
    data: D?
): D?

    if self:contains(entity, target) then return end
    
    local castedTarget = CastToEntity(self, target)
    local castedEntity = CastToEntity(self, entity)

    local bitMaps = self.bitMaps
    local entityRecords = self.entityRecords

    local map = bitMaps[castedTarget]

    if not map then
        bitMaps[castedTarget] = {}

        map = bitMaps[castedTarget]
    end

    local record = entityRecords[castedEntity]
    assert('Invalid entity: no record')

    map[record.word] = bit32.bor(map[record.word] or 0, record.mask)

    if not data and typeof(entity) == 'table' then
        data = entity.data
    end

    local storage = self.storage

    if not storage[castedTarget] then
        storage[castedTarget] = {}
    end
    
    if data then
        storage[castedTarget][castedEntity] = { data = data }
    end

    self:match(castedTarget)

    return data
end

function Registry.contains(
    self: Registry,
    target: UsedAsEntity,
    ...: UsedAsEntity
): boolean
    
    local castedTarget = CastToEntity(self, target)

    local targetMap = self.bitMaps[castedTarget]
    if not targetMap then return false end

    for i = 1, select('#', ...) do

        local entity = select(i, ...)
        local castedEntity = CastToEntity(self, entity)
        
        local entityRecord = self.entityRecords[castedEntity]
        assert(entityRecord, 'Invalid entity: no record')

        local hasEntity = bit32.band(targetMap[entityRecord.word] or 0, entityRecord.mask)

        if hasEntity ~= entityRecord.mask then
            return false
        end
    end

    return true
end

function Registry.ask<D>(
    self: Registry,
    target: UsedAsEntity,
    entity: UsedAsEntity<D>
): EntityData<D>?

    local castedTarget = CastToEntity(self, target)

    local targetData = self.storage[castedTarget]
    assert(
        targetData,
        'Invalid entity: does not have data. Check using contains first'
    )

    local castedEntity = CastToEntity(self, entity)

    return targetData[castedEntity]
end

local FACTOR = 2 ^ 26

local function pair(
    relation: Entity,
    target: Entity
): Entity

    return relation * FACTOR + target
end

local function unpackPair(
    id: Entity
): (Entity, Entity)

    local relation = math.floor(id / FACTOR)
    local target = id % FACTOR

    return relation, target
end

return table.freeze {
    New = Registry.New,

    pair = pair,
    unpackPair = unpackPair,

    AssembleQueryMap = AssembleQueryMap,
    CompareMapEntries = CompareMapEntries
}