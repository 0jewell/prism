type lune_tiniest = typeof(require('../lib/tiniest_for_lune').configure({}))

local Prism = require('../../src/lib')
local Query = Prism.Query
local Piece = Prism.Piece

return function(tiniest: lune_tiniest)
    local describe = tiniest.describe
	local test = tiniest.test
    local expect = tiniest.expect

    describe('Query', function()

        test('should create query', function()
            local query = Query { query = function() end }
            
            expect(getmetatable(query)).exists()
            expect(query.settings).is_a('table')

            expect(getmetatable(query).New).is_a('function')
        end)

        test('should should merge settings', function()
            local query = Query { query = function() end }

            expect(query.settings.priority).is_a('number')
        end)

        test('should not allow empty query setting', function()
            expect(function()
                Query { query = nil :: any }
            end).fails()
        end)

        test('should add trait', function()
            local piece = Piece()
            local query = Query { query = function() return piece end }
            
            query:trait('trait', function() end)
            expect(query.traits[1]).exists()
        end)
    end)
end