local LuauSpec = require(script.Parent.Parent.Parent.Luau.Spec)

--[=[
	@class String

	The String class is used to lift a constant type with the LBC_CONSTANT_STRING id (3)
]=]
local String = {}
String.__constant_type = LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_STRING
String.__index = String

--[=[
	@within String

	The String class is used to lift a constant type with the LBC_CONSTANT_STRING id (3)

	@return String
]=]
function String.new(Value: string)
	local self = setmetatable({}, String)
	self.ClassName = "String"
    
    self.Value = Value

	return self
end

--[=[
	@within String

]=]
function String:__tostring()
    return `"{self.Value}"`
end

export type String = typeof(String.new(nil :: never))

return String