--!native
--!optimize 2
--!nolint LocalUnused

local Package = script.Parent

local Query = require(Package.Query)
type Query<Q...> = Query.Query<Q...>
type Trait<P...> = Query.Trait<P...>

local Piece = require(Package.Piece)
type Piece<D = unknown> = Piece.Piece<D>

local Clean = require(Package.Common.Clean)
type Cleaning = Clean.Cleaning

type Priority = number
type Hash = string

export type Entity = number
export type UsedAsEntity<D = unknown> = Entity | Piece<D>

type Word = number
type Mask = number

type EntityMap = { [Word]: Mask }

type Record = { word: Word, mask: Mask }

type EntityData = any | never

export type Registry = typeof(setmetatable({} :: RegistryFields, {} :: RegistryImpl))

local Registry = {}
Registry.__index = Registry

function Registry.New(): Registry
    local self = {
        nextId = 1,
        cachedPieces = {},
        entityRecords = {},
        entityMaps = {},
        storage = {},
        queryStorage = {},
        queryMaps = {},
        consumedTraits = {}
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
): EntityMap

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
    targetMap: EntityMap,
    queryMap: EntityMap
): boolean

    for word, bits in queryMap do
        if bit32.band(targetMap[word], bits) ~= bits then
			return false
		end
    end

    return true
end

function Registry.match(
    self: Registry,
    target: UsedAsEntity
)
    local consumed = self.consumedTraits

    local castedTarget = CastToEntity(self, target)
    local entityMap = self.entityMaps[castedTarget]

    for _, row in self.queryStorage do
        --// TODO: Clean this mess
        for _, query in row do
            local queryMap = self.queryMaps[query]
            local canMatch = CompareMapEntries(self, entityMap, queryMap)

            if canMatch then
                for _, trait in query.traits do
                    local scope, data = {}, { registry = self, entity = castedTarget }

                    table.insert(scope, task.spawn(trait))

                    consumed[trait] = consumed[trait] or {}
                    consumed[trait][castedTarget] = scope
                end
            else
                for _, trait in query.traits do
                    local scope = consumed[trait] and consumed[trait][castedTarget]
                    if not scope then continue end

                    consumed[trait][castedTarget] = nil

                    if not next(consumed[trait]) then
                        consumed[trait] = nil
                    end

                    Clean(scope)
                end
            end
        end
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

    local entityMaps = self.entityMaps
    local entityRecords = self.entityRecords

    local map = entityMaps[castedTarget]

    if not map then
        entityMaps[castedTarget] = {}

        map = entityMaps[castedTarget]
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
        storage[castedTarget][castedEntity] = data
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

    local targetMap = self.entityMaps[castedTarget]
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
): D?

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

type RegistryFields = {
    nextId: number,
    cachedPieces: { [Piece]: Entity },
    entityRecords: { [Entity]: Record },
    entityMaps: { [Entity]: EntityMap },
    storage: { [Entity]: { [Entity]: EntityData } },
    queryStorage: { [Priority]: { Query<...any> } },
    queryMaps: { [Query<...any>]: EntityMap },
    consumedTraits: { [Trait<...any>]: { [Entity]: Cleaning } }
}

type RegistryImpl = {
    __index: RegistryImpl,
    New: () -> Registry,
    entity: (self: Registry) -> Entity,
    entityAt: (self: Registry, at: number) -> Entity,
    include: (self: Registry, queries: { Query<...any> }) -> (),
    match: (self: Registry, target: UsedAsEntity) -> (),
    add: <D>(self: Registry, target: UsedAsEntity, entity: UsedAsEntity<D>, data: D?) -> D?,
    contains: (self: Registry, target: UsedAsEntity, ...UsedAsEntity) -> boolean,
    ask: <D>(self: Registry, target: UsedAsEntity, entity: UsedAsEntity<D>) -> D?
}

return table.freeze {
    New = Registry.New,

    pair = pair,
    unpackPair = unpackPair,

    AssembleQueryMap = AssembleQueryMap,
    CompareMapEntries = CompareMapEntries
}