local Prism = require(game.ReplicatedStorage.Packages.Prism)
local Piece = Prism.Piece

local Registry = Prism.Registry()

local Piece1, Piece2 = Piece(10), Piece(5)

local totalApplications = 0

local query1 = Prism.Query { query = function() return Piece1 end }

for i = 1, 5 do
	query1:trait('Test', function(data, piece1)
		print(`(Query 1) Trait {i}: applied`)
		totalApplications += 1
	end)
end

local query2 = Prism.Query { query = function() return Piece1, Piece2 end }

for i = 1, 5 do
	query2:trait('Test', function(data, piece1, piece2)
		print(`(Query 2) Trait {i}: applied`)

		totalApplications += 1
	end)
end

do
	Registry:include { query1, query2 }

	for i = 1, 100 do
		local entity = Registry:entity()

		Registry:add(entity, Piece1)
		Registry:add(entity, Piece2)
	end

	print('Total Applied:', totalApplications)
end