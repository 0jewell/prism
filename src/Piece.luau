export type Entity = number
type None = 'none' | string

export type Piece<D = nil> = {
	id: None | Entity,
	type: D
}

local Piece = {}

--[[
    * pieces default data are set on entities when performing world:add
    * example:
    local Map = Prism.Piece(Assets.Maps.Testing)
    world:add(GlobalGameData, Map)

    world.data = {
            [1] = {
                * the model setted on default data
                [2] = Testing
            }
        }
]]
function Piece.New<D>(
    default: D
): Piece<D>

    local self = { type = default, id = 'none' }

    return self
end

type Figure<D = nil> = { data: D }
type FigureBuilder<D = nil> = { New: (data: D) -> Figure<D> }

local function from<D>(
    state: FigureBuilder<D>,
    default: D
): () -> Figure<D>

    return function()
        return state.New(default)
    end
end

return table.freeze {
    New = Piece.New,
    from = from
}