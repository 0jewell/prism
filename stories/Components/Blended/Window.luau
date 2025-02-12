local Components = script.Parent.Parent
local Types = require(Components.Types)

local Frame = require(Components.Frame)
local Text = require(Components.Text)
local Separation = require(Components.Separation)

local function Window(
    props: Types.WindowProps
)

    local window = Frame {
        parent = props.parent
    }

    Text {
        order = 1, text = props.title or 'Data',
        textSize = 20, font = Enum.Font.GothamBold,
        parent = window
    }

    Separation {
        order = 2, parent = window
    }

    local listLayout = Instance.new('UIListLayout', window)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local corner = Instance.new('UICorner', window)
    corner.CornerRadius = UDim.new(0.1)

    return window
end

return Window