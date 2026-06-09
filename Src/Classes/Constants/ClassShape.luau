local LuauSpec = require("@root/Luau/Spec")

--[=[
	@class ClassShape

	The ClassShape class is used to lift a constant type with the
	LBC_CONSTANT_CLASS_SHAPE id (10), added in bytecode version 10.

	It describes a user-defined `class` declaration: the class name plus the
	names of its properties and methods. ClassName/Properties/Methods are
	resolved from the proto's own constant table (each is a String constant).
]=]
local ClassShape = {}
ClassShape.__type = "ClassShape"
ClassShape.__constant_type = LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_CLASS_SHAPE
ClassShape.__index = ClassShape

--[=[
	@within ClassShape

	The ClassShape class is used to lift a constant type with the
	LBC_CONSTANT_CLASS_SHAPE id (10)

	@param ClassName The class name (a String constant)
	@param Properties The property names (String constants)
	@param Methods The method names (String constants)
	@return ClassShape
]=]
function ClassShape.new(ClassName: any, Properties: { any }, Methods: { any })
	local self = setmetatable({}, ClassShape)

    self.ClassName = ClassName
    self.Properties = Properties
    self.Methods = Methods

	return self
end

--[=[
	@within ClassShape

]=]
function ClassShape:__tostring()
    if self.Display then
        return self.Display
    end

    self.Display = `class {self.ClassName}`

    return self.Display
end

export type ClassShape = typeof(ClassShape.new(nil :: never, nil :: never, nil :: never))

return ClassShape
