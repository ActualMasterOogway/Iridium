--[=[
	@class Upvalue

	The Upvalue class is used to lift a luau Upvalue
]=]
local Upvalue = {}
Upvalue.__type = "Upvalue"
Upvalue.__index = Upvalue

--[=[
	@within Upvalue

	The Upvalue class is used to lift a luau Upvalue

	@param Bytecode Buffer.BufferReader
	@return Upvalue
]=]
function Upvalue.new(Name: string): Upvalue
	local self = setmetatable({}, Upvalue)

    self.Name = Name

	return self
end

export type Upvalue = typeof(Upvalue.new(nil :: never))

return Upvalue