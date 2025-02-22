local Packages = game.ReplicatedStorage.Packages

local Iris = require(Packages.Iris)

local Fusion = require(Packages.Fusion)
local Value = Fusion.Value

local Prism = require(Packages.Prism)
type Entity = Prism.Entity
type EntityData = Prism.EntityData

local function get_registry_pieces_map(storage)
    local pieces, dataMap = {}, {}

    for entity, entityStorage in storage do
        for piece, data in entityStorage do
            pieces[piece] = true
            dataMap[piece] = dataMap[piece] or {}
            dataMap[piece][entity] = data
        end
    end

    return pieces, dataMap
end

local function table_to_text(table, indentLevel)
    local indent = string.rep('  ', indentLevel)
    local startTextData = '{\n'

    for index, value in pairs(table) do
        local text
        local formattedIndex = '' .. tostring(index) .. ''

        if typeof(value) == 'table' then
            if value.scope then
                text = `Value<{tostring(value._EXTREMELY_DANGEROUS_usedAsValue)}>`
            else
                text = table_to_text(value, indentLevel + 1)
            end
        else
            text = tostring(value)
        end

        startTextData = startTextData
            .. indent .. '  ' .. formattedIndex .. ' = ' .. text .. '\n'
    end

    return startTextData .. indent .. '}'
end

local function Story(props)

    local registry = Prism.Registry()
    local entity = registry:entity()

    local health = Prism.Piece {
        max = 100,
        current = Prism.from(Value, {}, 100)
    }
    local damage = Prism.Piece {
        quantity = 10,
        doubledDamage = false
    }
    registry:add(entity, health)
    registry:add(entity, damage)

    for i = 1, 10 do
        local e = registry:entity()
        registry:add(e, health)
        registry:add(e, damage)
    end

    Iris:Connect(function()

        Iris.Window {'Registry inspect'}
            local pieces, dataMap = get_registry_pieces_map(registry.storage)
            local selectedPiece = Iris.State(2)

            Iris.SameLine()
                Iris.Text {`Size: {registry.size}`}

                local sharedIndex = Iris.State('No selected')

                Iris.Combo({'Piece'}, { index = sharedIndex })
                    for piece in pieces do
                        local name = `Piece {piece}`
                        local test = Iris.Selectable({name, name}, { index = sharedIndex })

                        if test.clicked() then
                            selectedPiece:set(piece)
                        end
                    end
                Iris.End()
            Iris.End()

            Iris.SeparatorText {`Vizualizing components data`}

            if selectedPiece:get() ~= 0 then                   
                local datas = dataMap[selectedPiece:get()]

                Iris.SameLine()
                    Iris.TextColored { 'Entity id', Iris._config.HeaderActiveColor }
                    Iris.Separator()
                    Iris.TextColored { 'Data', Iris._config.HeaderActiveColor }
                Iris.End()

                for entity, entityData in datas do
                    Iris.SameLine()
                        Iris.Group()
                            Iris.Text { entity }
                            Iris.Text{'         '}
                        Iris.End()

                        Iris.Separator()

                        Iris.Group()
                            Iris.Tree {'...'}
                                local data = entityData.data

                                local text = if typeof(data) == 'table'
                                then table_to_text(data, 0)
                                else tostring(data)

                                Iris.Text { text }
                            Iris.End()
                        Iris.End()

                    Iris.End()
                end
            end
        Iris.End()
    end)
end

return {
    iris = Iris,
    story = Story
}