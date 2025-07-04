--!optimize 2
--!native
--!strict
--!nolint LocalShadow

-- types

-- unique id for an entity
type id = number
export type entity<T = any> = { __t: T }

-- storage for temporary data passed to traits
type scope = { unknown }

-- function applied to entities matching a query
export type trait<usage = id> = (id: usage, scope: scope) -> ()

-- stores data for a single component across all entities in an archetype
type column = { any }

type set<T> = { [T]: boolean }

export type archetype_edge<usage = id> = { [usage]: archetype<usage> }

export type archetype<usage = id> = {
    track: { usage }, -- ordered list of component ids in this archetype
    hash: string, -- string identifier, e.g. '1_2_3'
    entities: { usage }, -- list of entities currently in this archetype
    columns: { column }, -- raw component data arrays
    columns_map: { [usage]: column }, -- maps component id to its column
    subs: set<archetype<usage>>, -- archetypes that are subsets of this one,
    supers: set<archetype<usage>>, -- archetypes that are supersets of this one
    traits: set<trait<usage>>, -- traits (callbacks) on this archetype,
    edge: archetype_edge<usage>
}

export type record<usage = id> = {
    archetype: archetype<usage>, -- current archetype the entity belongs to
    row: number, -- row index in the archetype's columns
}

type component_fields<T, usage = id> = {
    default: T,
    id: usage
}

type component_impl<T, usage = id> = {
    __call: (self: component_impl<T, usage>) -> T
}

export type component<T, usage = id> = typeof(setmetatable({} :: component_fields<T, usage>, {} :: component_impl<T, usage>))

type world_fields<usage = id> = {
    next_id: number,
    records: { [usage]: record<usage> },
    archetypes: { [string]: archetype<usage> }, -- map to hash -> archetype
    consumed: { [trait<usage>]: set<usage> }, -- tracks which traits were already called to which entity
    scopes: { [usage]: { [trait<usage>]: scope } }, -- per-entity scope storage used during trait execution
    component_index: { [usage]: set<string> } -- map to component -> { hash }
}

type world = typeof(setmetatable({} :: world_fields, {} :: world_impl))

local insert, remove = table.insert, table.remove

-- this
local world = {}
world.__index = world

-- constructor
function world.new(): mock_world
    local self = {
        next_id = 1,
        records = {},
        archetypes = {},
        component_index = {},
        consumed = {},
        scopes = {}
    }
    
    setmetatable(self, world)
    return self :: any
end

local function subset<A, B>(
    sub: { A | B }, 
    sup: { B | A }
): boolean
    local i, j = 1, 1

    -- traverse both lists
    while i <= #sub and j <= #sup do
        if sub[i] == sup[j] then
            -- found matching element, advance both pointers
            i += 1
            j += 1
        elseif sub[i] < sup[j] then
            -- sub[i] is less than sup[j], which means it can't be in sup
            return false
        else
            -- keep scanning sup for a match
            j += 1
        end
    end

    -- if we've checked all elements in sub, it's a subset
    return i > #sub
end

local function hash(
    track: { id }
): string
    return table.concat(track, '_')
end

