local Package = script.Parent

local Types = require(Package.Common.Types)
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

return table.freeze {
    New = Piece,
    from = from
}