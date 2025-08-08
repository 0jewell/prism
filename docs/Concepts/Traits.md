# Traits

Traits define the behavior of entities by operating on entities that contain specific components.
They act as systems that process and modify entity states dynamically.

## Understading them

A **Trait is not a loop** or a frame-based system.  
It runs **exactly once** when an entity **first matches** the component requirements specified in the query.

```lua hl_lines="11"
local entity = world:spawn()
local health = world:spawn()

local counter = 0

world:query(health) (function(entity)
    print('This is the', counter, 'time')
    counter += 1
end)

world:insert(entity, health, 100) --> this is the 1 time
```

!!! note "Reactive, not continuous"
    Traits are **reactive**. They **only execute once** per matching event.  
    They do **not run every frame**, and they do **not loop** over entities continuously.  
    Think of them as event-driven systems triggered by changes in the entity's state.

If the entity stops matching (e.g., a required component is removed), the trait is automatically **removed**.  
If it later matches again, the trait is **re-applied**, and the function is executed **again once**.

```lua linenums="12" hl_lines="3"
world:remove(entity, health)

world:insert(entity, health, { value = 50 }) --> this is the 2 time
```

## Trait Cleanup

When writing traits that create or manage instances or resources,
it's important to manually add them to the cleaning scope.

```lua hl_lines="7"
local components = require(path.to.components)
local part = components.part

return function(world)
    world:query(part) (function(entity, clean)
        local instance = Instance.new('Part', workspace)
        clean(instance)

        world:assign(entity, part, instance)
    end)
end
```

!!! note "Modular Code"
    Separating your queries in modules allows for a cleaner codebase.
    From now on, we will follow this approach.