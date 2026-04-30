local LuauSpec = require("@root/Luau/Spec")
local Buffer = require("@root/Utilities/Buffer")

--[=[
    Helpers for parsing the per-proto type-info section of Luau bytecode.

    For typesversion 1 the section is just the function signature.
    For typesversion 2 it adds typed upvalues and typed locals.
    For typesversion 3 it adds a deserializer-level userdata name table that
    maps tagged-userdata indices in the type bytes to their source names.

    The format is documented inline in upstream's
    `Bytecode/src/BytecodeBuilder.cpp` at `BytecodeBuilder::writeFunction`.
]=]

local OPTIONAL_BIT = LuauSpec.LuauBytecodeType.LBC_TYPE_OPTIONAL_BIT
local USERDATA_BASE = LuauSpec.LuauBytecodeType.LBC_TYPE_TAGGED_USERDATA_BASE
local USERDATA_END = LuauSpec.LuauBytecodeType.LBC_TYPE_TAGGED_USERDATA_END

local TypeNames = {
    [LuauSpec.LuauBytecodeType.LBC_TYPE_NIL] = "nil",
    [LuauSpec.LuauBytecodeType.LBC_TYPE_BOOLEAN] = "boolean",
    [LuauSpec.LuauBytecodeType.LBC_TYPE_NUMBER] = "number",
    [LuauSpec.LuauBytecodeType.LBC_TYPE_STRING] = "string",
    [LuauSpec.LuauBytecodeType.LBC_TYPE_TABLE] = "table",
    [LuauSpec.LuauBytecodeType.LBC_TYPE_FUNCTION] = "function",
    [LuauSpec.LuauBytecodeType.LBC_TYPE_THREAD] = "thread",
    [LuauSpec.LuauBytecodeType.LBC_TYPE_USERDATA] = "userdata",
    [LuauSpec.LuauBytecodeType.LBC_TYPE_VECTOR] = "vector",
    [LuauSpec.LuauBytecodeType.LBC_TYPE_BUFFER] = "buffer",
    [LuauSpec.LuauBytecodeType.LBC_TYPE_INTEGER] = "integer",
    [LuauSpec.LuauBytecodeType.LBC_TYPE_ANY] = "any",
}

export type ParsedType = {
    Byte: number,
    Tag: number,
    IsOptional: boolean,
    Name: string,
    UserdataName: string?,
}

export type ParsedLocal = {
    Byte: number,
    Tag: number,
    IsOptional: boolean,
    Name: string,
    UserdataName: string?,
    Register: number,
    StartPc: number,
    EndPc: number,
}

export type FunctionTypeInfo = {
    NumParams: number,
    ParameterTypes: { ParsedType },
}

local TypeInfo = {}

--[=[
    Resolves the human-readable name for a type byte. Tagged userdata bytes
    look up `UserdataNames[index]` (1-based, matching the wire format); if the
    bytecode is typesversion < 3 (no name table) or the index is unregistered,
    falls back to a synthetic `userdata#N` label.
]=]
function TypeInfo.GetTypeName(Byte: number, UserdataNames: { [number]: string }?): string
    local Tag = bit32.band(Byte, 0x7F)

    if Tag >= USERDATA_BASE and Tag < USERDATA_END then
        local Index = Tag - USERDATA_BASE + 1

        if UserdataNames and UserdataNames[Index] then
            return UserdataNames[Index]
        end

        return `userdata#{Tag - USERDATA_BASE}`
    end

    return TypeNames[Tag] or `unknown(0x{string.format("%02X", Tag)})`
end

function TypeInfo.ParseType(Byte: number, UserdataNames: { [number]: string }?): ParsedType
    local Tag = bit32.band(Byte, 0x7F)
    local UserdataName: string? = nil

    if UserdataNames and Tag >= USERDATA_BASE and Tag < USERDATA_END then
        UserdataName = UserdataNames[Tag - USERDATA_BASE + 1]
    end

    return {
        Byte = Byte,
        Tag = Tag,
        IsOptional = bit32.band(Byte, OPTIONAL_BIT) ~= 0,
        Name = TypeInfo.GetTypeName(Byte, UserdataNames),
        UserdataName = UserdataName,
    }
end

--[=[
    Parses the function-signature byte string: `[LBC_TYPE_FUNCTION][numparams][param-types...]`.
]=]
function TypeInfo.ParseFunctionSignature(Bytes: Buffer.BufferReader, UserdataNames: { [number]: string }?): FunctionTypeInfo
    Bytes:readu8()

    local NumParams = Bytes:readu8()
    local ParameterTypes = table.create(NumParams)

    for Index = 1, NumParams do
        ParameterTypes[Index] = TypeInfo.ParseType(Bytes:readu8(), UserdataNames)
    end

    return {
        NumParams = NumParams,
        ParameterTypes = ParameterTypes,
    }
end

--[=[
    Parses `Count` consecutive 1-byte upvalue type tags.
]=]
function TypeInfo.ParseUpvalueTypes(Bytes: Buffer.BufferReader, Count: number, UserdataNames: { [number]: string }?): { ParsedType }
    local Result = table.create(Count)

    for Index = 1, Count do
        Result[Index] = TypeInfo.ParseType(Bytes:readu8(), UserdataNames)
    end

    return Result
end

--[=[
    Parses `Count` typed-local entries: `[type][reg][startpc varint][(endpc - startpc) varint]`.
]=]
function TypeInfo.ParseLocalTypes(Bytes: Buffer.BufferReader, Count: number, UserdataNames: { [number]: string }?): { ParsedLocal }
    local Result = table.create(Count)

    for Index = 1, Count do
        local Byte = Bytes:readu8()
        local Register = Bytes:readu8()
        local StartPc = Bytes:ReadVarInt()
        local Span = Bytes:ReadVarInt()

        local Tag = bit32.band(Byte, 0x7F)
        local UserdataName: string? = nil

        if UserdataNames and Tag >= USERDATA_BASE and Tag < USERDATA_END then
            UserdataName = UserdataNames[Tag - USERDATA_BASE + 1]
        end

        Result[Index] = {
            Byte = Byte,
            Tag = Tag,
            IsOptional = bit32.band(Byte, OPTIONAL_BIT) ~= 0,
            Name = TypeInfo.GetTypeName(Byte, UserdataNames),
            UserdataName = UserdataName,
            Register = Register,
            StartPc = StartPc,
            EndPc = StartPc + Span,
        }
    end

    return Result
end

return TypeInfo
