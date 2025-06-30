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

        test('should insert component using metadata (comp())', function()
            local w = world.new()
            local comp = w:component { health = 100 }
            local e = w:spawn()

            w:insert(e, comp())

            expect(w:has(e, comp().id)).is(true)

            local data = w:ask(e, comp().id)
            expect(data).exists()
            expect(data.health).is(100)
        end)

        test('should support mixing metadata and (comp, value)', function()
            local w = world.new()
            local c1 = w:component { ready = false }
            local c2 = w:component { level = 1 }
            local e = w:spawn()

            w:insert(e, c1(), c2())

            expect(w:has(e, c1().id)).is(true)
            expect(w:has(e, c2().id)).is(true)

            local data = w:ask(e, c2().id)
            expect(data).exists()

            expect(data.level).is(1)
        end)

        test('should handle multiple components at once', function()
            local w = world.new()
            local a = w:component(true)
            local b = w:spawn()
            local c = w:component('string')
            local e = w:spawn()

            w:insert(e, a(), b, { val = 99 }, c())

            expect(w:ask(e, a().id)).is(true)

            local data = w:ask(e, b)
            expect(data).exists()
            expect(data.val).is(99)

            expect(w:ask(e, c().id)).is('string')
        end)

        test('should return false if entity does not have component', function()
            local w = world.new()
            local a = w:spawn()
            local b = w:spawn()
            local e = w:spawn()

            w:assign(e, a, { val = 1 })

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

            w:assign(e, comp, { val = 123 })
            expect(w:has(e, comp)).is(true)

            w:remove(e, comp)
            expect(w:has(e, comp)).is(false)
        end)
    end)
end
