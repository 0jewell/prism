local Prism = require(game.ReplicatedStorage.Packages.Prism)

local Stories = script.Parent.Parent

local Components = require(Stories.Components)
local Window = Components.Window
local Text = Components.Text

local function Story(props)

    local world = Prism.World()
    local e, e2, e3 = world:entity(), world:entity(), world:entity()
    world:add(e, e2, 'data')
    world:add(e, e3, 'data')

    local function worldDataToString(
        world: Prism.World
    ): string
        
        local entities, entityMap = {}, {}
    
        for entity, entityData in pairs(world.data) do
            local mappedEntityData = {}

            for piece, data in pairs(entityData) do
                table.insert(mappedEntityData, `{piece} = {data}`)
            end
            if #mappedEntityData <= 0 then continue end

            table.insert(
                entities,
                `{entity} = [ {table.concat(mappedEntityData, ', ')} ]`
            )
        end

        for entity, map in pairs(world.entityMap) do
            local mappedEntities = {}

            for e in pairs(map) do 
                table.insert(mappedEntities, e)
            end

            table.insert(
                entityMap,
                `{entity} = [ {table.concat(mappedEntities, ', ')} ]`
            )
        end

        return 'data = [\n'
        .. `{table.concat(entities, ', \n')}`
        .. '\n]\n\n'

        .. 'entityMap = [\n'
        .. `{table.concat(entityMap, ', \n')}`
        .. '\n]'
    end

    local window = Window {  parent = props.target, title = 'World' }

    Text {
        order = 3, text = worldDataToString(world),
        size = UDim2.fromScale(1, 0.45), parent = window
    }

    return function()
        window:Destroy()
    end
end

return {
    render = Story
}