local Package = script.Parent.Parent
local Types = require(Package.Common.Types)

type Record = Types.Record
type BitMap = Types.BitMap

local function GenerateRecord(
    entity: Types.Entity
): Record

    local wordIndex = math.floor((entity - 1) / 64) + 1

    local bitPosition = (entity - 1) % 64
    local mask = bit32.lshift(1, bitPosition)

    local record = { word = wordIndex, mask = mask }

    return record
end

local function AppendRecordToMap(
    map: Types.BitMap,
    record: Record
)
    map[record.word] = bit32.bor(map[record.word] or 0, record.mask)
end

local function UnappendRecordFromMap(
    map: BitMap,
    record: Record
)
    map[record.word] = bit32.band(map[record.word] or 0, bit32.bnot(record.mask))

    if map[record.word] == 0 then
        map[record.word] = nil
    end
end

return table.freeze {
    generate = GenerateRecord,
    append = AppendRecordToMap,
    unappend = UnappendRecordFromMap
}