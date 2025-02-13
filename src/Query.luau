local DefaultSettings = {
    priority = 0
}
export type QuerySettings<P...> = {
    query: () -> (P...),
    priority: number?
}

export type Query<P...> = typeof(setmetatable({} :: queryFields<P...>, {} :: queryImpl<P...>))

local Query = {}
Query.__index = Query

local JoinData;

function Query.New<P...>(
    settings: QuerySettings<P...>
): Query<P...>

    local mergedSettings = JoinData(DefaultSettings, settings)
    assert(mergedSettings.query, 'Missing query setting')

    local self = { traits = {}, settings = mergedSettings }

    return setmetatable(self, Query)
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

type Trait<P...> = (P...) -> ()

type queryFields<P...> = {
    traits: { [string]: Trait<P...> },
    settings: QuerySettings<P...>
}

type queryImpl<P...> = {
    __index: queryImpl<P...>,
    New: (settings: QuerySettings<P...>) -> (Query<P...>),
    trait: (self: Query<P...>, name: string, trait: (P...) -> ()) -> (Query<P...>)
}

return table.freeze(Query)