local function create_archetype(
    track: { id },
    hash: string
): archetype
    local columns = table.create(#track)

    return {
        hash = hash,
        track = track,
        entities = {},
        columns = columns,
        columns_map = {},
        subs = {},
        supers = {},
        traits = {},
        edge = {}
    }
end

local function register_component_index(
    world: world,
    track: { id },
    hash: string,
    archetype: archetype
): set<archetype>
    local archetypes = world.archetypes
    local component_index = world.component_index
    local possible_subs = {}

    for i, component in ipairs(track) do
        local column = {}
        archetype.columns[i] = column
        archetype.columns_map[component] = column

        -- check if the current component has been added
        -- to an archetype before
        local component_archetypes = component_index[component]

        if component_archetypes then
            -- if so, add it as a possible sub archetype or a super archetype
            for archetype_hash in pairs(component_archetypes) do
                local other_archetype = archetypes[archetype_hash]

                possible_subs[other_archetype] = true
            end
        else
            local new_index = {}
            component_index[component] = new_index
            component_archetypes = new_index
        end

        component_archetypes[hash] = true
    end

    return possible_subs
end

local function link_sub_archetypes(
    world: world,
    archetype: archetype,
    track: { id }
)
    for _, other_archetype in pairs(world.archetypes) do
        if other_archetype == archetype then
            continue
        end

        local other_track = other_archetype.track

        if subset(other_track, track) then
            -- other is a subset of new
            archetype.subs[other_archetype] = true
            other_archetype.supers[archetype] = true

            -- copy traits from other to new archetype
            local traits = archetype.traits
            local other_traits = other_archetype.traits

            for trait in other_traits do
                traits[trait] = true
            end

        elseif subset(track, other_track) then
            -- new is a subset of other
            other_archetype.subs[archetype] = true
            archetype.supers[other_archetype] = true
        end
    end
end

local function ensure_archetype(
    world: world, 
    track: { id }
): archetype
    local hash = hash(track)
    local archetype = world.archetypes[hash]

    if archetype then
        return archetype
    end

    local new_archetype = create_archetype(track, hash)

    -- register components and collect related archetypes
    register_component_index(world, track, hash, new_archetype)

    -- link this archetype with others based on component subsets
    link_sub_archetypes(world, new_archetype, track)

    world.archetypes[hash] = new_archetype
    return new_archetype
end

local function ensure_record(
    world: world,
    entity: id
): record
    local records = world.records
    local record = records[entity]

    if record == nil then
        local root_archetype = ensure_archetype(world, {})

        -- insert entity on the archetype
        local row = #root_archetype.entities + 1
        insert(root_archetype.entities, entity)

        local new_record = {
            archetype = root_archetype,
            row = row,
        }

        records[entity] = new_record
        return new_record
    end

    return record
end

local function find_insert(
    track: { id },
    to_add: id
): number
    for i, id in track do

        if id == to_add then
            return -1
        end
        if id :: any > to_add then
            return i
        end
    end

    return #track + 1
end

local function archetype_transition_add(
    world: world,
    component: id,
    archetype: archetype
): archetype
    if archetype.columns_map[component] then
        return archetype
    end

    local edge = archetype.edge
    local cached_new_archetype = edge[component]

    if cached_new_archetype == nil then
        local track = archetype.track

        local at = find_insert(track, component)
        local new_track = {}

        for _, id in ipairs(track) do
            insert(new_track, id)
        end
        insert(new_track, at, component)
        local new_archetype = ensure_archetype(world, new_track)

        -- cache transition
        edge[component] = new_archetype
        new_archetype.edge[component] = archetype

        return new_archetype
    end

    return cached_new_archetype
end

local function archetype_transition_remove(
    world: world,
    component: id,
    archetype: archetype
): archetype
    local edge = archetype.edge
    local cached_new_archetype = edge[component]

    if cached_new_archetype == nil then
        local track = archetype.track

        local at = table.find(track, component)
        local new_track = {}

        for _, id in ipairs(track) do
            insert(new_track, id)
        end
        remove(new_track, at)

        local new_archetype = ensure_archetype(world, new_track)

        -- cache transition
        edge[component] = new_archetype
        new_archetype.edge[component] = archetype

        return new_archetype
    end

    return cached_new_archetype
end

local function archetype_query_transition(
    world: world,
    entity: id,
    archetype: archetype,
    single_trait: trait?
)
    local scopes = world.scopes
    local consumed = world.consumed
    local traits = archetype.traits

    if single_trait then
        traits = { [single_trait] = true }
    end

    if next(traits) == nil then
        return
    end

    local entity_scopes = scopes[entity]

    if entity_scopes == nil then
        entity_scopes = {}

        scopes[entity] = entity_scopes
    end

    for trait in traits do
        local trait_consumed = consumed[trait]

        if trait_consumed == nil then
            trait_consumed = {}

            consumed[trait] = trait_consumed
        end

        if trait_consumed[entity] then
            continue -- already applied, skip
        end

        local scope = {}
        entity_scopes[trait] = scope

        trait_consumed[entity] = true
        trait(entity, scope)
    end
end

local function archetype_query_cleanup(
    world: world,
    entity: id,
    archetype: archetype
)
    local scopes = world.scopes
    local consumed = world.consumed

    for trait in archetype.traits do
        local trait_consumed = consumed[trait]

        if not trait_consumed then
            continue
        end

        -- remove entity from this trait
        trait_consumed[entity] = nil

        local entity_scopes = scopes[entity]

        if entity_scopes then
            -- cleanup entity's scope attached to this trait
            -- clean(entity_scopes[trait])
            entity_scopes[trait] = nil
        end
    end
end

local function archetype_propagate_trait(
    world: world,
    archetype: archetype,
    trait: trait
)
    for _, id in pairs(archetype.entities) do
        archetype_query_transition(world, id, archetype, trait)
    end

    for super_archetype in pairs(archetype.supers) do
        archetype_propagate_trait(world, super_archetype, trait)
    end
end

local function world_query(
    world: world,
    ...: id
)
    local track = { ... }
    table.sort(track)

    local archetype = ensure_archetype(world, track)

    return function(trait: trait)
        -- call this trait for all entities
        archetype_propagate_trait(world, archetype, trait)

        -- cache trait in the archetype state
        archetype.traits[trait] = true
    end
end

local function archetype_swap_remove(
    world: world,
    old_row: id,
    old_archetype: archetype
)
    local entities = old_archetype.entities
    local last_index = #entities
    local entity = entities[old_row]
    local last_entity = entities[last_index]

    -- swap the last entity into the same slot
    -- unless it's the same entity
    if entity ~= last_entity then
        entities[old_row] = last_entity

        -- update the record of the moved entity
        local moving_record = world.records[last_entity]
        moving_record.row = old_row
    end

    -- remove last entity from archetype
    entities[last_index] = nil

    -- cleanup its columns
    for _, id in ipairs(old_archetype.track) do
        local column = old_archetype.columns_map[id]
        column[old_row] = column[last_index]
        column[last_index] = nil
    end
end

local function archetype_entity_move(
    world: world,
    new_archetype: archetype,
    entity: id,
    record: record
)
    local old_archetype = record.archetype
    local old_row = record.row

    local new_row = #new_archetype.entities + 1
    insert(new_archetype.entities, entity)

    -- move entity's data to the new archetype
    for i = 1, #new_archetype.track do
        local id = new_archetype.track[i]

        local column = new_archetype.columns_map[id]
        local old_column = old_archetype.columns_map[id]

        if old_column then
            column[new_row] = old_column[old_row]
        end
    end

    record.archetype = new_archetype
    record.row = new_row

    -- remove entity from the old archetype
    archetype_swap_remove(world, old_row, old_archetype)
end

local function archetype_track_queries(
    world: world,
    entity: id,
    old_archetype: archetype,
    new_archetype: archetype
)
    -- only remove scopes if the new archetype no longer satisfies the old one
    if new_archetype.supers[old_archetype] then
        archetype_query_cleanup(world, entity, old_archetype)
    end

    -- enable queries for the new archetype
    archetype_query_transition(world, entity, new_archetype)
end

local function world_assign<D>(
    world: world,
    entity: id,
    component: id,
    data: D?
): D?
    local record = world.records[entity]
    if record == nil then
        error(`entity {entity} does not exist`)
    end

    local old_archetype = record.archetype
    local old_row = record.row

    local new_archetype = archetype_transition_add(world, component, old_archetype)

    -- if the entity is on the correct archetype
    -- just rewrite its value
    if old_archetype == new_archetype then
        local column = old_archetype.columns_map[component]

        column[old_row] = data
        return data
    end

    if old_archetype then
        -- move entity to the new archetype
        archetype_entity_move(world, new_archetype, entity, record)
    end

    -- set component's data on the new archetype
    local column = new_archetype.columns_map[component]
    column[record.row] = data

    -- calling traits after data is set
    archetype_track_queries(world, entity, old_archetype, new_archetype)

    return data
end

local function world_remove(
    world: world,
    entity: id,
    component: id
)
    local record = world.records[entity]
    if record == nil then
        error(`entity {entity} does not exist`)
    end

    local old_archetype = record.archetype

    if old_archetype == nil then
        return
    end

    if old_archetype.columns_map[component] then
        local new_archetype = archetype_transition_remove(world, component, old_archetype)

        archetype_entity_move(world, new_archetype, entity, record)

        -- calling traits after data is removed
        archetype_track_queries(world, entity, old_archetype, new_archetype)
    end
end

local function world_has(
    world: world,
    entity: id,
    component: id
)
    local record = world.records[entity]

    if record == nil then
        return false
    end

    local archetype = record.archetype
    local archetype_set = world.component_index[component]

    if archetype_set == nil then
        return false
    end

    return archetype_set[archetype.hash] ~= nil
end

local function world_spawn(world: world)
    local next_id = world.next_id

    ensure_record(world, next_id)

    world.next_id += 1
    return next_id
end

local function world_despawn(
    world: world,
    entity: id
)
    local record = world.records[entity]
    if record == nil then
        error(`entity {entity} does not exist`)
    end

    local archetype = record.archetype
    local track = archetype.track

    for i = 1, #track do
        local component = track[i]
        world_remove(world, entity, component)
    end

    local new_archetype = record.archetype
    local new_row = record.row

    -- remove entity from root archetype
    archetype_swap_remove(world, new_row, new_archetype)

    -- remove it from world records
    world.records[entity] = nil
end

local function world_delete(
    world: world,
    entity: id
)
    local record = world.records[entity]
    if record == nil then
        error(`entity {entity} does not exist`)
    end

    local archetype = record.archetype
    local row = record.row

    archetype_query_cleanup(world, entity, archetype)
    archetype_swap_remove(world, row, archetype)

    world.records[entity] = nil
end

local function field(
    component: id,
    columns_map: { [id]: column },
    row: number
)
    local column = columns_map[component]

    if column == nil then
        return nil
    end

    return column[row]
end

local function world_ask<T>(
    world: world,
    entity: id,
    ...: id
): ...any
    local record = world.records[entity]
    assert(record, `entity {entity} does not exist`)

    local archetype = record.archetype

    if archetype == nil then
        return nil
    end

    local columns_map = archetype.columns_map
    local row = record.row

    local length = select('#', ...)
    local a, b, c, d, e = ...

    return length == 1 and
        field(a, columns_map, row)

        or length == 2 and
            field(a, columns_map, row),
            field(b, columns_map, row)

        or length == 3 and
            field(a, columns_map, row),
            field(b, columns_map, row),
            field(c, columns_map, row)

        or length == 4 and
            field(a, columns_map, row),
            field(b, columns_map, row),
            field(c, columns_map, row),
            field(d, columns_map, row)

        or length == 5 and
            field(a, columns_map, row),
            field(b, columns_map, row),
            field(c, columns_map, row),
            field(d, columns_map, row),
            field(e, columns_map, row)
end

local function component<T>(
    world: world,
    default: T
): () -> component<T>
    local id = world_spawn(world)

    local metadata = { id = id, default = default }
    local metatable = {}

    function metatable:__call()
        if typeof(default) == 'table' then
            local new_value: any = table.clone(default)

            return new_value
        end

        return default
    end

    setmetatable(metadata, metatable)

    return function()
        return metadata
    end
end

local function world_insert(
    world: world,
    entity: id,
    ...: undecided_component<unknown, any>
)
    local args = { ... }
    local i = 1

    while i <= #args do
        local entry = args[i]
        local next_val = args[i + 1]

        -- case 1: component metadata (has .id and .default)
        if typeof(entry) == 'table' and entry.id and entry.default ~= nil then
            world_assign(world, entity, entry.id, entry.default)
            i += 1

        -- case 2: direct component id followed by value or nil
        elseif typeof(entry) == 'number'  then
            local entry: any = entry
            world_assign(world, entity, entry, next_val)
            i += 2

        -- invalid usage: warn and break to avoid silent failure
        else
            error(`world:insert invalid argument at {i}: {entry}. Use world:assign instead`)
        end
    end
end

world.assign = world_assign
world.remove = world_remove
world.ask = world_ask
world.spawn = world_spawn
world.despawn = world_despawn
world.delete = world_delete
world.query = world_query
world.has = world_has
world.insert = world_insert
world.component = component

type undecided_component<T, Prev, usage = id> =
    component<T, usage> -- metadata table: { id, default }
    | usage -- component id
    | Prev -- fallback value for previous componen

type world_insert<world = world, usage = id> = <T, T1, T2, T3, T4, T5>(
    world: world,
    entity: usage,
    a: component<T, usage> | usage,
    b: undecided_component<T1, T, usage>?,
    c: undecided_component<T2, T1, usage>?,
    d: undecided_component<T3, T2, usage>?,
    e: undecided_component<T4, T3, usage>?,
    f: undecided_component<T5, T4, usage>?,
    g: T5?
) -> ()

type world_impl = {
    __index: world_impl,
    new: () -> world,
    assign: <D>(self: world, entity: id, component: id, data: D?) -> D?,
    remove: (self: world, entity: id, component: id) -> (),
    ask: (self: world, entity: id, ...id) -> ...any,
    spawn: (self: world) -> id,
    despawn: (self: world, entity: id) -> (),
    delete: (self: world, entity: id) -> (),
    query: (self: world, ...id) -> (trait: trait) -> (),
    has: (self: world, entity: id, component: id) -> boolean,
    insert: world_insert,
    component: <T>(world: world, default: T) -> () -> component<T>,
}

type world_ask<world = world> =
(<T>(self: world, id: entity, a: entity<T>) -> T?)
& (<T, T1>(self: world, id: entity, a: entity<T>, b: entity<T1>) -> (T?, T1?))
& (<T, T1, T2>(self: world, id: entity, a: entity<T>, b: entity<T1>, c: entity<T2>) -> (T?, T1?, T2?))
& (<T, T1, T2, T3>(self: world, id: entity, a: entity<T>, b: entity<T1>, c: entity<T2>, d: entity<T3>) -> (T?, T1?, T2?, T3?))
& (<T, T1, T2, T3, T4>(self: world, id: entity, a: entity<T>, b: entity<T1>, c: entity<T2>, d: entity<T3>, e: entity<T4>) -> (T?, T1?, T2?, T3?, T4?))

export type mock_world = world_fields<entity> & {
    __index: mock_world,
    new: () -> mock_world,
    assign: <D>(self: mock_world, entity: entity, component: entity<D>, data: D?) -> D?,
    remove: (self: mock_world, entity: entity, component: entity) -> (),
    ask: world_ask<mock_world>,
    spawn: (self: mock_world) -> entity,
    despawn: (self: mock_world, entity: entity) -> (),
    delete: (self: mock_world, entity: entity) -> (),
    query: (self: mock_world, ...entity) -> (trait: trait<entity>) -> (),
    has: (self: mock_world, entity: entity, component: entity) -> boolean,
    insert: world_insert<mock_world, entity>,
    component: <T>(world: mock_world, default: T) -> () -> component<T, entity>,
}

return world