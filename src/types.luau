-- types

-- unique id for an entity
export type id = number
export type entity<T = any> = { __t: T }

-- function applied to entities matching a query
export type scope = { unknown }
export type trait<usage = id> = (id: usage, clean: (...unknown) -> ()) -> ()

-- stores data for a single component across all entities in an archetype
export type column = { any }
export type set<T> = { [T]: boolean }

export type archetype_edge<usage = id> = { [usage]: archetype<usage> }

export type archetype<usage = id> = {
    track: { usage }, -- ordered list of component ids in this archetype
    hash: string, -- string identifier, e.g. '1_2_3'
    entities: { usage }, -- list of entities currently in this archetype
    columns: { column }, -- raw component data arrays
    columns_map: { [usage]: column }, -- maps component id to its column
    subs: set<archetype<usage>>, -- archetypes that are subsets of this one,
    supers: set<archetype<usage>>, -- archetypes that are supersets of this one
    traits: set<trait<usage>>, -- traits (callbacks) on this archetype (includes linked traits),
    edge: archetype_edge<usage>
}

export type record<usage = id> = {
    archetype: archetype<usage>, -- current archetype the entity belongs to
    row: number, -- row index in the archetype's columns
}

export type command_operation<content = any, usage = id> = content & {
    name: string,
    entity: usage,
    call: (operation: command_operation<content, usage>) -> ()
}

type world_fields<usage = id> = {
    next_id: number,
    records: { [usage]: record<usage> },
    archetypes: { [string]: archetype<usage> }, -- map to hash -> archetype
    consumed: { [trait<usage>]: set<usage> }, -- tracks which traits were already called to which entity
    scopes: { [usage]: { [trait<usage>]: scope } }, -- per-entity scope storage used during trait execution
    indexes: { [usage]: set<string> }, -- map to component -> { hash },
    commands: { [usage]: { command_operation } },
    to_despawn: set<usage>,
    deferred: set<usage>
}

export type world = world_fields & world_impl

type world_impl = {
    insert: <T>(entity: id, component: id, data: T?) -> (),
    remove: (entity: id, component: id) -> (),
    get: (entity: id, ...id) -> ...any,
    spawn: () -> id,
    despawn: (entity: id) -> (),
    query: (...id) -> (trait: trait) -> () -> (),
    has: (entity: id, component: id?) -> boolean,
}

type world_get<world = world> =
(<T>(id: entity, a: entity<T>) -> T)
& (<T, T1>(id: entity, a: entity<T>, b: entity<T1>) -> (T, T1))
& (<T, T1, T2>(id: entity, a: entity<T>, b: entity<T1>, c: entity<T2>) -> (T, T1, T2))
& (<T, T1, T2, T3>(id: entity, a: entity<T>, b: entity<T1>, c: entity<T2>, d: entity<T3>) -> (T, T1, T2, T3))
& (<T, T1, T2, T3, T4>(id: entity, a: entity<T>, b: entity<T1>, c: entity<T2>, d: entity<T3>, e: entity<T4>) -> (T, T1, T2, T3, T4))

export type mock_world = world_fields<entity> & {
    insert: <T>(entity: entity, component: entity<T>, data: T?) -> (),
    remove: (entity: entity, component: entity) -> (),
    get: world_get<mock_world>,
    spawn: () -> entity,
    despawn: (entity: entity) -> (),
    query: (...entity) -> (trait: trait<entity>) -> () -> (),
    has: (entity: entity, component: entity?) -> boolean,
}

return {}