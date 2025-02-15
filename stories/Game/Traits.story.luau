local Prism = require(game.ReplicatedStorage.Packages.Prism)

local Stories = script.Parent.Parent

local Components = require(Stories.Components)
local Window = Components.Window
local Text = Components.Text

local function Story(props)

    local piece = Prism.Piece()
    local query = Prism.Query { query = function() return piece end }

    local function querySettingsToString<P...>(
        query: Prism.Query<P...>
    ): string

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

    local window = Window {  parent = props.target }

    Text {
        order = 3, text = 'QUERY:\n' .. querySettingsToString(query),
        size = UDim2.fromScale(1, 0.15), parent = window
    }

    return function()
        window:Destroy()
    end
end

return {
    render = Story
}