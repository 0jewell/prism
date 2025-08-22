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
    end)
end