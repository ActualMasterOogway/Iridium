--[=[
	@class Hexadecimal

	The Hexadecimal class is used to represent an integer as a Hexadecimal
]=]
local Hexadecimal = {}
Hexadecimal.__index = Hexadecimal

--[=[
	@within Hexadecimal

	The Hexadecimal class is used to represent an integer as a Hexadecimal

	@return Hexadecimal
]=]
function Hexadecimal.new(Number: number): Hexadecimal
	local self = setmetatable({}, Hexadecimal)
	self.ClassName = "Hexadecimal"
    
    self.Value = Number

	return self
end

--[=[
	@within Hexadecimal

]=]
function Hexadecimal:__tostring()
    return ("0x%X"):format(self.Value)
end

export type Hexadecimal = typeof(Hexadecimal.new(nil :: never))

return Hexadecimal