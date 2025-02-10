local Types = require(script.Parent.Types)

local function Text(
    props: Types.TextProps
): TextLabel

    local text = Instance.new('TextLabel')
    text.LayoutOrder = props.order or 0
    text.Text = props.text or 'Text'
    text.TextSize = props.textSize or 15
    text.Size = props.size or UDim2.fromScale(1, 0.1)
    text.BackgroundTransparency = 1
    text.Font = props.font or Enum.Font.GothamMedium
    text.TextColor3 = props.textColor or Color3.new(1, 1, 1)
    text.Parent = props.parent

    return text
end

return Text