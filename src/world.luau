-- types
export type entity = number
type i53 = number
type i24 = number

type scope = { unknown }
export type trait = (id: entity, scope: scope) -> ()

type column = { unknown }
type row = i53

type set<T> = { [T]: true }

export type archetype = {
    track: { entity },
    hash: string,
    entities: { entity },
    columns: { column },
    columns_map: { [row]: column },
    queries: { trait },
    consumed: { [trait]: set<entity> },
    subs: { archetype },
    scopes: { [entity]: scope }
}

export type record = {
    archetype: archetype,
    row: number
}

local insert, remove = table.insert, table.remove

-- this
local world = {}
world.__index = world

-- constructor
function world.new()
    local self = {
        next_id = 1,
        records = {},
        archetypes = {}
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

    -- ff we've checked all elements in sub, it's a subset
    return i > #sub
end

local function ensure_archetype(
    world: world,
    track: { entity }
): archetype
    -- sort track
    table.sort(track)

    -- generate archetype identifier
    local hash = table.concat(track, '_')
    local archetypes = world.archetypes
    local archetype = archetypes[hash]

    if archetype == nil then
        local new_archetype = {
            hash = hash,
            track = track,
            entities = {},
            columns = {},
            columns_map = {},
            queries = {},
            consumed = {},
            subs = {},
            scopes = {}
        }

        -- initialize archetype component column
        for _, component in ipairs(track) do
            local column = {}
            new_archetype.columns[component] = column
            new_archetype.columns_map[component] = column
        end

        archetypes[hash] = new_archetype

        for _, other_archetype: archetype in pairs(archetypes) do
            local other_track = other_archetype.track

            if other_archetype ~= new_archetype and subset(other_track, track) then
                insert(new_archetype.subs, other_archetype)
            end
        end

        return new_archetype
    end

    return archetype
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

local function archetype_transition(
    world: world,
    component: entity,
    old_archetype: archetype
): archetype
    if old_archetype.columns_map[component] then
        return old_archetype
    end

    local new_track = {}
    for _, id in ipairs(old_archetype.track) do
        insert(new_track, id)
    end
    insert(new_track, component)

    -- create a new archetype with the new tracked components
    return ensure_archetype(world, new_track)
end

local function archetype_query_transition(
    world: world,
    entity: entity,
    archetype: archetype,
    single_trait: trait?
)
    local scopes = archetype.scopes
    local consumed = archetype.consumed

    if not scopes[entity] then
        scopes[entity] = {}
    end
    local entity_scopes = scopes[entity]

    local function apply_trait(trait: trait)
        consumed[trait] = consumed[trait] or {}

        if consumed[trait][entity] then
            return -- already applied, skip
        end

        local scope = {}
        insert(entity_scopes, scope)

        trait(entity, scope)
        consumed[trait][entity] = true
    end

    if single_trait then
        apply_trait(single_trait)
        return
    end

    for _, trait in ipairs(archetype.queries) do
        apply_trait(trait)
    end

    for _, sub_archetype in ipairs(archetype.subs) do
        archetype_query_transition(world, entity, sub_archetype)
    end
end

local function archetype_query_cleanup(
    world: world,
    entity: entity,
    archetype: archetype
)
    local scopes = archetype.scopes

    -- remove scopes attached to this archetype
    for _, scope in ipairs(scopes[entity]) do
        -- cleanup(scope)
    end
    scopes[entity] = nil

    for _, trait in ipairs(archetype.queries) do
        local applied = archetype.consumed[trait]

        if applied then
            applied[entity] = nil
        end
    end

    -- recursively clean up sub-archetypes
    for _, sub_archetype in ipairs(archetype.subs) do
        archetype_query_cleanup(world, entity, sub_archetype)
    end
end

local function world_query(
    world: world,
    ...: entity
)
    local track = { ... }
    local archetype = ensure_archetype(world, track)

    return function(trait: trait)
        -- call this trait for all entities
        for _, id in pairs(archetype.entities) do
            archetype_query_transition(world, id, archetype, trait)
        end

        -- cache trait in the archetype
        insert(archetype.queries, trait)
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

    local new_archetype = archetype_transition(world, component, old_archetype)

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
    if not subset(old_archetype.track, new_archetype.track) then
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

export type world = typeof(world.new())

return world