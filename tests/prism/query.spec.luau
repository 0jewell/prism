local tiniest = require('../lib/tiniest_for_lune')
type testing = typeof(tiniest.configure {})

local prism = require('../../src/lib')
local world = prism.world

return function(testing: testing)
    local describe = testing.describe
    local test = testing.test
    local expect = testing.expect

    describe('queries', function()
        test('should run query on entities with matching archetype', function()
            local w = world.new()
            local a = w:spawn()
            local b = w:spawn()

            local e1 = w:spawn()
            local e2 = w:spawn()

            w:insert(e1, a, { val = 10 })
            w:insert(e1, b, { val = 20 })

            w:insert(e2, a, { val = 30 })

            local calls = {}
            local function trait(entity, scope)
                calls[entity] = (calls[entity] or 0) + 1
            end

            w:query(a, b)(trait)

            expect(calls[e1]).is(1)
            expect(calls[e2]).never_is(1)

            local scopes = w.scopes[e1]
            expect(scopes).exists()
            expect(scopes[trait]).exists()
        end)

        test('should apply query again when component added and archetype changes', function()
            local w = world.new()
            local a = w:spawn()
            local b = w:spawn()
            local c = w:spawn()

            local e = w:spawn()

            w:insert(e, a, { val = 1 })

            local call_count = 0
            local function trait(entity, scope)
                call_count = call_count + 1
            end

            w:query(a, b)(trait)

            expect(call_count).is(0)

            w:insert(e, b, { val = 2 })

            expect(call_count).is(1)

            w:insert(e, c, { val = 3 })

            expect(call_count).is(1)
        end)

        test('should not apply query twice for same entity and trait', function()
            local w = world.new()
            local compA = w:spawn()
            local compB = w:spawn()

            local e = w:spawn()

            w:insert(e, compA, { val = 1 })
            w:insert(e, compB, { val = 2 })

            local call_count = 0
            local function trait(entity, scope)
                call_count = call_count + 1
            end

            w:query(compA, compB)(trait)
            w:query(compA, compB)(trait)

            expect(call_count).is(1)

            local compC = w:spawn()
            w:insert(e, compC, { val = 3 })
            expect(call_count).is(1)
        end)

        test('should run query on entities in sub-archetypes', function()
            local w = world.new()
            local a = w:spawn()
            local b = w:spawn()
            local c = w:spawn()

            local e1 = w:spawn()
            local e2 = w:spawn()
            local e3 = w:spawn()

            w:insert(e1, a, { val = 10 })
            w:insert(e1, b, { val = 20 })
            w:insert(e1, c, { val = 30 })

            w:insert(e2, a, { val = 40 })
            w:insert(e2, b, { val = 50 })

            w:insert(e3, a, { val = 60 })

            local calls = {}
            local function trait(entity, scope)
                calls[entity] = (calls[entity] or 0) + 1
            end

            w:query(a, b)(trait)

            expect(calls[e1]).is(1)
            expect(calls[e2]).is(1)
            expect(calls[e3]).never_is(1)

            expect(w.scopes[e1]).exists()
            expect(w.scopes[e1][trait]).exists()
            expect(w.scopes[e2]).exists()
            expect(w.scopes[e2][trait]).exists()
        end)

        test('should stop applying trait when components are removed', function()
            warn('this test')
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

            w:remove(e, a)

            local scopes = w.scopes[e]
            expect(scopes[trait]).is(nil)
        end)
    end)
end
