local Package = script.Parent.Parent

local Types = require(Package.Common.Types)
type Entity = Types.Entity

local FACTOR = 2 ^ 26

local function PackPair(
    relation: Entity,
    target: Entity
): Entity

    return relation * FACTOR + target
end

local function UnpackPair(
    id: Entity
): (Entity, Entity)

    local relation = math.floor(id / FACTOR)
    local target = id % FACTOR

    return relation, target
end

return table.freeze {
    pack = PackPair,
    unpack = UnpackPair
}