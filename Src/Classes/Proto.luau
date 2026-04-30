local Buffer = require("@root/Utilities/Buffer")

local LuauSpec = require("@root/Luau/Spec")
local TypeInfo = require("@root/Luau/TypeInfo")

local Instructions, Upvalue = require("@root/Classes/Instructions"), require("@root/Classes/Upvalue")

local Nil, Boolean, Number, String, Import, Table, Closure, Vector, TableWithConstants, Integer =
    require("@root/Classes/Constants/Nil"),
    require("@root/Classes/Constants/Boolean"),
    require("@root/Classes/Constants/Number"),
    require("@root/Classes/Constants/String"),
    require("@root/Classes/Constants/Import"),
    require("@root/Classes/Constants/Table"),
    require("@root/Classes/Constants/Closure"),
    require("@root/Classes/Constants/Vector"),
    require("@root/Classes/Constants/TableWithConstants"),
    require("@root/Classes/Constants/Integer")

--[=[
	@class Proto

	The Proto class is used to lift a function
]=]
local Proto = {}
Proto.__type = "Proto"
Proto.__index = Proto

--[=[
	@within Proto

	The Proto class is used to lift a function

	@param Bytecode The buffer wrapper of the Bytecde
    @param Deserializer The deserializer
	@return Proto
]=]
function Proto.new(Bytecode: Buffer.BufferReader, Deserializer, EncodingKey: number?): Proto
	local self = setmetatable({}, Proto)
    self.Main = false

    -- Function Header

    self.MaxStackSize = Bytecode:readu8()
    self.ParameterCount = Bytecode:readu8()
    self.UpvalueCount = Bytecode:readu8()
    self.IsVararg = Bytecode:readu8() == 1

    -- Types
    --
    -- v1 layout (bytes): [LBC_TYPE_FUNCTION][numparams][param-types]
    -- v2/v3 layout: VarInt funcSize, VarInt upvalsCount, VarInt localsCount,
    --               followed by funcSize bytes of v1-style signature,
    --               then upvalsCount type bytes,
    --               then localsCount [type, reg, startpc varint, span varint] entries.
    -- v3 additionally resolves tagged-userdata bytes against Deserializer.UserdataNames.

    self.FunctionType = nil :: TypeInfo.FunctionTypeInfo?
    self.UpvalueTypes = {} :: { TypeInfo.ParsedType }
    self.LocalTypes = {} :: { TypeInfo.ParsedLocal }

    if Deserializer.IsTyped then
        self.Flags = Bytecode:readu8()

        self.TypeSize = Bytecode:ReadVarInt()

        if self.TypeSize > 0 then
            local TypesData = Bytecode:ReadBytes(self.TypeSize)
            local UserdataNames = Deserializer.UserdataNames

            if Deserializer.TypesVersion == 1 then
                assert(self.TypeSize == 2 + self.ParameterCount, "Type size mismatch")

                self.FunctionType = TypeInfo.ParseFunctionSignature(TypesData, UserdataNames)
            elseif Deserializer.TypesVersion == 2 or Deserializer.TypesVersion == 3 then
                local FuncSize = TypesData:ReadVarInt()
                local UpvalsCount = TypesData:ReadVarInt()
                local LocalsCount = TypesData:ReadVarInt()

                if FuncSize > 0 then
                    local FuncBytes = TypesData:ReadBytes(FuncSize)
                    self.FunctionType = TypeInfo.ParseFunctionSignature(FuncBytes, UserdataNames)
                end

                self.UpvalueTypes = TypeInfo.ParseUpvalueTypes(TypesData, UpvalsCount, UserdataNames)
                self.LocalTypes = TypeInfo.ParseLocalTypes(TypesData, LocalsCount, UserdataNames)
            end
        end
    end

    -- Instructions

    self.InstructionCount = Bytecode:ReadVarInt()
    self.Instructions = Instructions.new(Bytecode, self.InstructionCount, EncodingKey)

    -- Constants

    self.ConstantCount = Bytecode:ReadVarInt()
    self.Constants = table.create(self.ConstantCount)

    for ConstantIndex = 1, self.ConstantCount do
        local ConstantType = Bytecode:readu8()

        if (ConstantType == LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_NIL) then
            self.Constants[ConstantIndex] = Nil.new()
        elseif (ConstantType == LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_BOOLEAN) then
            self.Constants[ConstantIndex] = Boolean.new(Bytecode:ReadBoolean())
        elseif (ConstantType == LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_NUMBER) then
            self.Constants[ConstantIndex] = Number.new(Bytecode:readf64())
        elseif (ConstantType == LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_STRING) then
            local StringIndex = Bytecode:ReadVarInt()
            local Wrapper = Deserializer.StringConstants[StringIndex]
            if not Wrapper then
                Wrapper = String.new(Deserializer.Strings[StringIndex])
                Deserializer.StringConstants[StringIndex] = Wrapper
            end
            self.Constants[ConstantIndex] = Wrapper
        elseif (ConstantType == LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_IMPORT) then
            local ImportID = Bytecode:readu32()
            local Count = bit32.rshift(ImportID, 30)
            
            local Names = table.create(Count)

            for i = 1, Count do
                local ShiftedConstantIndex = bit32.band(bit32.rshift(ImportID, 30 - i * 10), 1023)

                Names[i] = self.Constants[ShiftedConstantIndex + 1]
            end

            self.Constants[ConstantIndex] = Import.new(Names)
        elseif (ConstantType == LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_TABLE) then
            local KeyCount = Bytecode:ReadVarInt()
            local Keys: { any } = table.create(KeyCount)

            for ValueIndex = 1, KeyCount do
                Keys[ValueIndex] = self.Constants[Bytecode:ReadVarInt() + 1]
            end

            self.Constants[ConstantIndex] = Table.new(Keys)
        elseif (ConstantType == LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_CLOSURE) then
            local ClosureIndex = Bytecode:ReadVarInt()
            local Wrapper = Deserializer.ClosureConstants[ClosureIndex]
            if not Wrapper then
                Wrapper = Closure.new(ClosureIndex)
                Deserializer.ClosureConstants[ClosureIndex] = Wrapper
            end
            self.Constants[ConstantIndex] = Wrapper
        elseif (ConstantType == LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_VECTOR) then
            local x, y, z, w =
                Bytecode:readf32(), Bytecode:readf32(), Bytecode:readf32(), Bytecode:readf32()
            self.Constants[ConstantIndex] = Vector.new(x, y, z, w)
        elseif (ConstantType == LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_TABLE_WITH_CONSTANTS) then
            local KeyCount = Bytecode:ReadVarInt()
            local Pairs: { TableWithConstants.Pair } = table.create(KeyCount)

            for PairIndex = 1, KeyCount do
                local Key = Bytecode:ReadVarInt()
                local ConstantIdx = Bytecode:readi32()

                Pairs[PairIndex] = {
                    Key = self.Constants[Key + 1],
                    Value = if ConstantIdx >= 0 then self.Constants[ConstantIdx + 1] else nil
                }
            end

            self.Constants[ConstantIndex] = TableWithConstants.new(Pairs)
        elseif (ConstantType == LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_INTEGER) then
            local IsNegative = Bytecode:ReadBoolean()
            local Magnitude = Bytecode:ReadVarInt64()

            self.Constants[ConstantIndex] = Integer.new(Magnitude, IsNegative)
        else
            error(`Unexpected constant kind ({ConstantType})`)
        end
    end

    -- Protos (Functions)

    self.ProtoCount = Bytecode:ReadVarInt()
    self.Protos = table.create(self.ProtoCount)

    for i = 1, self.ProtoCount do
        local fid = Bytecode:ReadVarInt()

        self.Protos[i] = Deserializer.Protos[fid]
    end

    -- Proto Extra Information

    self.LineDefined = Bytecode:ReadVarInt()
    self.LastLineDefined = 0
    self.Name = Deserializer:ReadStringRef()

    -- Instruction Line Information

    self.HasLineInfo = Bytecode:ReadBoolean()

    if self.HasLineInfo then
        local LineGapLog2 = Bytecode:readu8()

        local Intervals, _AbsOffset = 
            bit32.rshift(self.InstructionCount - 1, LineGapLog2) + 1, 
            bit32.band(self.InstructionCount + 3, bit32.bnot(3))
        
        local LineInfo, AbsLineInfo = table.create(self.InstructionCount), table.create(Intervals)

        local LastOffset, LastLine = 0, 0

        for i = 1, self.InstructionCount do
            LastOffset = bit32.band(LastOffset + Bytecode:readu8(), 0xFF)

            LineInfo[i] = LastOffset
        end

        for i = 1, Intervals do
            LastLine += Bytecode:readi32()

            AbsLineInfo[i] = LastLine
        end

        local LineDefinedArr = table.create(self.InstructionCount)
        for Pc = 1, self.InstructionCount do
            LineDefinedArr[Pc] = AbsLineInfo[bit32.rshift(Pc - 1, LineGapLog2) + 1] + LineInfo[Pc]
        end
        self.Instructions:SetLineInfo(LineDefinedArr)

        self.LastLineDefined = LineDefinedArr[self.InstructionCount]
    end

    -- Debug Information

    self.HasDebugInfo = Bytecode:ReadBoolean()

    if self.HasDebugInfo then
        self.LocalVariableCount = Bytecode:ReadVarInt()
        self.LocalVariables = table.create(self.LocalVariableCount)

        for i = 1, self.LocalVariableCount do
            local Name = Deserializer:ReadStringRef()
            local StartPc, EndPc = Bytecode:ReadVarInt(), Bytecode:ReadVarInt()
            local Register = Bytecode:readu8()

            self.LocalVariables[i] = {
                Name = Name,
                StartPc = StartPc,
                EndPc = EndPc,
                Register = Register
            }
        end

        self.DebugUpvalueCount = Bytecode:ReadVarInt()
        self.Upvalues = table.create(self.DebugUpvalueCount)

        for i = 1, self.DebugUpvalueCount do
            self.Upvalues[i] = Upvalue.new(Deserializer:ReadStringRef())
        end
    end

	return self
end

export type Proto = typeof(Proto.new(nil :: never))

return Proto