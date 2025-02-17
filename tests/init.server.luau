--!nocheck
local TestEZ = require(game.ReplicatedStorage.Packages.TestEZ)

local TestBootstrap = TestEZ.TestBootstrap
TestBootstrap:run( script.Spec:GetChildren() )