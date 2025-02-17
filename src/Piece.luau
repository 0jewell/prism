export type Piece<D = nil> = {
	data: D
}

local function Piece<D>(
    default: D?
): Piece<D>

    local self = { data = default :: D }
    
    return self
end

return table.freeze {
    New = Piece
}