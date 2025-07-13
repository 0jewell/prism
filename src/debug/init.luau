local colors = require('@self/colors')
local label = colors.label
local value = colors.value
local header = colors.header
local error_text = colors.error_text
local gray = colors.gray

local world_module = require('./world')
type mock_archetype = world_module.archetype
type mock_record = world_module.record
type mock_world = world_module.mock_world

local trace_enabled = false
local trait_stack: { stackframe } = {}

local CELL_WIDTH = 11

export type stackframe = {
    path: string,
    line: number,
    name: string,
}

local function get_stackframe(
    level: number?
): stackframe?
    local path, line, name = debug.info((level or 2), "sln")

    if line == nil then
        return
    end

    return {
        path = path,
        line = line,
        name = name,
    }
end

local function format_stackframe(sf: stackframe): string
    return `📄 {sf.path}:{sf.line}   ↪ {sf.name}()`
end

local function print_labeled(lbl: string, val: string, indent: string?)
    print((indent or '') .. '│ ' .. label(lbl) .. ' ' .. value(val))
end

local function print_list(lbl: string, items: { any }, indent: string?)
    print((indent or '') .. '│ ' .. label(lbl) .. ' ' .. value('[' .. table.concat(items, ', ') .. ']'))
end

local function pad(str: string): string
    return string.format("%-" .. CELL_WIDTH .. "s", str)
end

local function value_preview(v: any): string
    if typeof(v) == "table" then
        return "{ ... }"
    elseif typeof(v) == "string" then
        return '"' .. v .. '"'
    else
        return tostring(v)
    end
end

local function debug_archetype(
    archetype: mock_archetype,
    indent: string?
)
    local indent_str = indent or '  '
    print(indent_str .. '╭─ 🎴 Archetype `' .. tostring(archetype.hash) .. '`')
    print_list('Track (components):', archetype.track, indent_str)
    print_list('Entities:', archetype.entities, indent_str)

    local trait_count = 0
    for _ in pairs(archetype.traits) do trait_count += 1 end
    print_labeled('Traits:', tostring(trait_count), indent_str)
    print_labeled('Subs:', tostring(#archetype.subs), indent_str)
    for sub in pairs(archetype.subs) do
        print(indent_str .. '│    ↪ ' .. tostring(sub.hash))
    end

    print(indent_str .. '│')
    print(indent_str .. '│ Columns Data (row x component):')

    local header = indent_str .. '│    [row] '
    for _, component in ipairs(archetype.track) do
        header ..= '| ' .. pad(tostring(component))
    end
    print(header)

    for row = 1, #archetype.entities do
        local entity = archetype.entities[row]
        local line = indent_str .. '│    [' .. row .. ':' .. tostring(entity) .. '] '
        for _, component in ipairs(archetype.track) do
            local column = archetype.columns_map[component]
            local value = column and column[row] or nil
            local preview = value and value_preview(value) or 'nil'
            line ..= '| ' .. pad(preview)
        end
        print(line)
    end

    print(indent_str .. '╰──────────────')
end

local function debug_world(world: mock_world)
    print(header('🌍 ─── WORLD STATE ───'))
    print_labeled('Next ID:', tostring(world.next_id))

    local archetype_count = 0
    for _ in world.archetypes do archetype_count += 1 end
    print_labeled('Total Archetypes:', tostring(archetype_count))
    print()

    for _, archetype in pairs(world.archetypes) do
        debug_archetype(archetype :: any)
        print()
    end

    print(header('📦 ─── ENTITY RECORDS ───'))
    for entity, record in pairs(world.records) do
        print('│ Entity ' .. value(entity :: any) ..
            '  →  🧬 ' .. value(record.archetype.hash) ..
            '  @ Row ' .. value(record.row)
        )
    end
    print()

    print(header('🧠 ─── TRAIT CONSUMPTION ───'))
    for trait, entities in pairs(world.consumed) do
        local entity_list = {}
        for entity in entities do
            table.insert(entity_list, tostring(entity))
        end
        print('│ Trait ' .. value(tostring(trait)) .. ' → [' .. table.concat(entity_list, ', ') .. ']')
    end
end

local function debug_entity(world: mock_world, entity: number)
    local record = world.records[entity :: any]
    if not record then
        print(error_text('🚫 Entity ' .. entity .. ' not found!'))
        return
    end

    print(header('🔎 ─── ENTITY ' .. entity .. ' ───'))
    print_labeled('Archetype:', record.archetype.hash)
    print_labeled('Row:', tostring(record.row))
    print('│ Components:')

    for _, component_id in ipairs(record.archetype.track) do
        local column = record.archetype.columns_map[component_id]
        local value_raw = column[record.row]
        local formatted = type(value_raw) == 'table' and '{ ... }' or tostring(value_raw)
        print('│   • ' .. label(tostring(component_id)) .. ': ' .. value(formatted))
    end

    print()
    debug_archetype(record.archetype :: any, '  ')
end

local function push_trace(label_str: string)
    if not trace_enabled then return end
    local frame = get_stackframe(3)
    if frame then
        frame.name = label_str
        table.insert(trait_stack, frame)
    end
end

local function pop_trace()
    if trace_enabled and #trait_stack > 0 then
        table.remove(trait_stack)
    end
end

local function print_stack()
    if #trait_stack == 0 then
        print(gray .. '╭── ❖ TRAIT STACKTRACE ──╮')
        print(gray .. '│  (empty)')
        print(gray .. '╰────────────────────────╯')
        return
    end

    print(header('📜 ─── TRAIT STACKTRACE ───'))
    for i, frame in ipairs(trait_stack) do
        print(gray .. '│ ' .. i .. '. ' .. value(format_stackframe(frame)))
    end
end

return {
    debug_world = debug_world,
    debug_entity = debug_entity,
    debug_archetype = debug_archetype,

    push_trace = push_trace,
    pop_trace = pop_trace,
    print_stack = print_stack,

    enable_trace = function() trace_enabled = true end,
    disable_trace = function() trace_enabled = false end,
    is_trace_enabled = function() return trace_enabled end,
}
