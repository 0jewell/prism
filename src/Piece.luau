local Types = require('./Types')
type Piece<D = unknown> = Types.Piece<D>
type UsedAs<D = unknown> = Types.UsedAs<unknown>

type DataMap = Types.DataMap
type Tags = Types.Tags

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

local TagMarker = Piece()
local BuiltInPiece = Piece()

local function Tag(
    ...: UsedAs
): Tags

    local tags = {}

    for index = 1, select('#', ...) do
        local piece = select(index, ...)
        tags[piece] = TagMarker
    end

    return setmetatable(tags, TagMarker)
end

local function Is(
    piece: Piece<never>
): boolean

    return Pieces[piece] or false
end

local function Tags(
    dataMap: DataMap
): DataMap
    return dataMap
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
    tag = Tag,
    tags = Tags,

    OnAdd = OnAdd,
    OnRemove = OnRemove,
    TagMarker = TagMarker,
    BuiltInPiece = BuiltInPiece
}