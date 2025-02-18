local Packages = game.ReplicatedStorage.Packages

local Iris = require(Packages.Iris)
local Prism = require(Packages.Prism)

local function Story(props)

    local registry = Prism.Registry()
    local entity = registry:entity()
    local health = Prism.Piece(100)

    registry:add(entity, health)

    Iris:Connect(function()
        Iris.Window {'Registry'}

            Iris.Text {'Entity data:'}

            Iris.CollapsingHeader {'Show'}
                Iris.Text {'TODO'}
            Iris.End()

            Iris.Separator()

            Iris.Text {'Entity map:'}

            Iris.CollapsingHeader {'Show'}
                Iris.Text {'TODO'}
            Iris.End()
        Iris.End()
    end)
end

return {
    iris = Iris,
    story = Story
}