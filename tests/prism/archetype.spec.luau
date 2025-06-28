local tiniest = require('../lib/tiniest_for_lune')
type testing = typeof(tiniest.configure({}))

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
			expect(record.archetype).is(w.root_archetype)
			expect(record.row).is(1)
		end)

		test('should insert component and create new archetype', function()
			local w = world.new()
			local position = w:spawn()
			local e = w:spawn()

			w:insert(e, position, { x = 1, y = 2 })

			local record = w.records[e]
			expect(record.archetype).never_is(w.root_archetype)
            
			local val = w:ask(e, position)
			expect(val).never_is(nil)
			expect(val.x).is(1)
			expect(val.y).is(2)
		end)

		test('should rewrite existing component if already in archetype', function()
			local w = world.new()
			local hp = w:spawn()
			local e = w:spawn()

			w:insert(e, hp, 50)
			w:insert(e, hp, 100)

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

			w:insert(e, pos, { x = 0, y = 0 })
			local old_archetype = w.records[e].archetype

			w:insert(e, vel, { x = 1, y = 1 })
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
			local w = world.new()
			local a = w:spawn()
			local b = w:spawn()
			local e1 = w:spawn()
			local e2 = w:spawn()

			w:insert(e1, a, true)
			w:insert(e1, b, true)

			w:insert(e2, b, true)
			w:insert(e2, a, true)

			expect(w.records[e1].archetype).is(w.records[e2].archetype)
		end)
	end)
end