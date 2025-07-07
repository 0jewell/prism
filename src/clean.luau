--!nolint LocalShadow

-- types

-- storage for temporary data passed to traits
export type scope = { unknown }

local function clean(
	scope: scope
)
    for index = #scope, 1, -1 do
        local task = scope[index]

        -- case 1: callback
        if typeof(task) == 'function' then
            local task = task :: () -> ()
            task()

        -- case 2: Instance
        elseif typeof(task) == 'Instance' then
            task:Destroy()

        -- case 3: Signal
        elseif typeof(task) == "RBXScriptConnection" then
            task:Disconnect()

        elseif typeof(task) == 'table' then
            local task = (task :: any) :: {Destroy: (...unknown) -> (...unknown)?, destroy: (...unknown) -> (...unknown)?}

            -- case 4: custom object with "destroy"
            if typeof(task.destroy) == "function" then
                local task = (task :: any) :: {destroy: (...unknown) -> (...unknown)}
                task:destroy()

            -- case 5: custom object with "Destroy"
            elseif typeof(task.Destroy) == "function" then
                local task = (task :: any) :: {Destroy: (...unknown) -> (...unknown)}
                task:Destroy()
            
            -- case 6: another scope
            else
                clean(task)
            end
        end

        scope[index] = nil
    end
end

return clean