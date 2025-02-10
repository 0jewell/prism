local Prism = require(game.ReplicatedStorage.Packages.Prism)

local Stories = script.Parent.Parent
local Components = Stories.Components

local Text = require(Components.Text)
local Frame = require(Components.Frame)
local Separation = require(Components.Separation)

local function Story(props)

    local piece = { id = 1, type = 'hello' }
    local query = Prism.Query { query = function() return piece end }

    local function queryDataToString<P...>(
        query: Prism.Query<P...>
    )

        local settings = query.settings

        local pieces = {}
        for _, piece in { settings.query() } do
            table.insert(pieces, piece.id)
        end

        return 'Settings = ['
            .. ` priority: {settings.priority},`
            .. ` pieces: [ {table.concat(pieces, ', ')} ] `
            .. ']'
    end

    local frame = Frame {
        parent = props.target
    }

    Text {
        order = 1, text = 'Data', textSize = 20,
        font = Enum.Font.GothamBold, parent = frame
    }

    Separation {
        order = 2, parent = frame
    }

    Text {
        order = 3, text = 'QUERY:\n' .. queryDataToString(query),
        size = UDim2.fromScale(1, 0.15), parent = frame
    }

    local listLayout = Instance.new('UIListLayout', frame)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local corner = Instance.new('UICorner', frame)
    corner.CornerRadius = UDim.new(0.1)

    return function()
        frame:Destroy()
    end
end

return {
    render = Story
}