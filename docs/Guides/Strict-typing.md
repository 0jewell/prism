# Strict typing

### Type notations

Programming blindly is hard and it can be frustrating. If you frequently open 2 Visual
Studio Code tabs or maybe switch files on Studio you need to know there's something wrong.

In Luau, you can add **type notations** to variables, return types and parameters.
And when type notations get really complex, the type inference simple won't work anymore, or type it as `any`.

```luau linenums="1"
local var: number = 10

local function func(): number
    return var
end
```

### How to type components

Components are just numbers, aren't they? Well, you are not wrong. But the type checker does not need to know that.
In another words, you can lie by **typing the entity as a table**, with a fake field holding its type.

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

### Getting component data

You can get full type check support when asking for a data using a typed component:

```luau linenums="8" hl_lines="8"
local entity = world:spawn()

world:assign(entity, health, {
    max = 100,
    current = 100
})

local health_data = world:ask(entity, health) --> data is typed
```