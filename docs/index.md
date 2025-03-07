# Home

![Prism Logo](assets/home/logo-light-theme.svg#only-light)
![Prism Logo](assets/home/logo-dark-theme.svg#only-dark)

**Prism** is a powerful and flexible **Entity Component System** (ECS) library designed for efficient game development in Roblox.
<br>It enables a data-driven approach to managing entities and their behaviors.

## Introduction

This is a rework of **Celesta**, my old ECS library, created 7 months ago. After having some problems with Celesta development, I stopped it and now I decided to open-source the new version of it with a new name -- Prism.

## Usage

```lua
local Packages = game.ReplicatedStorage.Packages
local Prism = require(Packages.Prism)

local health = Prism.Piece {
    max = 100,
    current = 100
}

return Prism.Query { query = function() return health end }

:trait('Update Health', function(data, health)
    -- Code logic here
end)
```