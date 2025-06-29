local function color(r, g, b)
    return string.format('\27[38;2;%d;%d;%dm', r, g, b)
end

local reset = '\27[0m'

local red = color(255, 150, 150) 
local green = color(170, 240, 170)
local gray = color(190, 190, 190)
local cyan = color(170, 220, 255)
local magenta = color(220, 170, 240)

type color_input = string | number

local function colorize(text: color_input, code: string): string
    return code .. text .. reset
end

local function label(label: color_input): string
    return colorize(label, cyan)
end

local function header(text: color_input): string
    return colorize(text, magenta)
end

local function value(text: color_input): string
    return colorize(tostring(text), green)
end

local function error_text(text: color_input): string
    return colorize(text, red)
end

return {
    colorize = colorize,
    label = label,
    header = header,
    value = value,
    error_text = error_text,

    red = red,
    green = green,
    gray = gray,
    cyan = cyan,
    magenta = magenta,
}
