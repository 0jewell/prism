local Types = require(script.Parent.Types)

local function Text(
    props: Types.CommonProps
): Frame

    local separation = Instance.new('Frame')
    separation.LayoutOrder = props.order or 0
    separation.BackgroundColor3 = Color3.new(1, 1, 1)
    separation.Size = UDim2.new(1, 0, 0, 1)
    separation.Parent = props.parent

    return separation
end

return Text