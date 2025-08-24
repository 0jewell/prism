# Using Fusion with Prism

This example shows how to use fusion states in components data.

## Overview

Assuming the following code:

```luau title="shared/world.luau"
local packages = game.ReplicatedStorage.packages
local prism = require(packages.prism)

return prism.world.new()
```

```luau title="shared/components.luau"
local packages = game.ReplicatedStorage.packages
local shared = game.ReplicatedStorage.shared

local fusion = require(packages.fusion)
type value<T> = fusion.value<T>

local prism = require(packages.prism)
type entity<T> = prism.entity<T>

local world = require(shared.world)

return {
    health = world.spawn() :: entity<{
       max: number,
        current: value<number>
    }>
}
```

And then on your system:

```luau
local packages = game.ReplicatedStorage.packages
local shared = game.ReplicatedStorage.shared

local fusion = require(packages.fusion)
local scoped = fusion.scoped
local peek = fusion.peek
local hydrate = fusion.Hydrate
local computed = fusion.Computed

local world = require(shared.world)
local components = require(shared.components)

local health_bar = Instance.new('Frame')
local blood_vignette = Instance.new('Frame')

world.query(client, health) (function(entity, clean)
    local health = world.get(entity, health)
    local current = health.current
    local max = health.max

    local scope = scoped()
    clean(scope)
    
    hydrate(scope, health_bar) {
        Size = computed(function(use)
            local percent = use(current) / max

            return UDim2.fromScale(percent, 1)
        end)
    }
end)
``` 