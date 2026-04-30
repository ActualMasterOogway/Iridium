local LuauSpec = require("@root/Luau/Spec")

--[=[
	@class Boolean

	The Boolean class is used to lift a constant type with the LBC_CONSTANT_BOOLEAN id (1)
]=]
local Boolean = {}
Boolean.__type = "Boolean"
Boolean.__constant_type = LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_BOOLEAN
Boolean.__index = Boolean

local True = setmetatable({ Value = true }, Boolean)
local False = setmetatable({ Value = false }, Boolean)
table.freeze(True)
table.freeze(False)

--[=[
	@within Boolean

	The Boolean class is used to lift a constant type with the LBC_CONSTANT_BOOLEAN id (1)

	@return Boolean
]=]
function Boolean.new(State: boolean)
	return if State then True else False
end

--[=[
	@within Boolean

]=]
function Boolean:__tostring()
    return self.Value == true and "true" or "false"
end

export type Boolean = typeof(Boolean.new(nil :: never))

return Boolean