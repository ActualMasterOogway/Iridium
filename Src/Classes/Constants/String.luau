local LuauSpec = require("@root/Luau/Spec")

--[=[
	@class String

	The String class is used to lift a constant type with the LBC_CONSTANT_STRING id (3)
]=]
local String = {}
String.__type = "String"
String.__constant_type = LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_STRING
String.__index = String

--[=[
	@within String

	The String class is used to lift a constant type with the LBC_CONSTANT_STRING id (3)

	@return String
]=]
function String.new(Value: string)
	local self = setmetatable({}, String)

    self.Value = buffer.fromstring(Value)

	return self
end

--[=[
	@within String

]=]
function String:__tostring()
    if self.Display then
        return self.Display
    end

    local Length = buffer.len(self.Value)
    local Output = buffer.create(Length + 2)

    buffer.writeu8(Output, 0, 34)
    buffer.copy(Output, 1, self.Value)
    buffer.writeu8(Output, Length + 1, 34)

    self.Display = buffer.tostring(Output)

    return self.Display
end

export type String = typeof(String.new(nil :: never))

return String
