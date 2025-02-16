local Packages = game.ReplicatedStorage.Packages

local Iris = require(Packages.Iris)
local Prism = require(Packages.Prism)

local function Story(props)

    local piece = Prism.Piece()
    local query = Prism.Query { query = function() return piece end }

    local settings = query.settings
    local pieces = { settings.query() }

    Iris:Connect(function()
        
        Iris.Window {`Query {tostring(query)}`}
            Iris.MenuBar()
                Iris.Text {'Available settings:'}
            Iris.End()

            Iris.Text {`Priority: {settings.priority}`}

            Iris.Separator()

            Iris.Text {'Querying data:'}

            Iris.CollapsingHeader {'Show'}
                Iris.Text {'Total pieces:' .. #pieces}

                Iris.Tree {'Pieces'}
                    local pieces = {}
                    for i, piece in { settings.query() } do
                        table.insert(pieces, i)
                    end
                    Iris.Text { table.concat(pieces, ', ')}
                Iris.End()

            Iris.End()
        Iris.End()
    end)
end

return {
    iris = Iris,
    story = Story
}