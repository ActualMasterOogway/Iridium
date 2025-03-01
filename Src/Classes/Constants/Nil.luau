local LuauSpec = require(script.Parent.Parent.Parent.Luau.Spec)

--[=[
	@class Nil

	The Nil class is used to lift a constant type with the LBC_CONSTANT_NIL id (0)
]=]
local Nil = {}
Nil.__constant_type = LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_NIL
Nil.__index = Nil

--[=[
	@within Nil

	The Nil class is used to lift a constant type with the LBC_CONSTANT_NIL id (0)

	@return Nil
]=]
function Nil.new()
	local self = setmetatable({}, Nil)
	self.ClassName = "Nil"
    
    self.Value = nil

	return self
end

--[=[
	@within Nil

]=]
function Nil:__tostring()
    return "nil"
end

export type Nil = typeof(Nil.new())

return Nil