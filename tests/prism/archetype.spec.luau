local tiniest = require('../lib/tiniest_for_lune')
type testing = typeof(tiniest.configure {})

local prism = require('../../src/lib')
local world = prism.world

return function(testing: testing)
    local describe = testing.describe
    local test = testing.test
    local expect = testing.expect

    describe('archetypes', function()
        test('should spawn entity into root archetype', function()
            local w = world.new()
            local e = w:spawn()

            local record = w.records[e]
            expect(record).exists()
            expect(record.archetype.hash).is('')
            expect(record.row).is(1)
        end)

        test('should insert component and create new archetype', function()
            local w = world.new()
            local position = w:spawn()
            local e = w:spawn()

            w:assign(e, position, { x = 1, y = 2 })

            local record = w.records[e]
            expect(record.archetype.hash).never_is('')

            local val = w:ask(e, position)
            expect(val).never_is(nil)
            expect(val.x).is(1)
            expect(val.y).is(2)
        end)

        test('should rewrite existing component if already in archetype', function()
            local w = world.new()
            local hp = w:spawn()
            local e = w:spawn()

            w:assign(e, hp, 50)
            w:assign(e, hp, 100)

            local record = w.records[e]
            local archetype = record.archetype
            local column = archetype.columns_map[hp]

            expect(column[record.row]).is(100)
        end)

        test('should move entity to new archetype with additional component', function()
            local w = world.new()
            local pos = w:spawn()
            local vel = w:spawn()
            local e = w:spawn()

            w:assign(e, pos, { x = 0, y = 0 })
            local old_archetype = w.records[e].archetype

            w:assign(e, vel, { x = 1, y = 1 })
            local new_archetype = w.records[e].archetype

            expect(old_archetype).never_is(new_archetype)
            expect(#old_archetype.entities).is(0)
            expect(#new_archetype.entities).is(1)

            local pos_val = w:ask(e, pos)
            expect(pos_val.x).is(0)
            expect(pos_val.y).is(0)

            local vel_val = w:ask(e, vel)
            expect(vel_val.x).is(1)
            expect(vel_val.y).is(1)
        end)

        test('should not duplicate archetypes with same component set', function()
            print(1)
            local w = world.new()
            local a = w:spawn()
            local b = w:spawn()
            local e1 = w:spawn()
            local e2 = w:spawn()

            w:insert(e1, a, true, b, true)

            w:assign(e2, b, true)
            w:assign(e2, a, true)
            
            expect(w.records[e1].archetype.hash).is(w.records[e2].archetype.hash)
        end)

        test('should register archetype with correct subs using component index', function()
            print(5)
            local w = world.new()
            local A = w:spawn()
            local B = w:spawn()
            local C = w:spawn()

            w:query(A, B)(function() end)
            w:query(A, B, C)(function() end)

            local abc = w.archetypes['1_2_3']
            local ab = w.archetypes['1_2']

            expect(abc).exists()
            expect(abc.subs[ab]).exists()

            -- check inverse
            expect(ab.subs[abc]).never_exists()
        end)

        test('should correctly register subs regardless of component order', function()
            local w = world.new()
            local A = w:spawn()
            local B = w:spawn()
            local C = w:spawn()

            -- Intentionally out of order
            w:query(B, C, A)(function() end)
            w:query(C, A, B)(function() end)
            w:query(B, C)(function() end)

            local cab = w.archetypes['3_1_2']
            expect(cab).never_exists()

            local bca = w.archetypes['1_2_3']
            local bc = w.archetypes['2_3']

            expect(bca).exists()
            expect(bc).exists()
            expect(bca.subs[bc]).exists()

            -- reverse check
            expect(bc.subs[bca]).never_exists()
        end)

        test('should remove a component and move entity to new archetype', function()
            local w = world.new()
            local A = w:spawn()
            local B = w:spawn()
            local e = w:spawn()

            w:assign(e, A, { val = 1 })
            w:assign(e, B, { val = 2 })

            local old_record = w.records[e]
            local old_archetype = old_record.archetype
            expect(old_archetype).exists()
            expect(old_archetype.columns_map[A]).exists()
            expect(old_archetype.columns_map[B]).exists()

            w:remove(e, B)

            local new_record = w.records[e]
            local new_archetype = new_record.archetype
            expect(new_archetype).exists()
            expect(new_archetype ~= old_archetype).is(true)

            expect(new_archetype.columns_map[A]).exists()
            expect(new_archetype.columns_map[B]).is(nil)

            expect(new_archetype.columns_map[A][new_record.row].val).is(1)
        end)
    end)
end
