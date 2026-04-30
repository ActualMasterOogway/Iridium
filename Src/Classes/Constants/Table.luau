local LuauSpec = require("@root/Luau/Spec")

--[=[
	@class Table

	The Table class is used to lift a constant type with the LBC_CONSTANT_TABLE id (5)
]=]
local Table = {}
Table.__type = "Table"
Table.__constant_type = LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_TABLE
Table.__index = Table

--[=[
	@within Table

	The Table class is used to lift a constant type with the LBC_CONSTANT_TABLE id (5)

	@return Table
]=]
function Table.new(Value: { any })
	local self = setmetatable({}, Table)
    
    self.Value = Value

	return self
end

--[=[
	@within Table

]=]
function Table:__tostring()
    if self.Display then
        return self.Display
    end

    local Count = #self.Value
    local Stringified: { string } = table.create(Count)
    local Total = 4 + (if Count > 1 then 2 * (Count - 1) else 0)

    for Index, Constant in self.Value do
        local Item = tostring(Constant)
        Stringified[Index] = Item
        Total += #Item
    end

    local Output = buffer.create(Total)

    buffer.writeu8(Output, 0, 123)
    buffer.writeu8(Output, 1, 32)

    local Offset = 2

    for Index, Item in Stringified do
        if Index > 1 then
            buffer.writeu8(Output, Offset, 44)
            buffer.writeu8(Output, Offset + 1, 32)
            Offset += 2
        end

        buffer.writestring(Output, Offset, Item)
        Offset += #Item
    end

    buffer.writeu8(Output, Offset, 32)
    buffer.writeu8(Output, Offset + 1, 125)

    self.Display = buffer.tostring(Output)

    return self.Display
end

export type Table = typeof(Table.new(nil :: never))

return Table