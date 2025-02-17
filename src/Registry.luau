--!native
--!optimize 2
--!nolint LocalUnused

local Piece = require(script.Parent.Piece)
type Piece<D = nil> = Piece.Piece

export type Entity = number

export type UsedAsEntity<D = nil> = Entity | Piece<D>

type Word = number
type Mask = number

type EntityMap = { [Word]: Mask }

type Record = { word: Word, mask: Mask }

type DataColumn<D> = { [Entity]: D }
type EntityData = any | never

export type Registry = typeof(setmetatable({} :: RegistryFields, {} :: RegistryImpl))

local Registry = {}
Registry.__index = Registry

do
    function Registry.New(): Registry
        local self = {
            nextId = 1,
            cachedPieces = {},
            entityRecords = {},
            entityMaps = {},
            data = {}
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

    function CastToEntity(
        registry: Registry,
        target: UsedAsEntity
    ): Entity
        
        if typeof(target) == 'number' then
            return target
        end

        if typeof(target) ~= 'table' then
            error('Invalid entity: not a piece or id')
        end

        local cached = registry.cachedPieces[target]
        if cached then return cached end

        local castedEntity = registry:entity()
        registry.cachedPieces[target] = castedEntity

        return castedEntity
    end

    function Registry.add<D>(
        self: Registry,
        target: UsedAsEntity,
        entity: UsedAsEntity,
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

        if not data and typeof(target) == 'table' then
            data = target.data
        end
        
        if data then
            self.data[castedTarget][castedEntity] = data
        end

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

            local hasEntity = bit32.band(
                targetMap[entityRecord.word] or 0,
                entityRecord.mask
            )

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

        local targetData = self.data[castedTarget]
        assert(
            targetData,
            'Invalid entity: does not have data. Check using contains first'
        )

        local castedEntity = CastToEntity(self, entity)

        return targetData[castedEntity]
    end
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

--// Drafting
local function createQueryMap(
    registry: Registry,
    entities: { UsedAsEntity }
): EntityMap

    local map = {}

    for _, entity in entities do
        local castedEntity = CastToEntity(registry, entity)

        local record = registry.entityRecords[castedEntity]
        assert(record, 'Invalid entity: no record')

        map[record.word] = bit32.bor(map[record.word] or 0, record.mask)
    end

    return map
end

local function match(
    registry: Registry,
    entity: UsedAsEntity,
    queryMap: EntityMap
): boolean

    local castedEntity = CastToEntity(registry, entity)

    local entityMap = registry.entityMaps[castedEntity]
    assert(entityMap, 'Invalid entity, no map')
    
    for word, bits in queryMap do
        
        if bit32.band(entityMap[word], bits) ~= bits then
			return false
		end
    end

    return true
end

type RegistryFields = {
    nextId: number,
    cachedPieces: { [Piece]: Entity },
    entityRecords: { [Entity]: Record },
    entityMaps: { [Entity]: EntityMap },
    data: { [Entity]: DataColumn<EntityData> }
}

type RegistryImpl = {
    __index: RegistryImpl,
    New: () -> Registry,
    entity: (self: Registry) -> Entity,
    entityAt: (self: Registry, at: number) -> Entity,
    add: <D>(self: Registry, target: UsedAsEntity, entity: UsedAsEntity, data: D?) -> D?,
    contains: (self: Registry, target: UsedAsEntity, entity: UsedAsEntity) -> boolean,
    ask: <D>(self: Registry, target: UsedAsEntity, entity: UsedAsEntity<D>) -> D?
}

return table.freeze {
    New = Registry.New,

    pair = pair,
    unpackPair = unpackPair,

    mapQuery = createQueryMap,
    match = match
}