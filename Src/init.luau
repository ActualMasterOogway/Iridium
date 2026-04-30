local Types = require("@root/Deserializer.d")

local Buffer = require("@root/Utilities/Buffer")

local LuauSpec = require("@root/Luau/Spec")

local Proto = require("@root/Classes/Proto")

local Iridium = {
    LuauSpec = LuauSpec
}

--[=[
	@class Deserializer

	The Deserializer class is used for deserializing Luau Bytecode from versions ranging between 3 and 9
]=]
local Deserializer = {}
Deserializer.__type = "Deserializer"
Deserializer.__index = Deserializer

--[=[
	@within Deserializer

	The Deserializer class is used for deserializing Luau Bytecode from versions ranging between 3 and 9

	@param Bytecode Buffer.BufferReader
    @param Config DeserializerConfig
	@return Deserializer
]=]
function Deserializer.new(Bytecode: Buffer.BufferReader, Config: Types.DeserializerConfig): Types.Deserializer
	local self = setmetatable({}, Deserializer)
    self.Source = Bytecode

    self.HasRobloxEnvelope = false

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
    self.StringConstants = {} :: { [number]: any }
    self.ClosureConstants = {} :: { [number]: any }

    for i = 1, self.StringCount do
        self.Strings[i] = Bytecode:ReadString()
    end

    -- Userdata type name table (typesversion 3 only). Maps 1-based tagged
    -- userdata indices to their registered host-type names; the type-info
    -- bytes elsewhere reference these via LBC_TYPE_TAGGED_USERDATA_BASE + (i - 1).

    self.UserdataTypeLimit = LuauSpec.LuauBytecodeType.LBC_TYPE_TAGGED_USERDATA_END - LuauSpec.LuauBytecodeType.LBC_TYPE_TAGGED_USERDATA_BASE
    self.UserdataNames = {} :: { [number]: string }

    if self.TypesVersion == 3 then
        local Index = Bytecode:readu8()

        while Index ~= 0 do
            local Name = self:ReadStringRef() :: string

            if Index <= self.UserdataTypeLimit then
                self.UserdataNames[Index] = Name
            end

            Index = Bytecode:readu8()
        end
    end

    -- Protos (Functions)

    self.ProtoCount = Bytecode:ReadVarInt()
    self.Protos = table.create(self.ProtoCount)

    for i = 1, self.ProtoCount do
        self.Protos[i] = Proto.new(Bytecode, self, Config.EncodingKey)
    end

    self.ProtoEntryPoint = Bytecode:ReadVarInt() + 1

    self.Protos[self.ProtoEntryPoint].Main = true

    self.FunctionCount, self.Functions, self.FunctionEntryPoint = self.ProtoCount, self.Protos, self.ProtoEntryPoint

    -- Roblox envelope detection by post-body remainder + magic XOR validation.
    -- Vanilla Luau's body consumes the entire blob, leaving 0. Roblox emits
    -- one of two trailer formats; both encode the magic constant by XORing
    -- bytes between two halves of the trailer (so neither half carries the
    -- magic in cleartext, but their XOR does):
    --
    -- v0 (0x28 B / 40 B): u32(trailer[0..3]) XOR u32(trailer[8..11]) == 0x946AC432
    --   trailer[0..3]   magic-A    (XOR with trailer[8..11] = magic constant)
    --   trailer[4..7]   anti-rollback token (XOR'd with trailer[8..11];
    --                                       reject if result == 0x74171870)
    --   trailer[8..39]  32-byte MAC over body hash + token (validated by
    --                   a byte-permutation routine)
    --
    -- v1 (0x18 B / 24 B): bytewise XOR pattern in the last 4 bytes against
    --   trailer offsets 0..3 must equal [0x32, 0xC4, 0x6A, 0x01]; the third
    --   byte (0x6A) is the magic-version-tag and the last is the trailer
    --   version literal (must be 1 to be accepted).
    --   trailer[0..15]  16 bytes of MAC payload (XOR-MAC keystream input)
    --   trailer[16..19] anti-rollback token (XOR with trailer[0..3] checked
    --                                       against 0x74171870)
    --   trailer[20..23] magic+version XOR-encoded against trailer[0..3]

    local Remaining = Bytecode.LastUnreadBytes

    if Remaining == 0x28 then
        local Buf = Bytecode.Buffer
        local Length = Bytecode.Length

        local MagicLow = buffer.readu32(Buf, Length - 0x28)
        local MagicHigh = buffer.readu32(Buf, Length - 0x20)

        if bit32.bxor(MagicHigh, MagicLow) == 0x946AC432 then
            self.HasRobloxEnvelope = true
            self.RobloxTrailerVersion = 0
            self.RobloxTrailerSize = 0x28

            self.MagicA = Bytecode:readu32()
            self.MagicB = Bytecode:readu32()
            self.Hash = Bytecode:readstring(32)
        end
    elseif Remaining == 0x18 then
        local Buf = Bytecode.Buffer
        local Length = Bytecode.Length

        local M0 = bit32.bxor(buffer.readu8(Buf, Length - 4), buffer.readu8(Buf, Length - 24))
        local M1 = bit32.bxor(buffer.readu8(Buf, Length - 3), buffer.readu8(Buf, Length - 23))
        local M2 = bit32.bxor(buffer.readu8(Buf, Length - 2), buffer.readu8(Buf, Length - 22))
        local Version = bit32.bxor(buffer.readu8(Buf, Length - 1), buffer.readu8(Buf, Length - 21))

        if M0 == 0x32 and M1 == 0xC4 and M2 == 0x6A and Version == 1 then
            self.HasRobloxEnvelope = true
            self.RobloxTrailerVersion = 1
            self.RobloxTrailerSize = 0x18
            self.Trailer = Bytecode:readstring(0x18)
        end
    end

    if typeof(Config.PostFinish) == "function" then
        Config.PostFinish(self)
    end

    if Bytecode.LastUnreadBytes ~= 0 then
        print(`Bytecode was not parsed properly ({Bytecode.Offset}/{Bytecode.Length})`)
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
    Walks past one proto's body without parsing its content. Mirrors the
    serialized layout in Proto.luau. Caller must have consumed nothing of
    the proto yet — Bytecode.Offset is at the proto's first byte on entry.
]=]
local function SkipProto(Bytecode: Buffer.BufferReader, Version: number)
    Bytecode:seek(4)

    if Version >= 4 then
        Bytecode:seek(1)
        Bytecode:seek(Bytecode:ReadVarInt())
    end

    local SizeCode = Bytecode:ReadVarInt()
    Bytecode:seek(SizeCode * 4)

    for _ = 1, Bytecode:ReadVarInt() do
        local Kind = Bytecode:readu8()

        if Kind == 1 then
            Bytecode:seek(1)
        elseif Kind == 2 then
            Bytecode:seek(8)
        elseif Kind == 3 then
            Bytecode:ReadVarInt()
        elseif Kind == 4 then
            Bytecode:seek(4)
        elseif Kind == 5 then
            for _ = 1, Bytecode:ReadVarInt() do
                Bytecode:ReadVarInt()
            end
        elseif Kind == 6 then
            Bytecode:ReadVarInt()
        elseif Kind == 7 then
            Bytecode:seek(16)
        elseif Kind == 8 then
            for _ = 1, Bytecode:ReadVarInt() do
                Bytecode:ReadVarInt()
                Bytecode:seek(4)
            end
        elseif Kind == 9 then
            Bytecode:seek(1)
            Bytecode:ReadVarInt64()
        end
    end

    for _ = 1, Bytecode:ReadVarInt() do
        Bytecode:ReadVarInt()
    end

    Bytecode:ReadVarInt()
    Bytecode:ReadVarInt()

    if Bytecode:readu8() == 1 then
        local LineGapLog2 = Bytecode:readu8()
        local Intervals = bit32.rshift(SizeCode - 1, LineGapLog2) + 1

        Bytecode:seek(SizeCode + Intervals * 4)
    end

    if Bytecode:readu8() == 1 then
        for _ = 1, Bytecode:ReadVarInt() do
            Bytecode:ReadVarInt()
            Bytecode:ReadVarInt()
            Bytecode:ReadVarInt()
            Bytecode:seek(1)
        end
        for _ = 1, Bytecode:ReadVarInt() do
            Bytecode:ReadVarInt()
        end
    end
