local Registry = require(script.Registry)
export type Registry = Registry.Registry
export type Entity = Registry.Entity
export type UsedAsEntity<D = nil> = Registry.UsedAsEntity<D>

local Query = require(script.Query)
export type Query<P...> = Query.Query<P...>

local Piece = require(script.Piece)
export type Piece<D = unknown> = Piece.Piece<D>

return table.freeze {
    Registry = Registry.New,
    Query = Query.New,
    Piece = Piece.New,

    mapQuery = Registry.mapQuery,
    match = Registry.match
}