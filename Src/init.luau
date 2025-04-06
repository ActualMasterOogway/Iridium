local Buffer = require(script.Utilities.Buffer)

local LuauSpec = require(script.Luau.Spec)

local Proto = require(script.Classes.Proto)

local Iridium = {
    LuauSpec = LuauSpec
}

--[=[
	@class Deserializer

	The Deserializer class is used for deserializing Luau Bytecode from versions ranging between 3 and 6
]=]
local Deserializer = {}
Deserializer.__index = Deserializer

--[=[
	@within Deserializer

	The Deserializer class is used for deserializing Luau Bytecode from versions ranging between 3 and 6

	@param Bytecode Buffer.BufferReader
	@return Deserializer
]=]
function Deserializer.new(Bytecode: Buffer.BufferReader): Deserializer
	local self = setmetatable({}, Deserializer)
	self.ClassName = "Deserializer"
    self.Source = Bytecode

    -- Versions

    self.BytecodeVersion = Bytecode:readu8() :: number

    if self.BytecodeVersion == 0 then
        error(Bytecode:readstring(Bytecode.LastUnreadBytes))
    end

    if self.BytecodeVersion < LuauSpec.LuauBytecodeTag.LBC_VERSION_MIN or self.BytecodeVersion > LuauSpec.LuauBytecodeTag.LBC_VERSION_MAX then
        error(`Invalid bytecode version (expected {LuauSpec.LuauBytecodeTag.LBC_VERSION_MIN}-{LuauSpec.LuauBytecodeTag.LBC_VERSION_MAX}, got {self.BytecodeVersion})`)
    end

    self.IsTyped = self.BytecodeVersion >= 4

    if self.IsTyped then
        self.TypesVersion = Bytecode:readu8() :: number

        if self.TypesVersion < LuauSpec.LuauBytecodeTag.LBC_TYPE_VERSION_MIN or self.TypesVersion > LuauSpec.LuauBytecodeTag.LBC_TYPE_VERSION_MAX then
            error(`Invalid bytecode type version (expected {LuauSpec.LuauBytecodeTag.LBC_TYPE_VERSION_MIN}-{LuauSpec.LuauBytecodeTag.LBC_TYPE_VERSION_MAX}, got {self.BytecodeVersion})`)
        end
    end

    -- Strings

    self.StringCount = Bytecode:ReadVarInt() :: number
    self.Strings = table.create(self.StringCount) :: { string }

    for i = 1, self.StringCount do
        self.Strings[i] = Bytecode:ReadString()
    end

    -- Userdata

    self.UserdataTypeLimit = LuauSpec.LuauBytecodeType.LBC_TYPE_TAGGED_USERDATA_END - LuauSpec.LuauBytecodeType.LBC_TYPE_TAGGED_USERDATA_BASE
    self.UserdataRemapping = table.create(self.UserdataTypeLimit, LuauSpec.LuauBytecodeType.LBC_TYPE_USERDATA)

    if self.TypesVersion == 3 then
        local Index = Bytecode:readu8()

        while Index ~= 0 do
            local Name = self:ReadStringRef() :: string
            
            if Index <= self.UserdataTypeLimit then
                self.UserdataRemapping[Index] = self:GetTypeMapping(Name, #Name)
            end
            
            Index = Bytecode:readu8()
        end
    end

    -- Protos (Functions)

    self.ProtoCount = Bytecode:ReadVarInt()
    self.Protos = table.create(self.ProtoCount)

    for i = 1, self.ProtoCount do
        self.Protos[i] = Proto.new(Bytecode, self)
    end

    self.ProtoEntryPoint = Bytecode:ReadVarInt() + 1

    self.Protos[self.ProtoEntryPoint].Main = true

    self.FunctionCount, self.Functions, self.FunctionEntryPoint = self.ProtoCount, self.Protos, self.ProtoEntryPoint

    if Bytecode.LastUnreadBytes ~= 0 then
        warn(`Bytecode was not parsed properly ({Bytecode.Offset}/{Bytecode.Length})`)
    end

	return self
end

--[=[
	@within Deserializer

    Reads a string based off of its index

	@return string
]=]
function Deserializer:ReadStringRef()
    local Index = self.Source:ReadVarInt()

    return if Index ~= 0 then self.Strings[Index] else nil
end

--[=[
	@within Deserializer

    Gets the mapping of the provided type

	@return string
]=]
function Deserializer:GetTypeMapping(Name: string, Length: number) -- TODO: Actually implement this
    --? https://github.com/luau-lang/luau/blob/master/CodeGen/src/CodeGenContext.cpp#L694
    return bit32.band(string.byte(Name) - Length, 0xFF)
end

export type Deserializer = typeof(Deserializer.new(nil :: never))

function Iridium:Deserialize(Bytecode: string | buffer | Buffer.BufferReader)
    local ByteCode: Buffer.BufferReader = Buffer.new(if typeof(Bytecode) == "buffer" or Buffer.IsBufferReader(Bytecode) then Bytecode else buffer.fromstring(Bytecode :: string))

    return Deserializer.new(ByteCode)
end

return Iridium