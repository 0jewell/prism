local Types = require(script.Common.Types)

local Data = require(script.Common.Data)
local Clean = require(script.Common.Clean)

local Registry = require(script.Registry)
export type Registry = Types.Registry
export type Entity = Types.Entity

local Query = require(script.Query)
export type Query<P... = ...any> = Types.Query<P...>

local Piece = require(script.Piece)
export type Piece<D = unknown> = Types.Piece<D>

export type Data  = Types.Data
export type UsedAs<D = never> = Types.UsedAs<D>

return table.freeze {
    Registry = Registry.New,
    Query = Query.New,
    Piece = Piece.New,

    from = Piece.from,

    MergeData = Data.merge,
    Clean = Clean
}