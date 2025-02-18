local Prism = require(game.ReplicatedStorage.Packages.Prism)
local Piece = Prism.Piece

local mapQuery = Prism.mapQuery
local match = Prism.match

local Registry = Prism.Registry()

local Piece1, Piece2 = Piece(), Piece()
local QueryMap = mapQuery (Registry, { Piece1, Piece2 })

local entity = Registry:entity()

Registry:add(entity, Piece1)
Registry:add(entity, Piece2)

print(Registry:contains(entity, Piece()))

if match(Registry, entity, QueryMap) then
	print('Entity matches')
else
	print('Entity does not match')
end

local e = Registry:entity()
local health = Prism.Piece(100)

Registry:add(e, health)