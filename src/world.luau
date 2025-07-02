--!optimize 2
--!native
-- types

-- unique id for an entity
export type entity = number
type i53 = number

-- storage for temporary data passed to traits
type scope = { unknown }

-- function applied to entities matching a query
export type trait = (id: entity, scope: scope) -> ()

-- stores data for a single component across all entities in an archetype
type column = { unknown }

type set<T> = { [T]: boolean }

type archetype_edge = { [entity]: archetype }

export type archetype = {
    track: { entity }, -- ordered list of component ids in this archetype
    hash: string, -- string identifier, e.g. '1_2_3'
    entities: { entity }, -- list of entities currently in this archetype
    columns: { column }, -- raw component data arrays
    columns_map: { [entity]: column }, -- maps component id to its column
    subs: set<archetype>, -- archetypes that are subsets of this one,
    supers: set<archetype>, -- archetypes that are supersets of this one
    traits: set<trait>, -- traits (callbacks) on this archetype,
    edge: archetype_edge
}

export type record = {
    archetype: archetype, -- current archetype the entity belongs to
    row: number, -- row index in the archetype's columns
}

type component_fields<T> = {
    default: T,
    id: entity 
}

type component_impl<T> = {
    __call: (self: component_impl<T>) -> T
}

export type component<T> = typeof(
    setmetatable({} :: component_fields<T>, {} :: component_impl<T>)
)

local insert, remove = table.insert, table.remove

-- this
local world = {}
world.__index = world

-- constructor
function world.new(): world
    local self = {
        next_id = 1,
        records = {},
        archetypes = {},
        component_index = {},
        consumed = {},
        scopes = {}
    }
    
    setmetatable(self, world)
    return self
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
    track: { entity }
): string
    return table.concat(track, '_')
end

local function create_archetype(
    track: { entity },
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
    track: { entity },
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
    track: { entity }
)
    for _, other_archetype in pairs(world.archetypes) do
        if other_archetype == archetype then
            continue
        end

        local other_track = other_archetype.track
        if #other_track == 0 then
            continue
        end

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
    track: { entity }
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
    entity: entity
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
    track: { entity },
    to_add: entity
): number
    for i, id in track do

        if id == to_add then
            return -1
        end
        if id > to_add then
            return i
        end
    end

    return #track + 1
end

local function archetype_transition_add(
    world: world,
    component: entity,
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
    component: entity,
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
    entity: entity,
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
    entity: entity,
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
    ...: entity
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
    entity: entity,
    old_row: number,
    old_archetype: archetype
)
    local entities = old_archetype.entities
    local last_index = #entities
    local last_entity = entities[last_index]

    -- swap the last entity into the same slot
    -- unless it's the same entity
    if entity ~= last_entity then
        entities[old_row] = last_entity

        -- update the record of the moved entity
        local moved_record = world.records[last_entity]
        moved_record.row = old_row

        for _, id in ipairs(old_archetype.track) do
            local column = old_archetype.columns_map[id]
            column[old_row] = column[last_index]
        end
    end

    -- remove last entity from archetype
    remove(entities, last_index)

    -- cleanup its columns
    for _, id in ipairs(old_archetype.track) do
        local column = old_archetype.columns_map[id]
        column[last_index] = nil
    end
end

local function archetype_entity_move(
    world: world,
    new_archetype: archetype,
    entity: entity,
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
    archetype_swap_remove(world, entity, old_row, old_archetype)

    -- only remove scopes if the new archetype no longer satisfies the old one
    if new_archetype.supers[old_archetype] then
        archetype_query_cleanup(world, entity, old_archetype)
    end

    -- enable queries for the new archetype
    archetype_query_transition(world, entity, new_archetype)
end

local function world_assign<D>(
    world: world,
    entity: entity,
    component: entity,
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

    return data
end

local function world_remove(
    world: world,
    entity: entity,
    component: entity
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
    end
end

local function world_has(
    world: world,
    entity: entity,
    component: entity
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
    entity: entity
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
    archetype_swap_remove(world, entity, new_row, new_archetype)

    -- remove it from world records
    world.records[entity] = nil
end

local function field(
    component: entity,
    columns_map: { [number]: column },
    row: number
): any?
    local column = columns_map[component]

    if column == nil then
        return nil
    end

    return column[row]
end

local function world_ask(
    world: world,
    entity: entity,
    component: entity
): any?
    local record = world.records[entity]
    assert(record, `entity {entity} does not exist`)

    local archetype = record.archetype

    if archetype == nil then
        return nil
    end

    local columns_map = archetype.columns_map
    local row = record.row

    return field(component, columns_map, row)
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
    entity: entity,
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

        -- case 2: direct component id followed by value
        elseif typeof(entry) == 'number' and next_val ~= nil then
            world_assign(world, entity, entry, next_val)
            i += 2

        -- invalid usage: warn and break to avoid silent failure
        else
            error(`world:insert invalid argument at {i}: {entry}. Use world:assign instead`)
        end
    end
end

do
    world.assign = world_assign
    world.remove = world_remove
    world.ask = world_ask
    world.spawn = world_spawn
    world.despawn = world_despawn
    world.query = world_query
    world.has = world_has
    world.insert = world_insert :: world_insert
    world.component = component
end

type undecided_component<T, Prev> =
    component<T> -- metadata table: { id, default }
    | entity -- component id
    | Prev -- fallback value for previous componen

type world_insert = <T, T1, T2, T3, T4, T5>(
    world: world,
    entity: entity,
    a: component<T> | entity,
    b: undecided_component<T1, T>?,
    c: undecided_component<T2, T1>?,
    d: undecided_component<T3, T2>?,
    e: undecided_component<T4, T3>?,
    f: undecided_component<T5, T4>?,
    g: T5?
) -> ()

type world_fields = {
    next_id: number,
    records: { [entity]: record },
    archetypes: { [string]: archetype }, -- map to hash -> archetype
    consumed: { [trait]: set<entity> }, -- tracks which traits were already called to which entity
    scopes: { [entity]: scope }, -- per-entity scope storage used during trait execution
    component_index: { [entity]: set<string> } -- map to component -> { hash }
}

type world_impl = {
    __index: world_impl,
    new: () -> world,
    assign: <D>(self: world, entity: entity, component: entity, data: D?) -> D?,
    remove: (self: world, entity: entity, component: entity) -> (),
    ask: (self: world, entity: entity, component: entity) -> any?,
    spawn: (self: world) -> entity,
    despawn: (self: world, entity: entity) -> (),
    query: (self: world, ...entity) -> (trait: trait) -> (),
    has: (self: world, entity: entity, component: entity) -> boolean,
    insert: world_insert,
    component: <T>(world: world, default: T) -> () -> component<T>,
}

export type world = typeof(setmetatable({} :: world_fields, {} :: world_impl))

return world