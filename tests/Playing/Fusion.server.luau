--!nolint LocalUnused
local Packages = game.ReplicatedStorage.Packages

local Fusion = require(Packages.Fusion)

local Value = Fusion.Value
type Value<T> = Fusion.Value<T>

local Scoped = Fusion.scoped
local peek = Fusion.peek

local Prism = require(Packages.Prism)

local Query = Prism.Query

local Piece = Prism.Piece
type Piece<D> = Prism.Piece<D>

local from = Prism.from

local Registry = Prism.Registry()

local scope = Scoped()

type healthData = Piece<{ 
    max: number,
    current: Value<number>
}>
local health: healthData = Piece {
    max = 100,
    current = from(Value, scope, 100)
}

local HealthBar = Instance.new('Frame')
local BloodVignette = Instance.new('Frame')

return Query { query = function() return health end }

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