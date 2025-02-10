export type CommonProps = {
    parent: Instance?,
    order: number?
}

export type TextProps = CommonProps & {
    text: string?,
    textSize: number?,
    size: UDim2?,
    font: Enum.Font?,
    textColor: Color3?,
}

export type FrameProps = CommonProps & {
    size: UDim2?,
}

return {}