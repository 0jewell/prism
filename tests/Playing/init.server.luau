local Prism = require(game.ReplicatedStorage.Packages.Prism)
local Piece = Prism.Piece

local Registry = Prism.Registry()

local Piece1, Piece2 = Piece(10), Piece(5)
local Query = Prism.Query { query = function() return Piece1, Piece2 end }

Query:trait('Test', function(data, piece1, piece2)
	print('Trait applied')

	local thread; thread = task.spawn(function()
		local seconds = 1

		while task.wait(1) do
			print(seconds, 'seconds has passed!')
			seconds += 1
		end
	end)

	table.insert(data.cleaning, thread)
end)

do
	Registry:include { Query }

	local entity = Registry:entity()
	Registry:add(entity, Piece1)
	Registry:add(entity, Piece2)

	task.wait(3)

	Registry:delete(entity)
end