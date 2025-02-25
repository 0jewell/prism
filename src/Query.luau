local Package = script.Parent
local Types = require(Package.Common.Types)

local Data = require(Package.Common.Data)

local DefaultSettings = {
    priority = 0
}
type QuerySettings<P...> = Types.QuerySettings<P...>

type Trait<P...> = Types.Trait<P...>
type TraitRecord<P...> = Types.TraitRecord<P...>

type Data = Types.Data

type Query<P... = ...any> = Types.Query<P...>

local Query = {}
Query.__index = Query

function Query.New<P...>(
    settings: QuerySettings<P...>
): Query<P...>

    local mergedSettings = Data.merge(DefaultSettings, settings)
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

return table.freeze(Query)