local LuauSpec = require(script.Parent.Parent.Parent.Luau.Spec)

--[=[
	@class Vector

	The Vector class is used to lift a constant type with the LBC_CONSTANT_VECTOR id (7)
]=]
local Vector = {}
Vector.__constant_type = LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_VECTOR
Vector.__index = Vector

--[=[
	@within Vector

	The Vector class is used to lift a constant type with the LBC_CONSTANT_VECTOR id (7)

	@return Vector
]=]
function Vector.new(X: number, Y: number, Z: number, W: number)
	local self = setmetatable({}, Vector)
	self.ClassName = "Vector"
    
    self.X = X
    self.Y = Y
    self.Z = Z
    self.W = W

	return self
end

--[=[
	@within Vector

]=]
function Vector:__tostring()
    return `Vector({self.x}, {self.y}, {self.z}, {self.w})`

end

export type Vector = typeof(Vector.new(nil :: never))

return Vector