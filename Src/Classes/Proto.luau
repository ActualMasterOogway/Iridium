local Buffer = require(script.Parent.Parent.Utilities.Buffer)

local LuauSpec = require(script.Parent.Parent.Luau.Spec)

local Instruction, Upvalue = require(script.Parent.Instruction), require(script.Parent.Upvalue)

local Nil, Boolean, Number, String, Import, Table, Closure, Vector = 
    require(script.Parent.Constants.Nil), 
    require(script.Parent.Constants.Boolean), 
    require(script.Parent.Constants.Number), 
    require(script.Parent.Constants.String), 
    require(script.Parent.Constants.Import), 
    require(script.Parent.Constants.Table), 
    require(script.Parent.Constants.Closure), 
    require(script.Parent.Constants.Vector)

--[=[
	@class Proto

	The Proto class is used to lift a function
]=]
local Proto = {}
Proto.__index = Proto

--[=[
	@within Proto

	The Proto class is used to lift a function

	@param Bytecode The buffer wrapper of the Bytecde
    @param Deserializer The deserializer
	@return Proto
]=]
function Proto.new(Bytecode: Buffer.BufferReader, Deserializer): Proto
	local self = setmetatable({}, Proto)
	self.ClassName = "Proto"
    self.Main = false

    -- Function Header

    self.MaxStackSize = Bytecode:readu8()
    self.ParameterCount = Bytecode:readu8()
    self.UpvalueCount = Bytecode:readu8()
    self.IsVararg = Bytecode:readu8() == 1

    -- Types

    if Deserializer.IsTyped then
        self.Flags = Bytecode:readu8()

        self.TypeSize = Bytecode:ReadVarInt()

        if self.TypeSize > 0 then
            local TypesData = Bytecode:ReadBytes(self.TypeSize)

            if Deserializer.TypesVersion == 1 then
                assert(self.TypeSize == 2 + self.ParameterCount, "Type size mismatch")
                assert(TypesData:readu8() == LuauSpec.LuauBytecodeType.LBC_TYPE_FUNCTION, "Invalid function type")
                assert(TypesData:readu8() == self.ParameterCount, "Parameter count mismatch")

                local HeaderSize = self.TypeSize > 127 and 4 or 3
                
                self.SizeTypeInfo = HeaderSize + self.TypeSize
                self.TypeInfo = Buffer.new(buffer.create(self.SizeTypeInfo))
                
                if HeaderSize == 4 then
                    self.TypeInfo:writeu8(bit32.bor(bit32.band(self.TypeSize, 127), bit32.lshift(1, 7)))
                    self.TypeInfo:writeu8(bit32.rshift(self.TypeSize, 7))
                else
                    self.TypeInfo:writeu8(self.TypeSize)
                end

                self.TypeInfo:seek(2)

                self.TypeInfo:copy(TypesData, 0)
            elseif Deserializer.TypesVersion == 2 or Deserializer.TypesVersion == 3 then
                self.TypeInfo = TypesData
                self.SizeTypeInfo = self.TypeSize

                if Deserializer.TypesVersion == 3 then
                    self:RemapUserdataTypes(Deserializer.UserdataRemapping, Deserializer.UserdataTypeLimit)
                end
            end
        end
    end

    -- Instructions

    self.InstructionCount = Bytecode:ReadVarInt()
    self.Instructions = table.create(self.InstructionCount)

    local SkipAuxInstruction = false

    for i = 1, self.InstructionCount do
        if SkipAuxInstruction then
            SkipAuxInstruction = false
            continue
        end

        local Instruction = Instruction.new(Bytecode)

        if Instruction.Aux then
            self.Instructions[i + 1] = Instruction.Aux
            SkipAuxInstruction = true
        end

        self.Instructions[i] = Instruction
    end

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
            self.Constants[ConstantIndex] = String.new(Deserializer.Strings[Bytecode:ReadVarInt()])
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
            self.Constants[ConstantIndex] = Closure.new(Bytecode:ReadVarInt())
        elseif (ConstantType == LuauSpec.LuauBytecodeConstants.LBC_CONSTANT_VECTOR) then
            local x, y, z, w = 
                Bytecode:readf64(), Bytecode:readf64(), Bytecode:readf64(), Bytecode:readf64()
            self.Constants[ConstantIndex] = Vector.new(x, y, z, w)
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

        for Pc, Instruction in self.Instructions do
            Instruction.Context.LineDefined = AbsLineInfo[bit32.rshift(Pc - 1, LineGapLog2) + 1] + LineInfo[Pc]
            Instruction.Context.Pc = Pc
        end

        self.LastLineDefined = self.Instructions[self.InstructionCount].Context.LineDefined
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

	return self :: Proto
end

--[=[
	@within Proto

]=]
function Proto:RemapUserdataTypes(UserdataRemapping: { any }, UserdataTypeLimit: number)
    -- https://github.com/luau-lang/luau/blob/master/VM/src/lvmload.cpp#L188

    self.UserdataInfo = {
        TypeSize = self.TypeInfo:ReadVarInt(),
        UpvalueCount = self.TypeInfo:ReadVarInt(),
        LocalCount = self.TypeInfo:ReadVarInt()
    }

    if self.UserdataInfo.TypeSize ~= 0 then
        local TypesBuffer = self.TypeInfo:ReadBytes(self.UserdataInfo.TypeSize)

        TypesBuffer:seek(2)

        for i = 1, self.UserdataInfo.TypeSize - 2 do
            local ByteValue = TypesBuffer:readu8(false)
            local Index = ByteValue - LuauSpec.LuauBytecodeType.LBC_TYPE_TAGGED_USERDATA_BASE

            if Index >= 0 and Index < UserdataTypeLimit then
                TypesBuffer:writeu8(UserdataRemapping[Index + 1], false)
            end

            TypesBuffer:seek(1)
        end
    end

    if self.UserdataInfo.UpvalueCount ~= 0 then
        local UpvalueBuffer = self.TypeInfo:ReadBytes(self.UserdataInfo.UpvalueCount)

        for i = 1, self.UserdataInfo.UpvalueCount do
            local ByteValue = UpvalueBuffer:readu8(false)
            local Index = ByteValue - LuauSpec.LuauBytecodeType.LBC_TYPE_TAGGED_USERDATA_BASE

            if Index >= 0 and Index < UserdataTypeLimit then
                UpvalueBuffer:writeu8(UserdataRemapping[Index + 1], false)
            end

            UpvalueBuffer:seek(1)
        end
    end

    if self.UserdataInfo.LocalCount ~= 0 then
        for i = 1, self.UserdataInfo.LocalCount do
            local ByteValue = self.TypeInfo:readu8(false)
            local Index = ByteValue - LuauSpec.LuauBytecodeType.LBC_TYPE_TAGGED_USERDATA_BASE

            if Index >= 0 and Index < UserdataTypeLimit then
                self.TypeInfo:writeu8(UserdataRemapping[Index + 1], false)
            end

            self.TypeInfo:seek(2)

            local _VarInt1, _VarInt2 = self.TypeInfo:ReadVarInt(), self.TypeInfo:ReadVarInt()
        end
    end

    if self.TypeInfo.LastUnreadBytes ~= 0 then
        warn(`Userdata types was not parsed properly ({self.TypeInfo.Offset}/{self.TypeInfo.Length})`)
    end
end


export type Proto = typeof(Proto.new(nil :: never))

return Proto