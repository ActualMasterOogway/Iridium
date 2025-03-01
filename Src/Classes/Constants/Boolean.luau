local LuauSpec = require(script.Parent.Parent.Parent.Luau.Spec)

--[=[
	@class Boolean

	The Boolean class is used to lift a constant type with the LBC_CONSTANT_BOOLEAN id (1)
]=]
local Boolean = {}
Boolean.__constant_type = LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_BOOLEAN
Boolean.__index = Boolean

--[=[
	@within Boolean

	The Boolean class is used to lift a constant type with the LBC_CONSTANT_BOOLEAN id (1)

	@return Boolean
]=]
function Boolean.new(State: boolean)
	local self = setmetatable({}, Boolean)
	self.ClassName = "Boolean"
    
    self.Value = State

	return self
end

--[=[
	@within Boolean

]=]
function Boolean:__tostring()
    return self.Value == true and "true" or "false"
end

export type Boolean = typeof(Boolean.new(nil :: never))

return Boolean