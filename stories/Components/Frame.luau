local Types = require(script.Parent.Types)

local function Text(
    props: Types.FrameProps
): Frame

    local frame = Instance.new('Frame')
    frame.Size = props.size or UDim2.fromOffset(300, 400)
    frame.BackgroundColor3 = Color3.fromRGB(54, 54, 54)
    frame.Parent = props.parent

    return frame
end

return Text