# Entities and components

Entities are unique identifiers that act as containers for components, defining their data and state.
Entities do not store logic or behavior directly; instead, [traits](Traits.md) (systems) operate on entities based on their assigned components.

### 

```luau linenums="1"
local entity = world:spawn()
```

### Components

To first understand components, you need to understand that: **components are also entities.**

In most ECS libraries, every component is simply an **entity used as a label or identifier for data**.
When you create something like `health` or `player`, you're just creating an entity that serves a specific role in context.

The distinction between an "entity" and a "component" is entirely **semantic and contextual**:

- When an entity is used to **store data, tags, or relationships** inside another entity, we call it a *component*.
- When it's used as a **standalone game object** (like a player, enemy, or projectile), we refer to it as a *primary entity*.

```luau linenums="1"
local player = world:spawn() -- 'player' is a game object
local health = world:spawn() -- 'health' is a component
world:assign(player, health, 100) -- Here, 'health' acts as a component
```

Because components are just identifiers, **you could technically assign any entity to another — even the same one:**
```lua linenums="4"
world:assign(player, player, player)
```

This works because the world treats the *second* parameter (`player`) as the **component label**,
and the *third* as the **value** being associated. What matters is not what the entity "is," **but how it's used.**

### Use cases

In general **component** is simple a information that is added to an entity.
They can serve various purposes such as:

- Serving as simple tags (e.g., "this entity is a `player`").
```luau linenums="1"
local player = world:spawn()
world:assign(entity, player)
```

- Holding structured data (e.g., "this entity has `health` with a maximum of `100`").
```luau linenums="1"
local health = world:spawn()
local data = { max = 100, current = 100 }
world:assign(entity, health, data)
```

!!! tip Recommendation
    We recommend you [to check this page](../Guides/Strict-typing.md) on typing your components data.