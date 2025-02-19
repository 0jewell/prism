local Package = script.Parent
local Types = require(Package.Common.Types)

local DefaultSettings = {
    priority = 0
}
type QuerySettings<P...> = Types.QuerySettings<P...>

type Trait<P...> = Types.Trait<P...>
type TraitRecord<P...> = Types.TraitRecord<P...>

type Data = Types.Data

type Query<P... = ...any> = Types.Query<P...>

local JoinData;

local Query = {}
Query.__index = Query

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
    trait: (Data, P...) -> ()
): Query<P...>

    local record = {
        trait = trait,
        name = name
    }

    table.insert(self.traits, record)
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

return table.freeze(Query)