local tiniest = require('@tiniest/tiniest_for_lune')
type testing = typeof(tiniest.configure {})

local prism = require('@prism/')
local world = prism.world

return function(testing: testing)
    local describe = testing.describe
    local test = testing.test
    local expect = testing.expect

    describe('world', function()
        test('should despawn an entity', function()
            local w = world()
            local e = w.spawn()

            w.despawn(e)
            expect(w.records[e]).is(nil)
        end)
    end)
end