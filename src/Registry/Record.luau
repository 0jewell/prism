local Package = script.Parent.Parent

local Types = require(Package.Types)
type Record = Types.Record
type Bitmap = Types.Bitmap

local function GenerateRecord(
    entity: Types.Entity
): Record

    local word = math.floor((entity - 1) / 64) + 1

    local bitPosition = (entity - 1) % 64
    local mask = bit32.lshift(1, bitPosition)

    local record = {
        word = word,
        mask = mask,
        bitmap = {}
    }

    return record
end

local function AppendRecord(
    map: Bitmap,
    record: Record
)
    map[record.word] = bit32.bor(map[record.word] or 0, record.mask)
end

local function UnappendRecord(
    map: Bitmap,
    record: Record
)
    map[record.word] = bit32.band(map[record.word] or 0, bit32.bnot(record.mask))

    if map[record.word] == 0 then
        map[record.word] = nil
    end
end

local function MapContainsRecord(
    map: Record,
    record: Record
)
    local bitmap = map.bitmap
    return bit32.band(bitmap[record.word] or 0, record.mask) == record.mask
end

local function CompareMapsEntries(
    target: Bitmap,
    query: Bitmap
): boolean

    for word, bits in query do
        if bit32.band(target[word] or 0, bits) ~= bits then
            return false
        end
    end

    return true
end

return table.freeze {
    generate = GenerateRecord,
    append = AppendRecord,
    unappend = UnappendRecord,
    compare = CompareMapsEntries,
    contains = MapContainsRecord
}