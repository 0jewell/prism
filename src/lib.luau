local Types = require('./Types')

local Clean = require('./Modules/Clean')

local Registry = require('./Registry')
export type Registry = Types.Registry
export type Entity = Types.Entity

local Query = require('./Query')
export type Query<P... = ...any> = Types.Query<P...>

local Piece = require('./Piece')
local Tag = Piece.tag
local Tags = Piece.tags
local From = Piece.from
export type Piece<D = unknown> = Types.Piece<D>
export type UsedAs<D = never> = Types.UsedAs<D>

export type Data  = Types.Data

return table.freeze {
    Registry = Registry.New,
    Query = Query.New,
    Piece = Piece.New,

    from = From,
    tag = Tag,
    tags = Tags,
    Clean = Clean,

    OnAdd = Piece.OnAdd,
    OnRemove = Piece.OnRemove,
    BuiltInPiece = Piece.BuiltInPiece
}