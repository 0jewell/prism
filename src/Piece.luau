local Package = script.Parent

local Types = require(Package.Types)
type Piece<D = unknown> = Types.Piece<D>

local function Piece<D>(
    default: D?
): Piece<D>

    local self = { data = default :: D }
    
    return self
end

local function from(constructor, ...): any
    local default = { ... }

    return function()
        return constructor(unpack(default))
    end
end

type OnAdd = Types.OnAdd
local OnAdd = Piece() :: Piece<OnAdd>

type OnRemove = Types.OnRemove
local OnRemove = Piece() :: Piece<OnRemove>

local BuiltInPiece = Piece()

return table.freeze {
    New = Piece,
    from = from,

    OnAdd = OnAdd,
    OnRemove = OnRemove,
    BuiltInPiece = BuiltInPiece
}