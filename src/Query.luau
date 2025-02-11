local DefaultSettings = {
    priority = 0
}
export type QuerySettings<P...> = {
    query: () -> (P...),
    priority: number?
}

export type Query<P...> = typeof(setmetatable({} :: queryFields<P...>, {} :: queryImpl))

local Query = {}
local JoinData;

function Query.New<P...>(
    settings: QuerySettings<P...>
): Query<P...>

    local mergedSettings = JoinData(DefaultSettings, settings)

    local self = { traits = {}, settings = mergedSettings }
    local metatable = {}

    function metatable:__newindex(i: string, v: Trait<...unknown>)
        assert(typeof(i) == 'string', 'Traits names must be strings')
        assert(typeof(v) == 'function', 'Traits values must be functions')

        self.traits[i] = v
    end

    return setmetatable(self, metatable)
end

function JoinData<config, target>(
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
            target[index] = JoinData(config[index], target[index])
        end
    end

    return target
end

type Trait<P...> = (P...) -> unknown

type queryFields<P...> = {
    traits: { Trait<unknown> },
    settings: QuerySettings<P...>,
    [string]: (P...) -> ()
}

type queryImpl = {
    __newindex: (self: never, i: string, v: Trait<...unknown>) -> ()
}

return table.freeze(Query)