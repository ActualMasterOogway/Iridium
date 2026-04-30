local LuauSpec = require("@root/Luau/Spec")

--[=[
	@class Number

	The Number class is used to lift a constant type with the LBC_CONSTANT_NUMBER id (2)
]=]
local Number = {}
Number.__type = "Number"
Number.__constant_type = LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_NUMBER
Number.__index = Number

--[=[
	@within Number

	The Number class is used to lift a constant type with the LBC_CONSTANT_NUMBER id (2)

	@return Number
]=]
function Number.new(NumericalValue: number)
	local self = setmetatable({}, Number)
    
    self.Value = NumericalValue

	return self
end

--[=[
	@within Number

]=]
function Number:__tostring()
    if self.Display then
        return self.Display
    end

    self.Display = tostring(self.Value)

    return self.Display
end

export type Number = typeof(Number.new(nil :: never))

return Number