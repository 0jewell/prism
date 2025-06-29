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

-- index of the entity inside an archetype's column
type row = i53

type set<T> = { [T]: boolean }

export type archetype = {
    track: { entity }, -- ordered list of component ids in this archetype
    hash: string, -- string identifier, e.g. "1_2_3"
    entities: { entity }, -- list of entities currently in this archetype
    columns: { column }, -- raw component data arrays
    columns_map: { [row]: column }, -- maps component id to its column
    subs: { archetype }, -- archetypes that are subsets of this one,
    traits: { trait }, -- traits (callbacks) on this archetype
}

export type record = {
    archetype: archetype, -- current archetype the entity belongs to
    row: number, -- row index in the archetype's columns
}

local insert, remove, find = table.insert, table.remove, table.find

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
    return {
        hash = hash,
        track = track,
        entities = {},
        columns = {},
        columns_map = {},
        subs = {},
        traits = {}
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

    for _, component in ipairs(track) do
        local column = {}
        archetype.columns[component] = column
        archetype.columns_map[component] = column

        -- check if the current component has been added
        -- to an archetype before
        if component_index[component] then
            local component_archetypes = component_index[component]

            -- if so, add it as a possible sub archetype or a super archetype
            for archetype_hash in pairs(component_archetypes) do
                local other_archetype = archetypes[archetype_hash]
                possible_subs[other_archetype] = true
            end
        else
            component_index[component] = {}
        end

        component_index[component][hash] = true
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
            insert(archetype.subs, other_archetype)

            -- copy traits from other to new archetype
            local traits = archetype.traits
            local other_traits = other_archetype.traits

            for _, trait in ipairs(other_traits) do
                if not find(traits, trait) then
                    insert(traits, trait)
                end
            end

        elseif subset(track, other_track) then
            -- new is a subset of other
            insert(other_archetype.subs, archetype)
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

local function find_archetype_with(
    world: world,
    component: entity,
    archetype: archetype
): archetype
    if archetype.columns_map[component] then
        return archetype
    end

    local track = archetype.track

    local at = find_insert(track, component)
    local new_track = {}

    for _, id in ipairs(track) do
        insert(new_track, id)
    end
    insert(new_track, at, component)

    -- create a new archetype with the new tracked components
    return ensure_archetype(world, new_track)
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
        traits = { single_trait }
    end

    if #traits == 0 then
        return
    end

    local entity_scopes = scopes[entity]

    if entity_scopes == nil then
        entity_scopes = {}

        scopes[entity] = entity_scopes
    end

    for _, trait in ipairs(traits) do
        local trait_consumed = consumed[trait]

        if trait_consumed == nil then
            trait_consumed = {}

            consumed[trait] = trait_consumed
        end

        if trait_consumed[entity] then
            return -- already applied, skip
        end

        local scope = {}
        entity_scopes[trait] = scope

        trait(entity, scope)
        trait_consumed[entity] = true
    end
end

local function archetype_query_cleanup(
    world: world,
    entity: entity,
    archetype: archetype
)
    local scopes = world.scopes
    local consumed = world.consumed

    for _, trait in ipairs(archetype.traits) do
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
        end
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
        for _, id in pairs(archetype.entities) do
            archetype_query_transition(world, id, archetype, trait)
        end

        if find(archetype.traits, trait) then
            return
        end

        -- cache trait in the archetype state
        insert(archetype.traits, trait)
    end
end

local function archetype_swap_remove(
    world: world,
    entity: entity,
    old_row: row,
    old_archetype: archetype
)
    local entities = old_archetype.entities
    local last_index = #entities
    local last_entity = entities[last_index]

    -- swap the last entity into the same slot
    -- unless it's the same entity
    if entity ~= last_entity then
        entities[old_row] = last_entity

        -- update the record of the moved_entity
        local moved_record = world.records[last_entity]
        moved_record.row = old_row

        for _, id in ipairs(old_archetype.track) do
            local column = old_archetype.columns_map[id]
            column[old_row] = column[last_index]
        end
    end

    -- remove last entity and cleanup its columns
    remove(entities, last_index)

    for _, id in ipairs(old_archetype.track) do
        local column = old_archetype.columns_map[id]
        column[last_index] = nil
    end
end

local function world_insert<D>(
    world: world,
    entity: entity,
    component: entity,
    data: D?
): D?
    local record = ensure_record(world, entity)

    local old_archetype = record.archetype
    local old_row = record.row

    local new_archetype = find_archetype_with(world, component, old_archetype)

    -- if the entity is on the correct archetype
    -- just rewrite its value
    if old_archetype == new_archetype then
        local column = old_archetype.columns_map[component]

        column[old_row] = data
        return data
    end

    local new_row = #new_archetype.entities + 1
    insert(new_archetype.entities, entity)

    -- move entity's data to the new archetype
    for _, id in ipairs(new_archetype.track) do
        local column = new_archetype.columns_map[id]

        if id == component then
            column[new_row] = data
        else
            local old_column = old_archetype.columns_map[id]
            column[new_row] = old_column and old_column[old_row] or nil
        end
    end

    -- update entity record
    world.records[entity] = {
        archetype = new_archetype,
        row = new_row
    }

    -- remove entity from the old archetype
    archetype_swap_remove(world, entity, old_row, old_archetype)

    -- only remove scopes if the new archetype no longer satisfies the old one
    if not find(new_archetype.subs, old_archetype) then
        archetype_query_cleanup(world, entity, old_archetype)
    end

    -- enable queries for the new archetype
    archetype_query_transition(world, entity, new_archetype)

    return data
end

local function world_spawn(world: world)
    local next_id = world.next_id

    ensure_record(world, next_id)

    world.next_id += 1
    return next_id
end

local function field(
    component: entity,
    columns_map: { [row]: column },
    row: row
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
    local record = ensure_record(world, entity)
    local archetype = record.archetype

    if archetype == nil then
        return nil
    end

    local columns_map = archetype.columns_map
    local row = record.row

    return field(component, columns_map, row)
end

do
    world.insert = world_insert
    world.ask = world_ask
    world.spawn = world_spawn
    world.query = world_query
end

type world_fields = {
    next_id: number,
    records: { [entity]: record },
    archetypes: { [string]: archetype },
    consumed: { [trait]: set<entity> }, -- tracks which traits were already called to which entity
    scopes: { [entity]: scope }, -- per-entity scope storage used during trait execution
    component_index: { [entity]: set<string> }
}

type world_impl = {
    __index: world_impl,
    new: () -> world,
    insert: <D>(self: world, entity: entity, component: entity, data: D?) -> D?,
    ask: (self: world, entity: entity, component: entity) -> any?,
    spawn: (self: world) -> entity,
    query: (self: world, ...entity) -> (trait: trait) -> ()
}

export type world = typeof(setmetatable({} :: world_fields, {} :: world_impl))

return world