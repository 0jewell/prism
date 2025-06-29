local prism = require('../src/lib')
local world = prism.world

local w = world.new()

local function color(r, g, b)
    return string.format('\27[38;2;%d;%d;%dm', r, g, b)
end

local reset = '\27[0m'
local red = color(255, 80, 80)
local green = color(80, 255, 120)
local gray = color(160, 160, 160)

local function benchmark()
    print(gray .. [[
╔════════════════════════════════════════════╗
║            prism benchmark report           ║
╚════════════════════════════════════════════╝
]] .. reset)

    local query_count = 100
    local entity_count = 10_000

    local c1, c2 = w:spawn(), w:spawn()
    local c3, c4 = w:spawn(), w:spawn()
    local c5, c6 = w:spawn(), w:spawn()
    local c7, c8 = w:spawn(), w:spawn()

    local all_components = { c1, c2, c3, c4, c5, c6, c7, c8 }
    local components_per_entity = #all_components

    for _ = 1, query_count do
        w:query(c1, c2, c3, c4, c5, c6, c7, c8)(function() end)
    end

    print(gray .. '• inserting entities and components...' .. reset)

    local start = os.clock()

    for i = 1, entity_count do
        local e = w:spawn()
        for j = 1, components_per_entity do
            w:insert(e, all_components[j])
        end
    end

    local finish = os.clock()
    local total_time = finish - start
    local avg_time = total_time / entity_count

    print()
    print(green .. string.format('✔ inserted %d entities with %d components each', entity_count, components_per_entity) .. reset)
    print(red .. string.format('⏱ total time: %.6f seconds', total_time) .. reset)
    print(gray .. string.format('➤ average time per entity: %.10f seconds', avg_time) .. reset)
    print()
end

benchmark()
