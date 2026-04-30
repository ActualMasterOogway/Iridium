local LuauSpec = require("@root/Luau/Spec")
local String = require("@root/Classes/Constants/String")

--[=[
	@class Import

	The Import class is used to lift a constant type with the LBC_CONSTANT_IMPORT id (4)
]=]
local Import = {}
Import.__type = "Import"
Import.__constant_type = LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_IMPORT
Import.__index = Import

--[=[
	@within Import

	The Import class is used to lift a constant type with the LBC_CONSTANT_IMPORT id (4)

	@return Import
]=]
function Import.new(Imports: { String.String })
	local self = setmetatable({}, Import)
    
    self.Value = Imports

	return self
end

--[=[
	@within Import

]=]
function Import:__tostring()
    if self.Display then
        return self.Display
    end

    local Count = #self.Value
    local Total = if Count > 0 then Count - 1 else 0

    for _, Constant in self.Value do
        Total += buffer.len(Constant.Value)
    end

    local Output = buffer.create(Total)
    local Offset = 0

    for Index, Constant in self.Value do
        if Index > 1 then
            buffer.writeu8(Output, Offset, 46)
            Offset += 1
        end

        local Length = buffer.len(Constant.Value)

        buffer.copy(Output, Offset, Constant.Value)
        Offset += Length
    end

    self.Display = buffer.tostring(Output)

    return self.Display
end

export type Import = typeof(Import.new(nil :: never))

return Import