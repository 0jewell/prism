local Types = require('./Types')

local Clean = require('./Modules/Clean')

local Registry = require('./Registry')
export type Registry = Types.Registry
export type Entity = Types.Entity

local Query = require('./Query')
export type Query<P... = ...any> = Types.Query<P...>

local Piece = require('./Piece')
local Key = Piece.key
local From = Piece.from
export type Piece<D = unknown> = Types.Piece<D>
export type UsedAs<D = never> = Types.UsedAs<D>

export type Data  = Types.Data

return table.freeze {
    Registry = Registry.New,
    Query = Query.New,
    Piece = Piece.New,

    from = From,
    key = Key,
    Clean = Clean,

    OnAdd = Piece.OnAdd,
    OnRemove = Piece.OnRemove,
    BuiltInPiece = Piece.BuiltInPiece
}