local Types = require(script.Common.Types)

local Data = require(script.Common.Data)
local Clean = require(script.Common.Clean)

local Registry = require(script.Registry)
export type Registry = Types.Registry
export type Entity = Types.Entity
export type EntityData = Types.EntityData

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

    from = Piece.from,

    AssembleQueryMap = Registry.AssembleQueryMap,
    CompareMapEntries = Registry.CompareMapEntries,

    MergeData = Data.merge,
    Clean = Clean
}