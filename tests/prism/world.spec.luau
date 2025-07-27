local tiniest = require('@tiniest/tiniest_for_lune')
type testing = typeof(tiniest.configure {})

local prism = require('@prism/')
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

        test('should remove all components from entity on despawn', function()
            local w = world.new()
            local a = w:spawn()
            local b = w:spawn()
            local e = w:spawn()

            w:insert(e, a, { val = 1 })
            w:insert(e, b, { val = 2 })

            expect(w:has(e, a)).is(true)
            expect(w:has(e, b)).is(true)
            
            w:despawn(e)

            expect(w.records[e]).never_exists()
            expect(w:has(e, a)).is(false)
            expect(w:has(e, b)).is(false)

            expect(function()
                w:assign(e, a, true)
            end).fails()
        end)

        test('should remove entity from query results after despawn', function()
            local w = world.new()
            local a = w:spawn()
            local b = w:spawn()
            local e = w:spawn()

            w:insert(e, a, { val = 1 })
            w:insert(e, b, { val = 2 })

            local call_count = 0
            local function trait(entity, scope)
                call_count += 1
            end

            w:query(a, b)(trait)
            expect(call_count).is(1)

            w:despawn(e)

            call_count = 0
            w:query(a, b)(trait)
            expect(call_count).is(0)
        end)

        test('should remove all components from entity on delete', function()
            local w = world.new()
            local a = w:spawn()
            local b = w:spawn()
            local e = w:spawn()

            w:insert(e, a, { val = 1 })
            w:insert(e, b, { val = 2 })

            expect(w:has(e, a)).is(true)
            expect(w:has(e, b)).is(true)

            w:delete(e)

            expect(w.records[e]).never_exists()
            expect(w:has(e, a)).is(false)
            expect(w:has(e, b)).is(false)

            expect(function()
                w:assign(e, a, true)
            end).fails()
        end)

        test('should not call trait after delete', function()
            local w = world.new()
            local A = w:spawn()
            local e = w:spawn()

            w:insert(e, A, { val = 10 })

            local count = 0
            w:query(A) (function(entity)
                count += 1
            end)
            expect(count).is(1)

            w:delete(e)

            count = 0
            w:query(A) (function(entity)
                count += 1
            end)
            expect(count).is(0)
        end)

        test('should stop trait execution if entity is deleted mid-trait-chain', function()
            local w = world.new()
            local a = w:spawn()
            local e = w:spawn()

            w:insert(e, a, { val = 1 })

            local calls = {}

            w:query(a) (function(entity)
                table.insert(calls, 'a')
                w:delete(entity)
            end)

            w:query(a)(function(entity)
                table.insert(calls, 'b')
            end)

            w:query(a)(function(entity)
                table.insert(calls, 'c')
            end)

            expect(calls[2]).never_exists()
        end)
    end)
end
