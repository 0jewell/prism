local task = require('@lune/task')

local Prism = require('../src/lib')
local Piece = Prism.Piece
local key = Prism.key

local Registry = Prism.Registry()

local Piece1, Piece2 = Piece('piece 1'), Piece('piece 2')

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
		warn('=== TRAIT ===')
		print(entity, piece, data)
	end)

	print('Adding piece 1 & 2')
	Registry:add(entity, { key(Piece1, Piece2) })

	warn('=== PIECE 1 ===')
	print('Has:', Registry:contains(entity, Piece1))
	print('Data:', Registry:ask(entity, Piece1))
end