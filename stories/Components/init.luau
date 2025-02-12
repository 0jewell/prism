local Blended = script.Blended

local Window = require(Blended.Window)

local Frame = require(script.Frame)
local Separation = require(script.Separation)
local Text = require(script.Text)

return table.freeze {
    Window = Window,
    
    Frame = Frame,
    Separation = Separation,
    Text = Text
}