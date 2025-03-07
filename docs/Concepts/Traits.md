# Traits
Traits define the behavior of entities by operating on entities that contain specific Pieces.
They act as systems that process and modify entity states dynamically.

### Understanding them

A Trait is executed when an entity matches the required Pieces specified in its query.
It can react to state changes, update values, or trigger actions based on entity data. It's up to you.

```lua
local Query = Prism.Query { query = function() return health end }

local Counting = 1

Query:trait('Regenerate Health', function(data, health)
    print('This is the', counting, 'time')
    Counting += 1
end)

Registry:include { query }

Registry:add(entity, health)
--> This is the 1 time
```

If the requirements are no longer meet, they will be removed. When this happen,
if the entity meet the requirements again, the trait you be applied once again.

```lua
Registry:remove(entity, health)

Registry:add(entity, health)
--> This is the 2 time
```

### Trait cleaning scope

Traits can be added to or removed from entities, but reverting changes is not done automatically.
When removing a trait, you must manually handle the cleanup of any data associated with it.

```lua
return Prism.Query { query = function() return part end }

    :trait('Create part', function(data, part)
        local instance = Instance.new('Part')

        -- The trait scope is cleaned when the trait is removed
        table.insert(data.cleaning, instance)

        part.data.instance = instance
    end)
```

!!! note "Modularized code"
    By returning queries in modules, you can easily organize your codebase into different files. From now on, we will use this approach.

### Trait order

Queries can have multiple traits. By doing so, the trait creation order will count as the priority of it.

```lua
return Prism.Query { query = function() return part end }

    :trait('Create part', function(data, part)
        local instance = Instance.new('Part')

        -- The trait scope is cleaned when the trait is removed
        table.insert(data.cleaning, instance)

        part.data.instance = instance
    end)
    
    :trait('Print part', function(data, part)
        print(part.data.instance)
        --> "Part"
    end)
```