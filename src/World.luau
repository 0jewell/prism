local Prism = script.Parent

local Piece = require(Prism.Piece)
type Piece<D = nil> = Piece.Piece<D>
type Entity = Piece.Entity

export type World = typeof(setmetatable({} :: worldFields, {} :: worldImpl))

local World = {}
World.__index = World

function World.New(): World
    local self = { data = {} }

    return setmetatable(self, World)
end

function World.add<D>(
    self: World,
    entity: Entity,
    piece: Piece<D>,
    data: D
): D

    local worldData = self.data

    if not worldData[entity] then
        worldData[entity] = {}
    end
    
    worldData[entity][piece] = data
    return data
end

function World.ask<D>(
    self: World,
    entity: Entity,
    piece: Piece<D>
): D?

    local entityData = self.data[entity]
    if not entityData then return end

    return entityData[piece]
end

function World.contains(
    self: World,
    entity: Entity,
    ...: Piece
): boolean

    local entityData = self.data[entity]
    if not entityData then return false end

    for i = 1, select("#", ...) do

        local piece = select(i, ...)
        assert(
            typeof(piece) == 'table',
            'Invalid argument: not a piece'
        )
        
        if not entityData[piece] then
            return false
        end
    end

    return true
end

type entityData = any | never

type worldFields = { data: { [Entity]: {[Piece<unknown>]: entityData} } }

type worldImpl = {
    __index: worldImpl,
    New: () -> World,
    add: <D>(self: World, entity: Entity, piece: Piece<D>, data: D) -> D,
    ask: <D>(self: World, entity: Entity, piece: Piece<D>) -> D?,
    contains: (self: World, entity: Entity, ...Piece) -> boolean
}

return table.freeze(World)