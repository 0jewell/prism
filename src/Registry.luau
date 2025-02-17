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

        --[[
        if self:contains(at) then
            error('Invalid id: entity already exist')
        end
        ]]
    
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

    function Registry.add(
        self: Registry,
        target: UsedAsEntity,
        entity: UsedAsEntity
    )
        
        local castedTarget = CastToEntity(self, target)
        local castedEntity = CastToEntity(self, entity)
    end
end

type RegistryFields = {
    nextId: number,
    cachedPieces: { [Piece]: Entity },
    entityRecords: { [Entity]: Record },
    data: { [Entity]: DataColumn<EntityData> }
}

type RegistryImpl = {
    __index: RegistryImpl,
    New: () -> Registry,
    entity: (self: Registry) -> Entity,
    entityAt: (self: Registry, at: number) -> Entity,
    add: (self: Registry, target: UsedAsEntity, entity: UsedAsEntity) -> ()
}

return Registry