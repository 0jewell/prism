# Using Prism with CollectionService

Roblox's `CollectionService` lets you tag instances in the Explorer, making it possible to reference
those instances in your code.

This is useful when you are working with objects that are already placed in the scene, such as doors, trees, or anything else you may use on your map.

### What this does?
- You can create entities for those static objects
- You can add functionality to them using Prism

### Example code

```luau title='shared/tag.luau'
local CollectionService = game:GetService('CollectionService')

local components = require(shared.components)
local instance = components.instance

-- internal tag-to-component map
local tags = {}

-- pawns an entity and attaches components to it
local function spawn_bound(
    instance: Instance,
    component: entity
)
    local id = world:spawn()

    world:insert(id,
        component, nil,
        instance, instance
    )

    instance:SetAttribute('serverid', id)
end

-- loads a collection tag as a component
local function load_collection(tag: string): entity
    if tags[tag] then return tags[tag] end

    local tag_component = world:spawn()
    tags[tag] = tag_component

    local function on_added(instance)
        spawn_bound(instance, tag_component)
    end
    CollectionService:GetInstanceAddedSignal(tag):Connect(on_added)

    local function on_removed(instance)
        local id = instance:GetAttribute('serverid')
        if id then
            world:despawn(id)
        end
    end
    CollectionService:GetInstanceRemovedSignal(tag):Connect(on_removed)

    for _, instance in CollectionService:GetTagged(tag) do
        spawn_bound(instance, tag_component)
    end

    return tag_component
end

return load_collection
```

### Usage

```luau
local tag = require(shared.tag)
local killpart = tag('Killpart')

world:query(killpart, instance) (function(entity, scope)
    local instance = world:ask(entity, instance)

    local connection = instance.Touched:Connect(function(touch)
        -- kill logic
    end)

    table.insert(scope, connection)
end)
```