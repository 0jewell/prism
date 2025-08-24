local tiniest = require('@tiniest/tiniest_for_lune')
type testing = typeof(tiniest.configure {})

local prism = require('@prism/')
local world = prism.world

return function(testing: testing)
    local describe = testing.describe
    local test = testing.test
    local expect = testing.expect

    describe('query', function()
        test('should register and cleanup trait scope', function()
            local w = world()
            local a = w.spawn()
            local e = w.spawn()

            local trait = function(entity)
            end
            local unsub = w.query(a) (trait)

            w.insert(e, a, 10)

            expect(w.scopes[e]).exists()
            expect(w.scopes[e][trait]).exists()

            unsub()
            expect(w.scopes[e][trait]).is(nil)
        end)

        test('should defer despawn called inside trait', function()
            local w = world()
            local a = w.spawn()
            local b = w.spawn()
            local e = w.spawn()

            w.query(a) (function(entity)
                w.insert(entity, b, true)
                w.despawn(entity)

                -- deferred
                expect(w.get(entity, b)).never_exists()
                expect(w.records[entity]).exists()
            end)

            w.insert(e, a, 123)

            -- post flush
            expect(w.records[e]).is(nil)
        end)

        test('should allow remove inside trait before despawn (remove ignored)', function()
            local w = world()
            local a = w.spawn()
    
            local e = w.spawn()
            w.insert(e, a, 100)

            local ran = false
            w.query(a) (function(_, clean)
                clean(function()
                    ran = true
                end)
            end)

            w.query(a)(function(entity)
                w.remove(entity, a)
                w.despawn(entity)
            end)

            expect(ran).is_true()
            expect(w.records[e]).is(nil)
        end)

        test('should allow multiple operations after despawn in same trait, only despawn applied', function()
            local w = world()
            local A = w.spawn()
            local B = w.spawn()
            local e = w.spawn()

            w.insert(e, A, 10)

            w.query(A)(function(entity)
                w.despawn(entity)
                w.insert(entity, B, 99)
                w.remove(entity, A)
            end)

            expect(w.records[e]).is(nil)
        end)

        test('should not despawn entity immediately if multiple traits run on same entity', function()
            local w = world()
            local a = w.spawn()

            local seen = {}

            w.query(a) (function(entity)
                table.insert(seen, true)
                w.despawn(entity)
                expect(w.records[entity]).exists()
            end)

            w.query(a) (function(entity)
                table.insert(seen, true)
                expect(w.records[entity]).exists()
            end)

            local e = w.spawn()
            w.insert(e, a, 50)

            expect(#seen).is(2)
            expect(w.records[e]).is(nil)
        end)

        test('should not retrigger query when component is removed inside another query', function()
            local w = world()
            local a = w.spawn()
            local b = w.spawn()
            local c = w.spawn()

            local e = w.spawn()
            --[ A, B ]
            w.insert(e, a)
            w.insert(e, b)

            local first_calls = 0
            local second_calls = 0

            w.query(a, b) (function(entity)
                first_calls += 1

                -- [ A, B, C]
                w.insert(entity, c)
            end)

            w.query(b, c) (function(entity)
                second_calls += 1

                -- [ A, B ]
                w.remove(entity, c)
            end)

            expect(first_calls).is(1)
            expect(second_calls).is(1)

            w.insert(e, c)
            expect(second_calls).is(2)
        end)
    end)
end