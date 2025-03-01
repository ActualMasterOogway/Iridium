local LuauSpec = require(script.Parent.Parent.Parent.Luau.Spec)
local String = require(script.Parent.String)

--[=[
	@class Import

	The Import class is used to lift a constant type with the LBC_CONSTANT_IMPORT id (4)
]=]
local Import = {}
Import.__constant_type = LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_IMPORT
Import.__index = Import

--[=[
	@within Import

	The Import class is used to lift a constant type with the LBC_CONSTANT_IMPORT id (4)

	@return Import
]=]
function Import.new(Imports: { String.String })
	local self = setmetatable({}, Import)
	self.ClassName = "Import"
    
    self.Value = Imports

	return self
end

--[=[
	@within Import

]=]
function Import:__tostring()
    local result: { string } = {}

    for i, Constant in self.Value do
        table.insert(result, tostring(Constant.Value))
    end

    return table.concat(result, ".")

end

export type Import = typeof(Import.new(nil :: never))

return Import