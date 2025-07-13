local world = require('@self/world')
export type world = world.mock_world
export type entity<T = any> = world.entity<T>

export type archetype = world.archetype<entity>
export type record = world.record<entity>

local debugger = require('@self/debug/trace')
export type stackframe = debugger.stackframe

return {
    world = world,
    debugger = debugger
}