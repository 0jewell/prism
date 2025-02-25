local function MergeData<config, target>(
    config: config,
    target: target
): config & target

    assert(type(target) == 'table', 'Target must be a table.')
    assert(type(config) == 'table', 'Config  must be a table.')

    for index, default in pairs(config) do

        if not target[index] then
            target[index] = default
        end

        if typeof(config[index]) == 'table' then
            target[index] = MergeData(config[index], target[index])
        end
    end

    return target
end

local function Transform<target>(
    data: target
): target

    assert(typeof(data) == 'table', 'Data must be a table')

    for index, value in data do
        if typeof(value) == 'function' then
            data[index] = value()

        elseif typeof(value) == 'table' then
            Transform(value)

        end
    end

    return data
end

return table.freeze {
    merge = MergeData,
    transform = Transform
}