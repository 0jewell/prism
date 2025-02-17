local Packages = game.ReplicatedStorage.Packages

local Iris = require(Packages.Iris)
local Prism = require(Packages.Prism)

local function Story(props)

    local world = Prism.World()
    local entity = world:entity()
    local health = Prism.Piece(100)

    world:add(entity, health)

    Iris:Connect(function()
        Iris.Window {'World'}
            Iris.Text {'Entity data:'}
            
            Iris.CollapsingHeader {'Show'}
                Iris.Indent()
                    for entity, entityData in pairs(world.data) do
                        local mappedEntityData = {}

                        for piece, data in pairs(entityData) do
                            table.insert(mappedEntityData, `{piece} = {data}`)
                        end

                        if #mappedEntityData <= 0 then continue end

                        Iris.Text { `{entity} = [ {table.concat(mappedEntityData, ', ')} ]` }
                    end
                Iris.End()
            Iris.End()

            Iris.Separator()
            Iris.Text {'Entity map:'}

            Iris.CollapsingHeader {'Show'}
                for entity, map in pairs(world.entityMap) do
                    local mappedEntities = {}

                    for e in pairs(map) do 
                        table.insert(mappedEntities, e)
                    end

                    Iris.Text { `{entity} = [ {table.concat(mappedEntities, ', ')} ]` }
                end
            Iris.End()
        Iris.End()
    end)
end

return {
    iris = Iris,
    story = Story
}