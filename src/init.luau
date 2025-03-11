local Lib = require(script.lib)

export type Registry = Lib.Registry
export type Entity = Lib.Entity

export type Query<P... = ...any> = Lib.Query<P...>

export type Piece<D = unknown> = Lib.Piece<D>

export type Data  = Lib.Data
export type UsedAs<D = never> = Lib.UsedAs<D>

return Lib