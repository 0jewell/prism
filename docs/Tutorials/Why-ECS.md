# Why Use ECS (and Why Prism)

In traditional game code, you often attach behavior directly to objects like models or parts.
For example, you might write a script inside an NPC model that controls how it moves.
This works for small games, but as things grow, this approach gets **harder** to manage.

You might end up with lots of duplicate code and objects that depend too much on each other.
Logic becomes scattered across scripts and folders, which leads to
difficult bugs when objects interact in unexpected ways.

**ECS** (Entity Component System) is a different way to organize game logic. Instead of
putting code inside objects, **you separate data (components) from behavior (systems)**.
This gives you more control over how things behave, makes debugging easier, produces
faster and more scalable code, and lets you reuse systems for AI, movement, damage, and more.

## What is ECS?

**ECS** is made of three parts: Entities, which are just IDs (numbers) that don’t hold data themselves;
Components, which are simple data attached to entities, such as `Health`, `Position`, or `Velocity`;
and Systems, which are functions that run over entities with specific components.

You can think of it like this: instead of doing something like assigning `Health` and
`Position` directly to an NPC and calling its Move method,

```lua
-- instead of doing this:
npc.Health = 50
npc.Position = Vector3.new(0, 5, 0)
npc:Move()
```

you spawn an entity in the world and insert components like `Health` and `Position` for that entity.

```lua
-- you do this:
local entity = world.spawn()
world.insert(entity, Health, 50)
world.insert(entity, Position, Vector3.new(0, 5, 0))
```

Then a **trait** somewhere else processes all entities that have `Position` and `Velocity` components and moves them accordingly.

## Why Use Prism?

**Prism** is a simple and efficient **ECS** system written for Roblox. It’s designed for
games where you want clean, organized logic and need to track state across many objects.
It offers good performance without complex boilerplate.

### Reactive Design

**Prism** is reactive, which means you can write [traits](../Concepts/Traits.md) that respond when entities are created
or changed. You don’t have to loop through all entities every frame unless you want to.

This is useful for objects that should react when spawned, like playing an animation or
starting movement, or for logic that only needs to run once, such as setting up a health bar.
**Prism** helps make your code modular and event-based, and it integrates well with reactive libraries like Fusion or Vide.

## When is ECS Useful?

You probably don’t need **ECS** for a game with only a few objects and one enemy.
But if your game has many enemies, different systems like AI, health, movement, status effects,
dynamically created objects, server-side state, or logic that repeats across different parts of the game,
**ECS** will make development **easier**.