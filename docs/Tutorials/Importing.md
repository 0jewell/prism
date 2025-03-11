# Importing Prism

After downloading **Prism**, it should be in a ``Packages`` folder on ``ReplicatedStorage``.

When using Prism as a variable in your code, it contains a dictionary with the following structure:

!!! caution "Freezed data"
    The returned table is freezed.

```luau title="Prism.luau"
local Data = require(script.Modules.Data)
local Clean = require(script.Modules.Clean)

local Registry = require(script.Registry)
local Query = require(script.Query)
local Piece = require(script.Piece)

return {
    Registry = Registry.New,
    Query = Query.New,
    Piece = Piece.New,

    from = Piece.from,
    Clean = Clean
}
```