end

--[=[
    Walks the bytecode just far enough to read the first instruction word of
    the entry proto (the script main, always vararg). Records each proto's
    start offset, reads `mainid` at the end of the protos section, then jumps
    back to the entry proto's header. Resets the buffer before returning.
    Returns nil on malformed input.
]=]
local function ProbeEntryFirstInstruction(Bytecode: Buffer.BufferReader): number?
    local ok, Word: number? = pcall(function()
        local Version = Bytecode:readu8()

        if Version < LuauSpec.LuauBytecodeTag.LBC_VERSION_MIN or Version > LuauSpec.LuauBytecodeTag.LBC_VERSION_MAX then
            return nil
        end

        local TypesVersion = 0

        if Version >= 4 then
            TypesVersion = Bytecode:readu8()

            if TypesVersion < LuauSpec.LuauBytecodeTag.LBC_TYPE_VERSION_MIN or TypesVersion > LuauSpec.LuauBytecodeTag.LBC_TYPE_VERSION_MAX then
                return nil
            end
        end

        for _ = 1, Bytecode:ReadVarInt() do
            Bytecode:seek(Bytecode:ReadVarInt())
        end

        if TypesVersion == 3 then
            local Index = Bytecode:readu8()

            while Index ~= 0 do
                Bytecode:ReadVarInt()
                Index = Bytecode:readu8()
            end
        end

        local ProtoCount = Bytecode:ReadVarInt()

        if ProtoCount < 1 then
            return nil
        end

        local Starts = table.create(ProtoCount)

        for i = 1, ProtoCount do
            Starts[i] = Bytecode.Offset
            SkipProto(Bytecode, Version)
        end

        local MainId = Bytecode:ReadVarInt()

        if MainId >= ProtoCount then
            return nil
        end

        Bytecode:seek(Starts[MainId + 1] - Bytecode.Offset)

        Bytecode:seek(4)

        if Version >= 4 then
            Bytecode:seek(1)
            Bytecode:seek(Bytecode:ReadVarInt())
        end

        if Bytecode:ReadVarInt() < 1 then
            return nil
        end

        return Bytecode:readu32()
    end)

    Bytecode:seek(-Bytecode.Offset)

    return if ok then Word else nil
