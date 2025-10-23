-- types
local types = require('@self/types')
export type world = types.mock_world
export type entity<T = any> = types.entity<T>
export type archetype = types.archetype
export type trait = types.trait<entity>

return {
    -- ecs
    world = require('@self/world'),
    archetype = require('@self/archetype'),

    -- scope
    clean = require('@self/clean')
}