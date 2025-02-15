local Prism = script.Parent

local Piece = require(Prism.Piece)
type Piece<D = unknown> = Piece.Piece<D>
type Entity = Piece.Entity
type usedAsEntity<D> = Piece.usedAsEntity<D>

export type World = typeof(setmetatable({} :: worldFields, {} :: worldImpl))

local component_piece = Piece.New()

local on_add_piece = Piece.New() :: Piece<onAddFunction>
type onAddFunction = <D>(entity: Entity, target: Entity, data: unknown) -> ()

local SHIFT = 26
local FACTOR = 2 ^ SHIFT

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

local World = {}
World.__index = World

function World.New(): World
    local self = {
        data = {},
        entityMap = {},
        cachedPieces = {},
        nextId = 1,
    }
    setmetatable(self, World)

    self:add(component_piece, component_piece)
    self:add(on_add_piece, component_piece)

    return self
end

function World.entity(
    self: World
): Entity

    return self:entityAt(self.nextId)
end

function World.entityAt(
    self: World,
    at: number
): Entity

    if self:contains(at) then
        error('Invalid id: existing entity')
    end

    if at >= self.nextId then
		self.nextId = at + 1
	end

    return at
end

local function castToEntity<D>(
    world: World,
    target: usedAsEntity<D>
): Entity

    local piecesCache = world.cachedPieces

    if typeof(target) ~= 'table' then
        assert(
            typeof(target) == 'number',
            'Invalid target: not a piece table or number'
        )
        return target
    end

    if piecesCache[target] then
        return piecesCache[target]
    end

    local pieceEntity = world:entity()

    piecesCache[target] = pieceEntity
    return pieceEntity
end

function World.add<D>(
    self: World,
    entity: usedAsEntity<D>,
    target: usedAsEntity<D>,
    data: D?
): D?

    if self:contains(entity, target) then return end

    local entityCast = castToEntity(self, entity)
    local targetCast = castToEntity(self, target)
    
    local worldData = self.data
    local entityMap = self.entityMap

    if not worldData[entityCast] then
        worldData[entityCast] = {}
    end

    if not entityMap[entityCast] then
        entityMap[entityCast] = {}
    end

    entityMap[entityCast][targetCast] = true
    
    if data then
        worldData[entityCast][targetCast] = data

        local onAdd = self:ask(entityCast, on_add_piece)

        if onAdd then
            onAdd(entityCast, targetCast, data)
        end
    end

    return data
end

function World.ask<D>(
    self: World,
    entity: Entity,
    target: usedAsEntity<D>
): D?

    local entityData = self.data[entity]
    assert(
        entityData,
        'Invalid entity: does not have data. Check using contains first'
    )

    local pieceEntity = castToEntity(self, target)

    return entityData[pieceEntity]
end

function World.contains<D>(
    self: World,
    entity: usedAsEntity<D>,
    ...: usedAsEntity<D>
): boolean

    local entityCast = castToEntity(self, entity)

    local entityData = self.data[entityCast]
    if not entityData then return false end

    for i = 1, select("#", ...) do

        local piece = select(i, ...)
        local pieceEntity = castToEntity(self, piece)
        
        if not entityData[pieceEntity] then
            return false
        end
    end

    return true
end

type entityData = any | never
type dataColumn<D> = { [Entity]: D }

type worldFields = {
    data: { [Entity]: dataColumn<entityData> },
    cachedPieces: { [Piece]: Entity },
    entityMap: { [Entity]: dataColumn<true> },
    nextId: number,
}

type worldImpl = {
    __index: worldImpl,
    New: () -> World,
    entity: (self: World) -> Entity,
    entityAt: (self: World, at: number) -> Entity,
    add: <D>(self: World, entity: usedAsEntity<D>, target: usedAsEntity<D>, data: D?) -> D?,
    ask: <D>(self: World, entity: Entity, target: usedAsEntity<D>) -> D?,
    contains: <D>(self: World, entity: usedAsEntity<D>, ...usedAsEntity<D>) -> boolean
}

return {
    New = World.New,

    component = component_piece,
    on_add = on_add_piece,

    pair = pair,
    unpackPair = unpackPair
}