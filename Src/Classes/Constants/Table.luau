local LuauSpec = require(script.Parent.Parent.Parent.Luau.Spec)

--[=[
	@class Table

	The Table class is used to lift a constant type with the LBC_CONSTANT_TABLE id (5)
]=]
local Table = {}
Table.__constant_type = LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_TABLE
Table.__index = Table

--[=[
	@within Table

	The Table class is used to lift a constant type with the LBC_CONSTANT_TABLE id (5)

	@return Table
]=]
function Table.new(Value: { any })
	local self = setmetatable({}, Table)
	self.ClassName = "Table"
    
    self.Value = Value

	return self
end

--[=[
	@within Table

]=]
function Table:__tostring()
    return `\{ {table.concat(self.Value, ", ")} \}`

end

export type Table = typeof(Table.new(nil :: never))

return Table