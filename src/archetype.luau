--!optimize 2
--!native

-- modules
local clean = require('./clean')

-- types
local types = require('./types')
type id = types.id
type trait = types.trait

type archetype = types.archetype
type record = types.record
type world = types.world

type set<T> = types.set<T>

-- functions
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

local function archetype_new(
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

local function archetype_link_traits(
    archetype: archetype,
    other_archetype: archetype
): ()
    local traits = archetype.traits
    local other_traits = other_archetype.traits

    for trait in other_traits do
        traits[trait] = true
    end
end

local function archetype_link_subs(
    world: world,
    archetype: archetype,
    track: { id }
): ()
    for _, other_archetype in pairs(world.archetypes) do
        if other_archetype == archetype then continue end

        local other_track = other_archetype.track

        if subset(other_track, track) then
            -- other is a subset of new
            archetype.subs[other_archetype] = true
            other_archetype.supers[archetype] = true

            -- copy traits from other to new archetype
            archetype_link_traits(archetype, other_archetype)

        elseif subset(track, other_track) then
            -- new is a subset of other
            other_archetype.subs[archetype] = true
            archetype.supers[other_archetype] = true
        end
    end
end

local function register_component_index(
    world: world,
    track: { id },
    hash: string,
    archetype: archetype
): ()
    local component_index = world.indexes

    for i, component in ipairs(track) do
        local column = {}
        archetype.columns[i] = column
        archetype.columns_map[component] = column

        -- check if the current component has been added
        -- to an archetype before
        local component_archetypes = component_index[component]

        if component_archetypes == nil then
            local new_index = {}
            component_index[component] = new_index
            component_archetypes = new_index
        end

        component_archetypes[hash] = true
    end
end

local function archetype_ensure(
    world: world, 
    track: { id }
): archetype
    local hash = hash(track)
    local archetype = world.archetypes[hash]

    if archetype then
        return archetype
    end

    local new_archetype = archetype_new(track, hash)

    -- register components and collect related archetypes
    register_component_index(world, track, hash, new_archetype)

    -- link this archetype with others based on component subsets
    archetype_link_subs(world, new_archetype, track)

    world.archetypes[hash] = new_archetype
    return new_archetype
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
            table.insert(new_track, id)
        end
        table.insert(new_track, at, component)
        local new_archetype = archetype_ensure(world, new_track)

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
            table.insert(new_track, id)
        end
        table.remove(new_track, at)

        local new_archetype = archetype_ensure(world, new_track)

        -- cache transition
        edge[component] = new_archetype
        new_archetype.edge[component] = archetype

        return new_archetype
    end

    return cached_new_archetype
end

local function archetype_transition_query(
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
        if world.records[entity] == nil then
            break
        end

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
    
        -- mark trait as consumed
        trait_consumed[entity] = true

        local function clean(...: unknown)
            for i = 1, select('#', ...) do
                local arg = select(i, ...)
                table.insert(scope, arg)
            end
        end

        trait(entity, clean)
    end
end

local function query_remove_trait(
    consumed: { [trait]: set<id> },
    scopes: { [id]: { [trait]: { unknown } } },
    entity: id,
    trait: trait
)
    local trait_consumed = consumed[trait]
    if trait_consumed == nil then
        return
    end

    local entity_scopes = scopes[entity]
    if entity_scopes then
        -- cleanup entity's scope attached to this trait
        if entity_scopes[trait] then
            clean(entity_scopes[trait])

            entity_scopes[trait] = nil
        end
    end

    -- remove entity from this trait
    trait_consumed[entity] = nil
end

local function archetype_transition_query_cleanup(
    world: world,
    entity: id,
    old_archetype: archetype,
    new_archetype: archetype,
    single_trait: trait?
)
    local scopes = world.scopes
    local consumed = world.consumed
    local traits = old_archetype.traits

    if single_trait then
        traits = { [single_trait] = true }
    end

    for trait in traits do
        if new_archetype.traits[trait] then
            continue
        end

        query_remove_trait(consumed, scopes, entity, trait)
    end
end

local function archetype_track_queries(
    world: world,
    entity: id,
    old_archetype: archetype,
    new_archetype: archetype
)
    -- only remove scopes if the new archetype no longer satisfies the old one
    if new_archetype.supers[old_archetype] then
        archetype_transition_query_cleanup(world, entity, old_archetype, new_archetype)
    end

    -- enable queries for the new archetype
    archetype_transition_query(world, entity, new_archetype)
end

local function archetype_query_cleanup(
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

    for trait in traits do
        query_remove_trait(consumed, scopes, entity, trait)
    end
end

local function snapshot_entities(
    archetype: archetype
)
    local src = archetype.entities
    local out = {}

    for i = 1, #src do
        out[i] = src[i]
    end

    return out
end

local function archetype_propagate_trait(
    world: world,
    archetype: archetype,
    trait: trait
)
    -- iterate over a snapshot so mutations (swap/remove) dont break the loop
    local entities_snapshot = snapshot_entities(archetype)
    for _, id in ipairs(entities_snapshot) do
        archetype_transition_query(world, id, archetype, trait)
    end

    -- snapshot supers to avoid issues if the supers table mutates
    local supers_snapshot = {}
    for super in pairs(archetype.supers) do
        supers_snapshot[#supers_snapshot + 1] = super
    end

    for _, super_archetype in ipairs(supers_snapshot) do
        super_archetype.traits[trait] = true
        archetype_propagate_trait(world, super_archetype, trait)
    end
end

local function archetype_propagate_remove(
    world: world,
    archetype: archetype,
    trait: trait
)
    local entities_snapshot = snapshot_entities(archetype)
    for _, id in ipairs(entities_snapshot) do
        archetype_query_cleanup(world, id, archetype, trait)
    end

    local supers_snapshot = {}
    for super in pairs(archetype.supers) do
        supers_snapshot[#supers_snapshot + 1] = super
    end

    for _, super_archetype in ipairs(supers_snapshot) do
        super_archetype.traits[trait] = nil
        archetype_propagate_remove(world, super_archetype, trait)
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

local function archetype_move_entity(
    world: world,
    new_archetype: archetype,
    entity: id,
    record: record
)
    local old_archetype = record.archetype
    local old_row = record.row

    local new_row = #new_archetype.entities + 1
    table.insert(new_archetype.entities, entity)

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

return {
    -- creation
    new = archetype_new,
    ensure = archetype_ensure,

    -- entity
    swap_remove = archetype_swap_remove,
    move_entity = archetype_move_entity,
    track_queries = archetype_track_queries,

    -- sub-supers
    link_traits = archetype_link_traits,
    link_subs = archetype_link_subs,

    -- transitions
    transition_add = archetype_transition_add,
    transition_remove = archetype_transition_remove,
    transition_query = archetype_transition_query,
    transition_query_cleanup = archetype_transition_query_cleanup,

    -- propagation
    propagate_trait = archetype_propagate_trait,
    propagate_remove = archetype_propagate_remove
}