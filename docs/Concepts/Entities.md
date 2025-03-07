# Entities and Pieces

Entities are unique identifiers that act as containers for Pieces (components), defining their data and state.
Entities do not store logic or behavior directly; instead, Traits (systems) operate on entities based on their assigned Pieces.

```lua
local entity = Registry:entity()
```

### Pieces
A **Piece** is a data container that is added to an entity. Pieces can serve various purposes such as:

- Serving as simple tags (e.g., "this entity is a `Player`").
```lua
local player = Registry:entity()

--// Entities that are attached to other entities are called Pieces too.
Registry:add(entity, player)
```

- Holding structured data (e.g., "this entity has `Health` with a maximum of `100`").
```lua
local health = Piece { maximum = 100 }
Registry:add(entity, health)
```

- Creating associations between entities (e.g., "Enemy is `targeting` Player").
```lua
local enemy = Registry:entity()
local targeting = Registry:entity()
local player = Registry:entity()

Registry:add(enemy, Registry:pair(targeting, player))
```

- Optionally storing extra information (e.g., "Enemy is `looking` for player within `20` meters").
```lua
local enemy = Registry:entity()
local looking = Registry:entity()
local player = Registry:entity()

Registry:add(enemy, Registry:pair(looking, player), { distance = 20 })
```

### Pieces are entities

Since Pieces are the only way to define an entity’s data, every Piece is inherently an entity.
When a Piece is created, it automatically becomes an entity within the registry. This mean that all of the API that apply to regular entities also apply to pieces.

```lua
local Piece = Prism.Piece

local health, networked = Piece(...), Piece(...)
Registry:add(health, networked)
```

In general, Pieces are primarily used to define data structures before runtime.
They serve as blueprints for entity composition, ensuring that the necessary attributes are established before the game logic starts executing.