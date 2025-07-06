local world = require(script.world)
export type world = world.mock_world
export type entity<T = any> = world.entity<T>
export type component<T> = world.component<T, entity>

export type archetype = world.archetype<entity>
export type record = world.record<entity>

return {
    world = world
}