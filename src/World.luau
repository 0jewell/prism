local Prism = script.Parent

local Piece = require(Prism.Piece)
type Piece<D = nil> = Piece.Piece<D>
type Entity = Piece.Entity

type entityData = any | never

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

    local pieceId = piece.id
    assert(
        typeof(pieceId) == 'number',
        'Invalid piece: does not have an id'
    )

    if not worldData[entity] then
        worldData[entity] = {}
    end
    
    worldData[entity][pieceId] = data
    return data
end

function World.ask<D>(
    self: World,
    entity: Entity,
    piece: Piece<D>
): D?

    local pieceId = piece.id
    assert(
        typeof(pieceId) == 'number',
        'Invalid piece: does not have an id'
    )

    local entityData = self.data[entity]
    if not entityData then return end

    return entityData[pieceId]
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
        
        if not entityData[piece.id] then
            return false
        end
    end

    return true
end

export type World = typeof(World.New())

return table.freeze(World)