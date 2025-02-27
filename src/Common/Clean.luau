--!nolint LocalShadow
--// from: https://github.com/dphfox/Fusion/blob/main/src/Memory/doCleanup.luau

local Package = script.Parent

local Types = require(Package.Types)
type Cleaning = Types.Cleaning

local alreadyDestroying: { [Cleaning]: true } = {}

local function Clean(cleaning: Cleaning): ()
	
	if alreadyDestroying[cleaning] then
		return error('Destroying twice')
	end
	alreadyDestroying[cleaning] = true

	-- case 1: Instance
	if typeof(cleaning) == "Instance" then
		cleaning:Destroy()

	-- case 2: RBXScriptConnection
	elseif typeof(cleaning) == "RBXScriptConnection" then
		cleaning:Disconnect()

	-- case 3: Callback
	elseif typeof(cleaning) == "function" then
		cleaning()

	-- case 4: Thread
	elseif typeof(cleaning) == 'thread' then
		task.cancel(cleaning)

	elseif typeof(cleaning) == "table" then
		local cleaning = (cleaning :: any) :: {Destroy: (...unknown) -> (...unknown)?, destroy: (...unknown) -> (...unknown)?}

		-- case 5: destroy() function
		if typeof(cleaning.destroy) == "function" then
			local cleaning = (cleaning :: any) :: {destroy: (...unknown) -> (...unknown)}
			cleaning:destroy()

		-- case 6: Destroy() function
		elseif typeof(cleaning.Destroy) == "function" then
			local cleaning = (cleaning :: any) :: {Destroy: (...unknown) -> (...unknown)}
			cleaning:Destroy()

		-- case 7: table of cleanings with an array part
		elseif cleaning[1] ~= nil then
			local cleaning = cleaning :: { Cleaning }

			-- It is important to iterate backwards through the table, since
			-- objects are added in order of construction.
			for index = #cleaning, 1, -1 do
				Clean(cleaning[index])
				cleaning[index] = nil
			end
		end
	end
	
	alreadyDestroying[cleaning] = nil
end

return Clean