# Importing Prism

After downloading **Prism**, it should be in a ``Packages`` folder on ``ReplicatedStorage``.

When using Prism as a variable in your code, it contains a dictionary with the following structure:

```luau title="Prism.luau"
return {
    world = require(script.world)
}
```

For use outside of Roblox, it contains the following structure:

```luau title="Prism.luau"
return {
    world = require('@self/world'),
    debugger = require('@self/debugger')
}
```