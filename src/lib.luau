local Types = require('./Types')

local Clean = require('./Modules/Clean')

local Registry = require('./Registry')
export type Registry = Types.Registry
export type Entity = Types.Entity

local Query = require('./Query')
export type Query<P... = ...any> = Types.Query<P...>

local Piece = require('./Piece')
local from = Piece.from
export type Piece<D = unknown> = Types.Piece<D>

export type Data  = Types.Data
export type UsedAs<D = never> = Types.UsedAs<D>

return table.freeze {
    Registry = Registry.New,
    Query = Query.New,
    Piece = Piece.New,

    from = from,
    Clean = Clean,

    OnAdd = Piece.OnAdd,
    OnRemove = Piece.OnRemove,
    BuiltInPiece = Piece.BuiltInPiece
}