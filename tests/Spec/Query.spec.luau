local Prism = require(game.ReplicatedStorage.Packages.Prism)
local Query = Prism.Query
local Piece = Prism.Piece

local function QueryTest()
    describe('Query', function()

        it('should create query', function()
            local query = Query { query = function() end }
            
            expect(getmetatable(query)).to.be.ok()
            expect(typeof(query.settings)).to.equal('table')

            expect(typeof(getmetatable(query).New)).to.be.equal('function')
        end)

        it('should should merge settings', function()
            local query = Query { query = function() end }

            expect(typeof(query.settings.priority)).to.be.equal('number')
        end)

        it('should not allow empty query setting', function()
            expect(function()
                Query { query = nil :: any }
            end).to.throw()
        end)

        it('should add trait', function()
            local piece = Piece()
            local query = Query { query = function() return piece end }
            
            query:trait('trait', function() end)
            expect(query.traits['trait']).to.be.ok()
        end)

        it('should not allow duplicated trait names', function()
            local piece = Piece()
            local query = Query { query = function() return piece end }

            expect(function()
                query:trait('trait', function() end)
                query:trait('trait', function() end)
            end).to.throw()
        end)
    end)
end

return QueryTest