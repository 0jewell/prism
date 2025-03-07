# Traits

Traits define the behavior of entities by operating on entities that contain specific Pieces.
They act as systems that process and modify entity states dynamically.

### Understading them
A Trait is executed whenever an entity matches the required Pieces specified in its query.

```lua
local Query = Prism.Query { query = function() return health end }

local counting = 1

Query:trait('Regenerate Health', function(data, health)
    print('This is the', counting, 'time')
    counting += 1
end)

Registry:include { Query }

Registry:add(entity, health)
--> This is the 1 time
```

If the entity no longer meets the requirements, the trait is removed.
If it later meets the conditions again, the trait is reapplied.

```lua
Registry:remove(entity, health)

Registry:add(entity, health)
--> This is the 2 time
```
### Trait Cleanup
Traits can be added or removed dynamically, but removing a trait does not automatically revert changes.
You must manually handle the cleanup of any data associated with it.

```lua
return Prism.Query { query = function() return part end }

    :trait('Create part', function(data, part)
        local instance = Instance.new('Part')

        -- Store the instance for cleanup when the trait is removed
        table.insert(data.cleaning, instance)

        part.data.instance = instance
    end)
```

!!! note "Modular Code"
    Returning queries from modules allows for a cleaner codebase.
    From now on, we will follow this approach.

### Trait Execution Order
A single query can have multiple traits.
Traits are executed in the order they are defined within the query.

```lua
return Prism.Query { query = function() return part end }

    :trait('Create part', function(data, part)
        local instance = Instance.new('Part')

        -- Store the instance for cleanup when the Trait is removed
        table.insert(data.cleaning, instance)

        part.data.instance = instance
    end)

    :trait('Print part', function(data, part)
        print(part.data.instance)
        --> 'Part'
    end)
```