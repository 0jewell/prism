local tiniest = require('@tiniest/tiniest_for_lune')
type testing = typeof(tiniest.configure {})

local prism = require('@prism/')
local world = prism.world

return function(testing: testing)
    local describe = testing.describe
    local test = testing.test
    local expect = testing.expect

    describe('world', function()
        test('should spawn a new entity', function()
            local w = world()
            local e = w.spawn()

            expect(typeof(e)).is('number')
            expect(w.records[e]).is_a('table')
        end)

        test('should despawn an entity', function()
            local w = world()
            local e = w.spawn()

            w.despawn(e)
            expect(w.records[e]).is(nil)
        end)

        test('should insert and remove components', function()
            local w = world()
            local a = w.spawn()
            local e = w.spawn()

            w.insert(e, a, 'abc')
            expect(w.has(e, a)).is(true)

            w.remove(e, a)
            expect(w.has(e, a)).is(false)
        end)

        test('should return false for has on non-existing entity', function()
            local w = world()
            expect(w.has(9999 :: any)).is(false)
        end)

        test('should return true for has when entity exists without component', function()
            local w = world()
            local e = w.spawn()
            expect(w.has(e)).is(true)
        end)

        test('should handle multiple components', function()
            local w = world()
            local a = w.spawn()
            local b = w.spawn()
            local e = w.spawn()

            w.insert(e, a, 'a')
            w.insert(e, b, 'b')

            expect(w.has(e, a)).is(true)
            expect(w.has(e, b)).is(true)

            w.remove(e, a)
            expect(w.has(e, a)).is(false)
            expect(w.has(e, b)).is(true)
        end)

        test('should not break when removing non-existent component', function()
            local w = world()
            local e = w.spawn()

            expect(function()
                w.remove(e, 123 :: any)
            end).never_fails()
        end)
    end)
end