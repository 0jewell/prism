local task = require('@lune/task')

local Prism = require('../src/lib')
local Piece = Prism.Piece
local tag = Prism.tag
local tags = Prism.tags

local Registry = Prism.Registry()

local Piece1, Piece2 = Piece('piece 1'), Piece(10)

local Query = Prism.Query { query = function() return Piece1, Piece2 end }

Query:trait('Test', function(data, piece1, piece2)
	local seconds = 1

	local thread = task.spawn(function()
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

	Registry:add(entity, Prism.OnAdd, function(entity, piece, data)
		print(entity, piece, data)
	end)

	Registry:add(entity, tags { [Piece1] = 'Piece', tag(Piece2) })
end