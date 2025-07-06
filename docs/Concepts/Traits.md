# Traits

Traits define the behavior of entities by operating on entities that contain specific Pieces.
They act as systems that process and modify entity states dynamically.

### Understading them

A Trait is executed whenever an entity matches the required components specified in a query.

```lua
local entity = world:spawn()
local health = world:spawn()

world:insert(entity, health, 100)

local counter = 1

world:query(health) (function(entity, scope)
    print('This is the', counter, 'time')
    counter += 1
end)
--> this is the 1 time
```

!!! note 
    When a query is created in runtime, every entity that matches it
    will be applied. This mean you can can insert components before actually
    creating any systems

If the entity no longer meets the requirements, the trait is removed.
If it later meets the conditions again, the trait is reapplied.

```lua
world:remove(entity, health)

world:insert(entity, health, { value = 50 })
-- > This is the 2 time
```

### Trait Cleanup

When writing traits that create or manage instances or resources,
it's important to manually clean them up when the trait no longer applies.

```lua
local components = require(path.to.components)
local part = components.part

return function(world)
    world:query(part) (function(entity, scope)
        local instance = Instance.new('Part')
        table.insert(scope, instance)

        world:assign(entity, part, instance)
    end)
end
```

!!! note "Modular Code"
    Separating your queries in modules allows for a cleaner codebase.
    From now on, we will follow this approach.