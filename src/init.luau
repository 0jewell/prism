local Query = require(script.Query)
export type Query<P...> = Query.Query<P...>

return table.freeze {
    Query = Query.New
}