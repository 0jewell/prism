local DefaultSettings = {
    priority = 0
}
export type QuerySettings<P...> = {
    query: () -> (P...),
    priority: number?
}

export type Query<P...> = typeof(setmetatable({} :: queryFields<P...>, {} :: queryImpl<P...>))

local Query = {}
local JoinData;

function Query.New<P...>(
    settings: QuerySettings<P...>
): Query<P...>

    local mergedSettings = JoinData(DefaultSettings, settings)

    local self = { traits = {}, settings = mergedSettings }
    local metatable = { __index = Query }

    function metatable.__newindex(
        self: Query<P...>,
        i: string,
        v: Trait<P...>
    )
        assert(typeof(i) == 'string', 'Traits names must be strings')
        assert(typeof(v) == 'function', 'Traits values must be functions')

        self.traits[i] = v
    end

    return setmetatable(self, metatable)
end

function Query.trait<P...>(
    self: Query<P...>,
    name: string,
    trait: (P...) -> ()
): Query<P...>

    local traits = self.traits

    if traits[name] then
        error('Traits names must not be repeated')
    end

    traits[name] = trait
    return self
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
    traits: { [string]: Trait<P...> },
    settings: QuerySettings<P...>,
    [string]: (P...) -> ()
}

type queryImpl<P...> = {
    __index: {
        trait: <P...>(self: Query<P...>, name: string, trait: (P...) -> ()) -> (Query<P...>),
        New: <P...>(settings: QuerySettings<P...>) -> (Query<P...>)
    },
    __newindex: (self: Query<P...>, i: string, v: Trait<P...>) -> ()
}

return table.freeze(Query)