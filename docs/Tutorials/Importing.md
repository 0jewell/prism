# Importing Prism

After downloading **Prism**, it should be in a ``Packages`` folder on ``ReplicatedStorage``.

When using Prism as a variable in your code, it contains a dictionary with the following structure:

!!! caution "Freezed data"
    The returned table is freezed.

```luau title="Prism.luau"
return {
    Registry = require(script.Registry),
    Query = require(script.Query),
    Piece = require(script.Piece),
    Clean = require(script.Modules.Clean)
}
```