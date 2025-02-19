export type Cleaning =
	Instance |
    thread |
	RBXScriptConnection |
	() -> () |
	{destroy: (unknown) -> ()} |
	{Destroy: (unknown) -> ()} |
	{ Cleaning }

export type Piece<D = unknown> = {
	data: D
}

export type Entity = number

export type UsedAsEntity<D = unknown> = Entity | Piece<D>

export type Word = number
export type Mask = number

export type BitMap = { [Word]: Mask }
export type Record = { word: Word, mask: Mask }

export type EntityData<D = any | never> = { data: D }

export type Priority = number

export type QuerySettings<P...> = {
    query: () -> (P...),
    priority: number?
}

export type Trait<P...> = (Data, P...) -> ()

export type TraitRecord<P...> = {
    trait: Trait<P...>,
    name: string
}

export type Data = {
    registry: Registry,
    entity: Entity
}

export type Query<P... = ...any> = typeof(setmetatable({} :: queryFields<P...>, {} :: queryImpl<P...>))

type queryFields<P...> = {
    traits: { TraitRecord<P...> },
    settings: QuerySettings<P...>
}

type queryImpl<P...> = {
    __index: queryImpl<P...>,
    New: (settings: QuerySettings<P...>) -> (Query<P...>),
    trait: (self: Query<P...>, name: string, trait: (Data, P...) -> ()) -> (Query<P...>)
}

export type Registry = typeof(setmetatable({} :: RegistryFields, {} :: RegistryImpl))

type RegistryFields = {
    nextId: number,
    cachedPieces: { [Piece]: Entity },
    entityRecords: { [Entity]: Record },
    bitMaps: { [Entity]: BitMap },
    storage: { [Entity]: { [Entity]: EntityData } },
    queryStorage: { [Priority]: { Query } },
    queryMaps: { [Query]: BitMap },
    consumedQueries: { [Query]: { [Entity]: Cleaning } }
}

type RegistryImpl = {
    __index: RegistryImpl,
    New: () -> Registry,
    entity: (self: Registry) -> Entity,
    entityAt: (self: Registry, at: number) -> Entity,
    include: (self: Registry, queries: { Query }) -> (),
    match: (self: Registry, target: UsedAsEntity) -> (),
    add: <D>(self: Registry, target: UsedAsEntity, entity: UsedAsEntity<D>, data: D?) -> D?,
    contains: (self: Registry, target: UsedAsEntity, ...UsedAsEntity) -> boolean,
    ask: <D>(self: Registry, target: UsedAsEntity, entity: UsedAsEntity<D>) -> EntityData<D>?
}

return {}