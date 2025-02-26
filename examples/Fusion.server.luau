local Packages = game.ReplicatedStorage.Packages

local Fusion = require(Packages.Fusion)
type Value<T> = Fusion.Value<T>

local peek = Fusion.peek

local Prism = require(Packages.Prism)
type Piece<D> = Prism.Piece<D>

local scope = Fusion.scoped()

local function Valuing(data)
    return Prism.from(Fusion.Value, scope, data)
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