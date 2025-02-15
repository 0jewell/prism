local World = require(script.World)
export type World = World.World

local Query = require(script.Query)
export type Query<P...> = Query.Query<P...>

local Piece = require(script.Piece)
export type Piece<D = unknown> = Piece.Piece<D>
export type Entity = Piece.Entity
export type usedAsEntity<D> = Piece.usedAsEntity<D>

return table.freeze {
    World = World.New,
    Query = Query.New,
    Piece = Piece.New,

    from = Piece.from,

    component = World.component,
    on_add = World.on_add,

    pair = World.pair,
    unpackPair = World.unpackPair
}