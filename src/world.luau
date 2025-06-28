-- types
export type entity = number
type i53 = number
type i24 = number

-- to do
export type query = never

type column = { unknown }
type row = i53

--[[
se row == 5
a data da entidade está em columns[componente][5]
]]

export type archetype = {
    track: { entity },
    hash: string,
    entities: { entity },
    columns: { column },
    columns_map: { [row]: column },
    queries: { query }
}

--[[
archetype.columns_map = {
    [Position] = archetype.columns[1],
    [Velocity] = archetype.columns[2],
    ...
}

archetype.columns = {
    [Position] = { pos1, pos2, pos3, ... },     -- coluna do componente Position
    [Velocity] = { vel1, vel2, vel3, ... },     -- coluna do componente Velocity
    ...
}
]]

export type record = {
    archetype: archetype,
    row: number
}

local insert = table.insert

-- this
local world = {}

-- constructor
function world.new(): world
    local self = {
        next_id = 1,
        records = {},
        archetypes = {},
        root_archetype = {
            hash = '',
            track = {},
            entities = {},
            columns = {},
            columns_map = {},
            queries = {}
        }
    }
    local metatable = { __index = world }
    setmetatable(self, metatable)

    return self
end

function ensure_archetype(
    world: world,
    track: { entity }
)
    local archetype = {
        hash = '',
        track = {},
        entities = {},
        columns = {},
        columns_map = {},
        queries = {}
    }

    world.archetypes[archetype.hash] = archetype
    return archetype
end

local function ensure_record(
    world: world,
    entity: entity
): record
    local records = world.records
    local record = records[entity]

    if record == nil then
        local archetype = world.root_archetype

        -- insert entity on the archetype
        local row = #archetype.entities + 1
        insert(archetype.entities, entity)

        local new_record = {
            archetype = archetype,
            row = row,
        }

        records[entity] = new_record
        return new_record
    end

    return record
end

local function spawn_entity(world: world)
    local next_id = world.next_id

    ensure_record(world, next_id)
    return next_id
end

local function field(
    entity: entity,
    columns_map: { [row]: column },
    row: row
): unknown?
    local column = columns_map[row]
    
    if column == nil then
        return nil
    end

    return column[row]
end

function world_ask(
    world: world,
    entity: entity,
    component: entity
): unknown?
    local record = world.records[entity]
    local archetype = record.archetype

    if archetype == nil then
        return nil
    end

    local columns_map = archetype.columns_map
    local row = record.row

    return field(entity, columns_map, row)
end

type world_fields = {
    next_id: number,
    records: { [entity]: record },
    archetypes: { [string]: archetype },
    root_archetype: archetype
}

type world_impl = {
    __index: world_impl,
    new: () -> world
}

export type world = typeof(setmetatable({} :: world_fields, {} :: world_impl))

return world