local Types = require(script.Common.Types)

local Registry = require(script.Registry)
export type Registry = Types.Registry
export type Entity = Types.Entity

local Query = require(script.Query)
export type Query<P... = ...any> = Types.Query<P...>

local Piece = require(script.Piece)
export type Piece<D = unknown> = Types.Piece<D>

export type Data  = Types.Data
export type UsedAsEntity<D = unknown> = Types.UsedAsEntity<D>

return table.freeze {
    Registry = Registry.New,
    Query = Query.New,
    Piece = Piece.New,

    AssembleQueryMap = Registry.AssembleQueryMap,
    CompareMapEntries = Registry.CompareMapEntries
}