local LuauSpec = require("@root/Luau/Spec")

--[=[
	@class TableWithConstants

	The TableWithConstants class is used to lift a constant type with the LBC_CONSTANT_TABLE_WITH_CONSTANTS id (8)
]=]
local TableWithConstants = {}
TableWithConstants.__type = "TableWithConstants"
TableWithConstants.__constant_type = LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_TABLE_WITH_CONSTANTS
TableWithConstants.__index = TableWithConstants

export type Pair = { Key: any, Value: any? }

--[=[
	@within TableWithConstants

	The TableWithConstants class is used to lift a constant type with the LBC_CONSTANT_TABLE_WITH_CONSTANTS id (8)

	@return TableWithConstants
]=]
function TableWithConstants.new(Value: { Pair })
	local self = setmetatable({}, TableWithConstants)

    self.Value = Value

	return self
end

--[=[
	@within TableWithConstants

]=]
function TableWithConstants:__tostring()
    if self.Display then
        return self.Display
    end

    local Count = #self.Value
    local Stringified: { string } = table.create(Count)
    local Total = 4 + (if Count > 1 then 2 * (Count - 1) else 0)

    for Index, Pair in self.Value do
        local Item = if Pair.Value ~= nil then `[{tostring(Pair.Key)}] = {tostring(Pair.Value)}` else `[{tostring(Pair.Key)}]`
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

export type TableWithConstants = typeof(TableWithConstants.new(nil :: never))

return TableWithConstants
