# Strict typing

### Type notations

Programming without guidance can be difficult and frustrating. If you often find yourself opening 2 Visual
Studio Code tabs or perhaps constantly switching files on Studio to look at type definitions, that's usually a sign that something is not quite right.

In Luau, it is possible to add **type annotations** to variables, return types and parameters.
And when type annotations get too complex, the type inference simple won't work anymore, or it will default to `any`.

```luau linenums="1"
local var: number = 10

local function func(): number
    return var
end
```

### How to type components

Components are just numbers, aren't they? Well, that's technically correct. But the type checker does not need to know that.
In other words, you can simulate the component's type by **annotating it as a table**, with a fake field holding its type.

```luau linenums="1" hl_lines="8"
local world = require(path.to.world)
type entity<T> = world.entity<T>

type health_data = entity<{
    max: number,
    current: number
}>
local health = world:spawn() :: health_data
```

In this code, `health` is typed as:

```
_t: {
    max: number,
    current: number
}
```

But in reality, it is a number.

### Getting component data

You can get full type check support when asking for data using a typed component:

```luau linenums="8" hl_lines="8"
local entity = world:spawn()

world:assign(entity, health, {
    max = 100,
    current = 100
})

local health_data = world:ask(entity, health) --> data is typed
```