end

--[=[
    Recovers the opcode encoding key by inspecting the first instruction of
    the entry proto, which is guaranteed to be LOP_PREPVARARGS (65) since
    the script main is always vararg. Solving `wire * key ≡ 65 (mod 256)`
    against odd keys yields the unique key (or nil if no encoding is in use).
]=]
local function DetermineEncodingKey(Bytecode: Buffer.BufferReader): number?
    local FirstWord = ProbeEntryFirstInstruction(Bytecode)

    if not FirstWord then
        return nil
    end

    local Wire = bit32.band(FirstWord, 0xFF)

    if Wire == LuauSpec.LuauOpcode.LOP_PREPVARARGS.Index then
        return nil
    end

    if bit32.band(Wire * 203, 0xFF) == LuauSpec.LuauOpcode.LOP_PREPVARARGS.Index then
        return 203
    end

    for Key = 3, 255, 2 do
        if Key ~= 203 and bit32.band(Wire * Key, 0xFF) == LuauSpec.LuauOpcode.LOP_PREPVARARGS.Index then
            return Key
        end
    end

    return error("Could not determine encoding key", 3)
end

function Iridium:Deserialize(Bytecode: string | buffer | Buffer.BufferReader, Config: Types.DeserializerConfig?): Types.Deserializer
    local DeserializerConfig = (Config or {}) :: Types.DeserializerConfig
    local Buf = Buffer.new(Bytecode)

    if DeserializerConfig.EncodingKey == nil then
        DeserializerConfig.EncodingKey = DetermineEncodingKey(Buf)
    end

    return Deserializer.new(Buf, DeserializerConfig)
end

return Iridium