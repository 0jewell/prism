local Prism = require(game.ReplicatedStorage.Packages.Prism)
local Piece = Prism.Piece

local Registry = Prism.Registry()

local Piece1, Piece2 = Piece(), Piece()
local Query = Prism.Query { query = function() return Piece1, Piece2 end }

Query:trait('Test', function(piece1, piece2)
	print('Applied!')
end)
Registry:include { Query }

local entity = Registry:entity()

Registry:add(entity, Piece1)
Registry:add(entity, Piece2)