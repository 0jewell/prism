local Prism = require(game.ReplicatedStorage.Packages.Prism)
local on_add = Prism.on_add
local pair = Prism.pair

local World = Prism.World()

local e = World:entity()
local e2 = World:entity()
local e3 = World:entity()

World:add(e, on_add, function(entity, target, data)
    print(target, 'added', data, 'to', entity)
end)

World:add(e, e2, 'data')
World:add(e, e3, 'more data')

local Eats = World:entity()
local Apples = World:entity()

World:add(e, pair(Eats, Apples), 10)