export type Entity = number
export type None = string

export type usedAsEntity<D> = Entity | Piece<D>

export type Piece<D = unknown> = {
	data: D
}

local function Piece<D>(
    default: D?
): Piece<D>

    local self = { data = default :: D }
    
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
    New = Piece,
    from = from
}