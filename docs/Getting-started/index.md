# Getting Started

To start a new project with Prism, you'll need to create a `world` and set up your traits.
First, import Prism and create your world:
 
```luau title="shared/world.luau"
local prism = require(ReplicatedStorage.prism)

local world = prism.world.new()

return world
```

## Create your components

Next, define your components module

```luau title="shared/components.luau" linenums="1"
local world = require(shared.world)

return {
    alive = world:spawn(),
    energy = world:spawn()
}
```

!!! tip Types
     Check [this guide](../Guides/Strict-typing.md) to type your components data

## Add a trait to the world

Then, define a behavior to your entities

```luau title="systems/energy.luau"
local world = require(shared.world)

local components = require(shared.components)
local alive, energy = components.alive, components.energy

world:query(alive, energy) (function(entity, clean)
    -- regenerate 1 energy every second
    local loop = task.spawn(function()
        while task.wait(1) do
            local energy = world:ask(entity, energy)
            world:assign(entity, math.min(100, energy + 1))
        end
    end)
    
    -- cleanup coroutine on remove
    clean(function() task.cancel(loop) end)
end)

return nil
```

## Create an entity

Now, create an entity with some initial energy and the `alive` component

```luau
local player = world:spawn()

world:insert(player,
    energy, 50,
    alive, true
)
```

## Next steps

You can continue by:

- Defining more components like Health, Speed, Burning, etc.
- Creating more complex systems like damage over time, status effects, or AI behavior
- Exploring the internals of the world, query, and assign APIs