local Types = require('./Types')
type Piece<D = unknown> = Types.Piece<D>
type UsedAs<D = unknown> = Types.UsedAs<unknown>

type Keys = Types.Keys

local Pieces = {}
local function Piece<D>(
    default: D?
): Piece<D>

    local self = { data = default :: D }
    
    Pieces[self] = true
    return self
end

type OnAdd = Types.OnAdd
local OnAdd = Piece() :: Piece<OnAdd>

type OnRemove = Types.OnRemove
local OnRemove = Piece() :: Piece<OnRemove>

local KeyMarker = Piece('lá ele')
local BuiltInPiece = Piece()

local function Key(
    ...: UsedAs
): Keys

    local keys = {}

    for index = 1, select('#', ...) do
        local piece = select(index, ...)
        keys[piece] = KeyMarker
    end

    return setmetatable(keys, KeyMarker)
end

local function Is(
    piece: Piece<never>
): boolean

    return Pieces[piece] or false
end

local function From(constructor, ...): any
    local default = { ... }

    return function()
        return constructor(unpack(default))
    end
end

return table.freeze {
    New = Piece,
    from = From,
    is = Is,
    key = Key,

    OnAdd = OnAdd,
    OnRemove = OnRemove,
    KeyMarker = KeyMarker,
    BuiltInPiece = BuiltInPiece
}