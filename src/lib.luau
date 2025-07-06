local world = require('./world')
export type world = world.mock_world
export type entity<T = any> = world.entity<T>
export type component<T> = world.component<T, entity>

export type archetype = world.archetype<entity>
export type record = world.record<entity>

local debugger = require('./debug/trace')
export type stackframe = debugger.stackframe

return {
    world = world,
    debugger = debugger
}