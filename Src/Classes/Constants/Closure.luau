local LuauSpec = require(script.Parent.Parent.Parent.Luau.Spec)

--[=[
	@class Closure

	The Closure class is used to lift a constant type with the LBC_CONSTANT_CLOSURE id (6)
]=]
local Closure = {}
Closure.__constant_type = LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_CLOSURE
Closure.__index = Closure

--[=[
	@within Closure

	The Closure class is used to lift a constant type with the LBC_CONSTANT_CLOSURE id (6)

	@return Closure
]=]
function Closure.new(Index: number)
	local self = setmetatable({}, Closure)
	self.ClassName = "Closure"
    
    self.Value = Index

	return self
end

--[=[
	@within Closure

]=]
function Closure:__tostring()
    return `closure({self.Value})`
end

export type Closure = typeof(Closure.new(nil :: never))

return Closure