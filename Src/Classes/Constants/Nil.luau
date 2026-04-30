local LuauSpec = require("@root/Luau/Spec")

--[=[
	@class Nil

	The Nil class is used to lift a constant type with the LBC_CONSTANT_NIL id (0)
]=]
local Nil = {}
Nil.__type = "Nil"
Nil.__constant_type = LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_NIL
Nil.__index = Nil

local Singleton = setmetatable({}, Nil)
table.freeze(Singleton)

--[=[
	@within Nil

	The Nil class is used to lift a constant type with the LBC_CONSTANT_NIL id (0)

	@return Nil
]=]
function Nil.new()
	return Singleton
end

--[=[
	@within Nil

]=]
function Nil:__tostring()
    return "nil"
end

export type Nil = typeof(Nil.new())

return Nil