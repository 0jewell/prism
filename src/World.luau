local Prism = script.Parent

local Piece = require(Prism.Piece)
type Piece<D = unknown> = Piece.Piece<D>
type Entity = Piece.Entity

export type World = typeof(setmetatable({} :: worldFields, {} :: worldImpl))

local World = {}
World.__index = World

local component_piece = Piece.New()

local on_add_piece = Piece.New() :: Piece<onAddFunction>
type onAddFunction = (entity: Entity, piece: Piece, data: unknown) -> ()

function World.New(): World
    local self = {
        data = {},
        entityHas = {},
        cachedPieces = {},
        nextId = 1,
    }
    setmetatable(self, World)

    self:add(on_add_piece, component_piece)

    return self
end

function World.entity<P...>(
    self: World
): Entity

    return self:entityAt(self.nextId)
end

function World.entityAt<P...>(
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

function World.add<D>(
    self: World,
    entity: Entity | Piece<D>,
    piece: Piece<D>,
    data: D?
): D?

    local piecesCache = self.cachedPieces

    if not piecesCache[piece] then
        local pieceEntity = self:entity()
        self:add(pieceEntity, component_piece)

        piecesCache[piece] = pieceEntity
    end

    local e do 
        if typeof(entity) == 'number' then
            e = entity
        
        elseif typeof(entity) == 'table' then
            e = piecesCache[piece]
        end
    end
    
    local worldData = self.data

    if not worldData[e] then
        worldData[e] = {}
    end

    local pieceEntity = piecesCache[piece]
    
    self.entityHas[e][pieceEntity] = true
    
    if data then
        worldData[e][pieceEntity] = data

        local onAdd = self:ask(e, on_add_piece)

        if onAdd then
            onAdd(e, piece, data)
        end
    end

    return data
end

function World.ask<D>(
    self: World,
    entity: Entity,
    piece: Piece<D>
): D?

    local entityData = self.data[entity]
    if not entityData then return end

    local pieceEntity = self.cachedPieces[piece]
    if not pieceEntity then return end

    return entityData[pieceEntity]
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

        local pieceEntity = self.cachedPieces[piece]
        if not pieceEntity then return false end
        
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
    entityHas: { [Entity]: dataColumn<true> },
    nextId: number,
}

type worldImpl = {
    __index: worldImpl,
    New: () -> World,
    entity: <P...>(self: World) -> Entity,
    entityAt: <P...>(self: World, at: number) -> Entity,
    add: <D>(self: World, entity: Entity | Piece<D>, piece: Piece<D>, data: D?) -> D?,
    ask: <D>(self: World, entity: Entity, piece: Piece<D>) -> D?,
    contains: (self: World, entity: Entity, ...Piece) -> boolean
}

return table.freeze(World)