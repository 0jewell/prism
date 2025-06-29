local tiniest = require('../lib/tiniest_for_lune')
type testing = typeof(tiniest.configure {})

local prism = require('../../src/lib')
local world = prism.world

return function(testing: testing)
    local describe = testing.describe
    local test = testing.test
    local expect = testing.expect

    describe('worlds', function()
        test('should return true if entity has component', function()
            local w = world.new()
            local comp = w:spawn()
            local e = w:spawn()

            w:insert(e, comp, { val = 42 })

            expect(w:has(e, comp)).is(true)
        end)

        test('should return false if entity does not have component', function()
            local w = world.new()
            local a = w:spawn()
            local b = w:spawn()
            local e = w:spawn()

            w:insert(e, a, { val = 1 })

            expect(w:has(e, a)).is(true)
            expect(w:has(e, b)).is(false)
        end)

        test('should return false if entity is not in any archetype', function()
            local w = world.new()
            local comp = w:spawn()
            local e = w:spawn()

            expect(w:has(e, comp)).is(false)
        end)

        test('should reflect component removal correctly', function()
            local w = world.new()
            local comp = w:spawn()
            local e = w:spawn()

            w:insert(e, comp, { val = 123 })
            expect(w:has(e, comp)).is(true)

            w:remove(e, comp)
            expect(w:has(e, comp)).is(false)
        end)
    end)
end
