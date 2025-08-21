--!optimize 2
--!native
--!strict

-- modules
local archetype = require('./archetype')
local types = require('./types')

-- operations
type insert_operation = command_operation<{
    component: id,
    data: any?
}>

type remove_operation = command_operation<{
    component: id
}>

-- functions
local function ensure_record(world: world, entity: id): record
    local records = world.records
    local record = records[entity]

    if record == nil then
        local root_archetype = archetype.ensure(world, {})

        -- insert entity on the archetype
        local row = #root_archetype.entities + 1
        table.insert(root_archetype.entities, entity)

        local new_record = {
            archetype = root_archetype,
            row = row,
        }

        records[entity] = new_record
        return new_record
    end

    return record
end

-- this
local function world_new(): mock_world
    local world: world = {
        next_id = 1, records = {}, archetypes = {},
        consumed = {}, scopes = {}, indexes = {},
        commands = {}, to_despawn = {}, deferred = {}
    } :: any

    local function start_deferring(entity: id): ()
        world.deferred[entity] = true
    end

    local function stop_deferring(entity: id): ()
        world.deferred[entity] = false
    end

    local function safe_record(entity: id): record
        local record = world.records[entity]
        if record == nil then
            error(`invalid entity: record does not exist`)
        end

        return record
    end

    local function execute_command(operation: command_operation)
        operation:call()
    end

    local function flush_commands(entity: id): ()
        local to_execute = world.commands[entity]

        if to_execute and next(to_execute) then
            for _, operation in to_execute do
                execute_command(operation)
            end

            table.clear(to_execute)
        end

        stop_deferring(entity)
    end

    local function inner_track_queries(
        entity: id,
        old_archetype: archetype,
        new_archetype: archetype
    ): ()
        start_deferring(entity)
        archetype.track_queries(world, entity, old_archetype, new_archetype)
        flush_commands(entity)
    end

    local function buffer_command(operation: command_operation): ()
        local entity = operation.entity
        local is_deferred = world.deferred[entity]

        if is_deferred then
            local dead = world.to_despawn[entity]
            if dead then return end

            local to_delete = operation.name == 'prism:despawn'

            if to_delete then
                world.to_despawn[entity] = true
            end
            local commands = world.commands[entity]

            if commands == nil then
                commands = {}
                world.commands[entity] = commands
            end
            table.insert(commands, operation)
        else
            execute_command(operation)
        end
    end

    function world.spawn(): id
        local next_id = world.next_id
        ensure_record(world, next_id)

        world.next_id += 1
        return next_id
    end

    local function execute_insert<T>(operation: insert_operation): ()
        local entity, component, data = operation.entity, operation.component, operation.data
        local record = safe_record(entity)

        local old_archetype, old_row = record.archetype, record.row
        local new_archetype = archetype.transition_add(world, component, old_archetype)

        -- if the entity is on the correct archetype
        -- just rewrite its value
        if old_archetype == new_archetype then
            local column = old_archetype.columns_map[component]

            column[old_row] = data
            return
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
    end

    function world.insert<T>(entity: id, component: id, data: T?): ()
        local insert_operation = {
            name = 'prism:insert',
            entity = entity,
            component = component,
            data = data,
            call = execute_insert
        }

        buffer_command(insert_operation)
    end

    local function execute_remove(operation: remove_operation): ()
        local entity, component = operation.entity, operation.component
        local record = safe_record(entity)

        local old_archetype = record.archetype
        if not old_archetype then return end

        -- entity may not have this component
        local has_component = old_archetype.columns_map[component]
        if has_component then
            local new_archetype = archetype.transition_remove(world, component, old_archetype)

            archetype.move_entity(world, new_archetype, entity, record)
            inner_track_queries(entity, old_archetype, new_archetype)
        end
    end

    function world.remove(entity: id, component: id): ()
        local remove_operation = {
            name = 'prism:remove',
            entity = entity,
            component = component,
            call = execute_remove
        }


        buffer_command(remove_operation)
    end

    local function field(
        component: id,
        columns_map: { [id]: column },
        row: number
    ): unknown
        local column = columns_map[component]

        if column == nil then
            return nil
        end

        return column[row]
    end

    function world.get(entity: id, ...: id): ...unknown
        local record = safe_record(entity)
        local archetype = record.archetype

        if archetype == nil then
            return nil
        end

        local columns_map = archetype.columns_map
        local row = record.row

        local length = select('#', ...)
        local a, b, c, d, e = ...

        if length == 1 then
            return field(a, columns_map, row)

        elseif length == 2 then
            return field(a, columns_map, row),
                field(b, columns_map, row)

        elseif length == 3 then
            return field(a, columns_map, row),
                field(b, columns_map, row),
                field(c, columns_map, row)

        elseif length == 4 then
            return field(a, columns_map, row),
                field(b, columns_map, row),
                field(c, columns_map, row),
                field(d, columns_map, row)

        elseif length == 5 then
            return field(a, columns_map, row),
                field(b, columns_map, row),
                field(c, columns_map, row),
                field(d, columns_map, row),
                field(e, columns_map, row)
        else
            local components = table.create(length, nil)
            for i = 1, length do
                local component = select(i, ...)
                components[i] = field(component, columns_map, row)
            end

            return unpack(components, 1, length)
        end
    end

    return world :: any
end

type id = types.id
type entity<T = any> = types.entity<T>
type record = types.record
type column = types.column

type archetype = types.archetype
type command_operation<T = any> = types.command_operation<T>

type world = types.world
type mock_world = types.mock_world

return world_new