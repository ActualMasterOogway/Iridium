--[=[
	@class Hexadecimal

	The Hexadecimal class is used to represent an integer as a Hexadecimal
]=]
local Hexadecimal = {}
Hexadecimal.__type = "Hexadecimal"
Hexadecimal.__index = Hexadecimal

--[=[
	@within Hexadecimal

	The Hexadecimal class is used to represent an integer as a Hexadecimal

	@return Hexadecimal
]=]
function Hexadecimal.new(Number: number): Hexadecimal
	local self = setmetatable({}, Hexadecimal)
    
    self.Value = Number

	return self
end

--[=[
	@within Hexadecimal

]=]
function Hexadecimal:__tostring()
    if self.Display then
        return self.Display
    end

    self.Display = ("0x%X"):format(self.Value)

    return self.Display
end

export type Hexadecimal = typeof(Hexadecimal.new(nil :: never))

return Hexadecimal