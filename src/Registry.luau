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
        if bit32.band(targetMap[word] or 0, bits) ~= bits then
            return false
        end
    end

    return true
end

local function CallQueryRow(
    registry: Registry,
    row: { Query },
    entity: Entity
)
    local consumed = registry.consumedQueries
    local BitMap = registry.bitMaps[entity]

    local function callTraitsFromQuery(
        query: Query
    )
        if consumed[query] and consumed[query][entity] then return end

        for _, traitRecord in query.traits do
            local cleaning = {}
            local entityDatas = {}

            local data = {
                registry = registry,
                entity = entity,
                cleaning = cleaning
            }

            for _, piece in { query.settings.query() } do
                local storedData = registry:ask(entity, piece)
    
                table.insert(entityDatas, storedData)
            end
    
            local thread = task.spawn(
                traitRecord.trait,
                data, unpack(entityDatas)
            )
            table.insert(cleaning, thread)
    
            consumed[query] = consumed[query] or {}
            consumed[query][entity] = cleaning
        end
    end

    local function cleanupTraitsFromQuery(
        query: Query
    )
        for _, traitRecord in query.traits do
            local cleaning = consumed[query] and consumed[query][entity]
            if not cleaning then continue end

            consumed[query][entity] = nil

            if not next(consumed[query]) then
                consumed[query] = nil
            end

            Clean(cleaning)
        end
    end

    local function tryMatching(
        query: Query
    )
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
    entity: UsedAsEntity
)
    local castedEntity = CastToEntity(self, entity)

    for priority, row in self.queryStorage do
        CallQueryRow(self, row, castedEntity)
    end
end

function Registry.add<D>(
    self: Registry,
    entity: UsedAsEntity,
    piece: UsedAsEntity<D>,
    data: D?
): D?

    if self:contains(entity, piece) then return end
    
    local castedEntity = CastToEntity(self, entity)
    local castedPiece = CastToEntity(self, piece)

    local bitMaps = self.bitMaps
    local entityRecords = self.entityRecords

    if not bitMaps[castedEntity] then
        bitMaps[castedEntity] = {}
    end

    local map = bitMaps[castedEntity]

    local record = entityRecords[castedPiece]
    assert('Invalid entity: no record')

    map[record.word] = bit32.bor(map[record.word] or 0, record.mask)

    if not data and typeof(piece) == 'table' then
        data = piece.data
    end

    local storage = self.storage

    if not storage[castedEntity] then
        storage[castedEntity] = {}
    end

    local entityStorage = storage[castedEntity]
    
    if data then
        entityStorage[castedPiece] = { data = data }
    end

    self:match(castedEntity)

    return data
end

function Registry.remove<D>(
    self: Registry,
    entity: UsedAsEntity,
    piece: UsedAsEntity<D>
)
    local castedEntity = CastToEntity(self, entity)
    local castedPiece = CastToEntity(self, piece)

    local bitMaps = self.bitMaps
    local entityRecords = self.entityRecords

    local map = bitMaps[castedEntity]
    if not map then return end

    local record = entityRecords[castedPiece]
        or error('Invalid entity: no record')

    map[record.word] = bit32.band(map[record.word] or 0, bit32.bnot(record.mask))

    if map[record.word] == 0 then
        map[record.word] = nil
    end

    local storage = self.storage

    local entityStorage = storage[castedEntity]
    if not entityStorage then return end

    local storedData = entityStorage[castedPiece]
    if storedData then
        Clean(storedData)
        entityStorage[castedPiece] = nil
    end

    self:match(castedEntity)
end

function Registry.delete(
    self: Registry,
    entity: UsedAsEntity
)
    local castedEntity = CastToEntity(self, entity)

    local bitMaps = self.bitMaps
    local storage = self.storage

    if not bitMaps[castedEntity] then return end

    local entityStorage = storage[castedEntity]

    if entityStorage then
        for piece in entityStorage do
            self:remove(entity, piece)
        end

        storage[castedEntity] = nil
    end

    bitMaps[castedEntity] = nil

    if typeof(entity) == 'table' then
        self.cachedPieces[entity] = nil
    end
end

function Registry.contains(
    self: Registry,
    entity: UsedAsEntity,
    ...: UsedAsEntity
): boolean
    
    local castedEntity = CastToEntity(self, entity)

    local entityMap = self.bitMaps[castedEntity]
    if not entityMap then return false end

    for i = 1, select('#', ...) do

        local piece = select(i, ...)
        local castedPiece = CastToEntity(self, piece)
        
        local entityRecord = self.entityRecords[castedPiece]
        assert(entityRecord, 'Invalid entity: no record')

        local hasPiece = bit32.band(entityMap[entityRecord.word] or 0, entityRecord.mask)

        if hasPiece ~= entityRecord.mask then
            return false
        end
    end

    return true
end

function Registry.ask<D>(
    self: Registry,
    entity: UsedAsEntity,
    piece: UsedAsEntity<D>
): EntityData<D>?

    local castedEntity = CastToEntity(self, entity)

    local targetData = self.storage[castedEntity]
    assert(
        targetData,
        'Invalid entity: does not have data. Check using contains first'
    )

    local castedPiece = CastToEntity(self, piece)

    return targetData[castedPiece]
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