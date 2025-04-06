export type Cleaning =
    Instance
    | RBXScriptConnection
    | () -> ()
    | { destroy: (unknown) -> () }
    | { Destroy: (unknown) -> () }
    | { Cleaning }
    | thread

export type Piece<D = unknown> = {
    data: D
}

export type Tags = typeof(setmetatable({} :: TagsFields, {} :: TagsImpl))

type TagsFields = { [UsedAs]: Piece }
type TagsImpl = {[Piece]: boolean}

export type OnAdd = (entity: Entity, piece: Entity, data: unknown) -> ()
export type OnRemove = (entity: Entity, piece: Entity) -> ()

export type Entity = number
export type EntityData = { data: any }

export type UsedAs<D = unknown> = Entity | Piece<D>

export type Word = number
export type Mask = number

export type Bitmap = { [Word]: Mask }
export type DataMap = { [UsedAs]: any }

export type Record = {
    word: Word,
    mask: Mask,
    bitmap: Bitmap
}

export type Priority = number

export type QuerySettings<P...> = {
    query: () -> P...,
    priority: number?
}

export type Data = {
    registry: Registry,
    entity: Entity,
    cleaning: { Cleaning }
}

export type Trait<P...> = (Data, P...) -> ()

export type TraitRecord<P...> = {
    trait: Trait<P...>,
    name: string
}

export type Query<P... = ...any> = typeof(setmetatable({} :: QueryFields<P...>, {} :: QueryImpl<P...>))

type QueryFields<P...> = {
    traits: { TraitRecord<P...> },
    settings: QuerySettings<P...>
}
type QueryImpl<P...> = {
    __index: QueryImpl<P...>,
    New: (settings: QuerySettings<P...>) -> Query<P...>,
    trait: (self: Query<P...>, name: string, trait: (Data, P...) -> ()) -> Query<P...>
}

export type Registry = typeof(setmetatable({} :: RegistryFields, {} :: RegistryImpl))

type RegistryFields = {
    nextId: number,
    size: number,
    cachedPieces: { [Piece]: Entity },
    records: { [Entity]: Record },
    storage: { [Entity]: { [Entity]: Piece<any> } },
    queryStorage: { [Priority]: { Query } },
    queryMaps: { [Query]: Bitmap },
    consumedQueries: { [Query]: { [Entity]: Cleaning } }
}
type RegistryImpl = {
    __index: RegistryImpl,
    New: () -> Registry,
    entity: (self: Registry) -> Entity,
    entityAt: (self: Registry, at: number) -> Entity,
    cast: (self: Registry, ...UsedAs) -> ...Entity,
    pair: (self: Registry, relation: UsedAs, target: UsedAs) -> Entity,
    include: <Q...>(self: Registry, queries: { Query<Q...> }) -> (),
    match: (self: Registry, entity: UsedAs) -> (),
    add: <D>(self: Registry, entity: UsedAs, piece: UsedAs<D> | DataMap, data: D?) -> (D | DataMap)?,
    remove: (self: Registry, entity: UsedAs, piece: UsedAs) -> (),
    delete: (self: Registry, entity: UsedAs) -> (),
    contains: (self: Registry, entity: UsedAs, ...UsedAs) -> boolean,
    ask: <D>(self: Registry, entity: UsedAs, piece: UsedAs<D>) -> Piece<D>?
}

return {}