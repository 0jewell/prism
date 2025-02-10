local Prism = require(game.ReplicatedStorage.Packages.Prism)
local Query = Prism.Query

local function QueryTest()
    describe('Query', function()

        it('should create query', function()
            local query = Query { query = function() end }
            
            expect(getmetatable(query)).to.be.ok()
            expect(typeof(query.settings)).to.equal('table')

            local query2 = Query { query = function() end }
            expect(getmetatable(query)).to.never.be.equal(getmetatable(query2))
        end)
    end)
end

return QueryTest