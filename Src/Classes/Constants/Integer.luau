local LuauSpec = require("@root/Luau/Spec")

--[=[
	@class Integer

	The Integer class is used to lift a constant type with the LBC_CONSTANT_INTEGER id (9)
]=]
local Integer = {}
Integer.__type = "Integer"
Integer.__constant_type = LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_INTEGER
Integer.__index = Integer

--[=[
	@within Integer

	The Integer class is used to lift a constant type with the LBC_CONSTANT_INTEGER id (9)

	@return Integer
]=]
function Integer.new(AnyFrickingNumber: number, IsNegative: boolean)
	local self = setmetatable({}, Integer)

    self.Value = if IsNegative then -AnyFrickingNumber else AnyFrickingNumber
    self.IsNegative = IsNegative

	return self
end

--[=[
	@within Integer

]=]
function Integer:__tostring()
    if self.Display then
        return self.Display
    end

    self.Display = `{self.Value}i`

    return self.Display
end

export type Integer = typeof(Integer.new(nil :: never, nil :: never))

return Integer
