--!optimize 2
--!native
--!strict

-- modules
local archetype = require('./archetype')

-- types
local types = require('./types')
type id = types.id
type entity<T = any> = types.entity<T>

type archetype = types.archetype
type command_operation = types.command_operation

type world = types.world
type mock_world = types.mock_world

-- this
local function world_new(): mock_world
    local world: world = {
        next_id = 1,
        records = {}, archetypes = {},
        consumed = {}, scopes = {},
        indexes = {}, commands = {},
        to_despawn = {}, deferred = {}
    } :: any

    local function start_deferring(entity: id)
        world.deferred[entity] = true
    end
    local function stop_deferring(entity: id)
        world.deferred[entity] = false
    end

    local function execute_command(operation: command_operation)
        -- execution
    end

    local function flush_commands(entity: id)
        local to_execute = world.commands[entity]

        if next(to_execute) == nil then
            return
        end

        for _, operation in to_execute do
            execute_command(operation)
        end

        stop_deferring(entity)
    end

    local function inner_track_queries(
        entity: id,
        old_archetype: archetype,
        new_archetype: archetype
    )
        start_deferring(entity)
        archetype.track_queries(world, entity, old_archetype, new_archetype)
        flush_commands(entity)
    end

    local function buffer_command(operation: command_operation)
        local entity = operation.entity
        local is_deferred = world.deferred[entity]

        if is_deferred then
            local dead = world.to_despawn[entity]
            if dead then return end

            local to_delete = operation.name == 'prism:despawn'

            if to_delete then
                world.to_despawn[entity] = true
            end
            table.insert(world.commands[entity], operation)
        else
            execute_command(operation)
        end
    end

    local function execute_insert(entity, component, data)
        local record = world.records[entity]
        if record == nil then
            error(`entity {entity} does not exist`)
        end

        local old_archetype, old_row = record.archetype, record.row
        local new_archetype = archetype.transition_add(world, component, old_archetype)

        -- if the entity is on the correct archetype
        -- just rewrite its value
        if old_archetype == new_archetype then
            local column = old_archetype.columns_map[component]

            column[old_row] = data
            return data
        end

        if old_archetype then
            -- move entity to the new archetype
            archetype.move_entity(world, new_archetype, entity, record)
        end

        -- set component's data on the new archetype
        local column = new_archetype.columns_map[component]
        column[record.row] = data

        -- calling traits after data is set
        inner_track_queries(entity, old_archetype, new_archetype)

        return data
    end

    function world.insert<T>(entity: id, component: id, data: T?): ()
        local insert_operation = {
            name = 'prism:insert',
            entity = entity
        }

        buffer_command(insert_operation)
    end

    return world :: any
end

return world_new