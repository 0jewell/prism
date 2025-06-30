# Home

![Prism Logo](assets/home/logo-light-theme.svg#only-light)
![Prism Logo](assets/home/logo-dark-theme.svg#only-dark)

**Prism** is a powerful and flexible **Entity Component System** (ECS) library designed for efficient game development in Roblox.
<br>It enables a data-driven approach to managing entities and their behaviors.

## Introduction

This is a rework of **Celesta**, my old ECS library, created a couple months ago. After having some problems with Celesta development, I stopped it and now I decided to open-source the new version of it with a new name -- Prism.

## Usage

```lua
local world = require(shared.world)

local health = world:spawn()
local damaged = world:spawn()

local entity = world:spawn()

world:insert(entity,
    health, 100,
    damaged, 10
)

world:query(health, damaged) (function(entity)
    local health = world:ask(entity, health)
    local damaged = world:ask(entity, damaged)

    world:assign(entity, health, math.max(0, health - damaged)

    world:remove(entity, damaged)
end)
```