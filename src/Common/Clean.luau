--!nolint LocalShadow
local Package = script.Parent
local Types = require(Package.Types)

type Cleaning = Types.Cleaning

local function Clean(
    clean: Cleaning
)
    if typeof(clean) == 'function' then
        clean()

    elseif typeof(clean) == 'thread' then
        task.cancel(clean)

    elseif typeof(clean) == 'Instance' then
        clean:Destroy()

    elseif typeof(clean) == 'RBXScriptConnection' then
        clean:Disconnect()

    elseif typeof(clean) == 'table' then

        local clean = (clean :: any) :: {Destroy: (...unknown) -> (...unknown)?, destroy: (...unknown) -> (...unknown)?}
        
        if typeof(clean.Destroy) == 'function' then
            local clean = (clean :: any) :: {Destroy: (...unknown) -> (...unknown)}
            clean:Destroy()
        
        elseif typeof(clean.destroy) == 'function' then
            local clean = (clean :: any) :: {destroy: (...unknown) -> (...unknown)}
            clean:destroy()

        elseif clean[1] ~= nil then
            local clean = clean :: { Cleaning }

            for _, Cleaning in clean do
                Clean(clean)
            end
        end

        table.clear(clean)
    end
end

return Clean