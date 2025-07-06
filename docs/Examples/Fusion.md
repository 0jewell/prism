# Using Fusion with Prism

This example shows how to use Fusion states in pieces data.

### Overview

```lua linenums="1"
local Packages = game.ReplicatedStorage.Packages

local Fusion = require(Packages.Fusion)
local peek = Fusion.peek
local scoped = Fusion.scoped
type Value<T> = Fusion.Value<T>

local Prism = require(Packages.Prism)
local from = Prism.from
type Piece<D> = Prism.Piece<D>

local function Valuing(data)
    local scope = scoped()
    return from(Fusion.Value, scope, data)
end

type healthData = Piece<{ 
    max: number,
    current: Value<number>
}>
local health: healthData = Prism.Piece {
    max = 100,
    current = Valuing(100)
}

local HealthBar = Instance.new('Frame')
local BloodVignette = Instance.new('Frame')

return Prism.Query { query = function() return health end }

:trait('UpdateHealthBar & ScreenState', function(data, health)
    local current = health.data.current
    local max = health.data.max

    local scope = Fusion:innerScope(data.cleaning)
    
    scope:Hydrate(HealthBar) {
        Size = scope:Computed(function(use)
            local percent = use(current) / max

            return UDim2.fromScale(percent, 1)
        end)
    }

    scope:Observer(current):onChange(function()
        local newValue = peek(current)

        if newValue <= 50 then
            BloodVignette.Visible = true
        else
            BloodVignette.Visible = false
        end
    end)
end)
``` 