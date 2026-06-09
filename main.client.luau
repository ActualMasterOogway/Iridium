local Iridium = require("@root")

local fs = require("@lune/fs")
local stdio = require("@lune/stdio")
local process = require("@lune/process")

local Path = process.args[1] or "Tests/BLChar2.bin"
local ByteCode = fs.readFile(Path)

local Deserialized = Iridium:Deserialize(ByteCode)

local Reset = "\27[0m"
local Colors = {
    black = "\27[30m",
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    purple = "\27[35m",
    cyan = "\27[36m",
    white = "\27[37m",
    reset = Reset
}

local function WriteColor(str: string, color: string)
    stdio.write(`{Colors[color]}{str}{Reset}`)
end

local Op = Iridium.LuauSpec.LuauOpcode
local BuiltinsByIndex = Iridium.LuauSpec.LuauBuiltinFunctionByIndex

-- Short, aligned tag for each constant-pool entry kind.
local ConstantTag = {
    Nil = "nil", Boolean = "bool", Number = "number", String = "string",
    Import = "import", Table = "table", Closure = "closure", Vector = "vector",
    TableWithConstants = "table+k", Integer = "integer", ClassShape = "class",
}

-- Bare text for a constant used as a key / name (a String prints unquoted).
local function RawConst(Constant): string
    if not Constant then return "?" end
    if Constant.__type == "String" then
        return buffer.tostring(Constant.Value)
    end
    return tostring(Constant)
end

-- Value text for a constant (a String keeps its quotes, etc.).
local function ValConst(Constant): string
    return if Constant then tostring(Constant) else "?"
end

-- Reconstructs the source-level operation for any constant-bearing opcode.
-- Constant operands are 0-based on the wire; Proto.Constants is 1-based.
local function ResolveConstants(Proto, Instruction): string?
    local Index = Instruction.OpCodeInfo.Index
    local A, B, C, D = Instruction.A, Instruction.B, Instruction.C, Instruction.D
    local Aux = if Instruction.AuxValue then Instruction.AuxValue.Value else 0

    local function K(Offset: number)
        return Proto.Constants[Offset + 1]
    end

    if Index == Op.LOP_GETIMPORT.Index then
        return `R{A} = {RawConst(K(D))}`
    elseif Index == Op.LOP_GETGLOBAL.Index then
        return `R{A} = {RawConst(K(Aux))}`
    elseif Index == Op.LOP_SETGLOBAL.Index then
        return `{RawConst(K(Aux))} = R{A}`
    elseif Index == Op.LOP_GETTABLEKS.Index then
        return `R{A} = R{B}.{RawConst(K(Aux))}`
    elseif Index == Op.LOP_SETTABLEKS.Index then
        return `R{B}.{RawConst(K(Aux))} = R{A}`
    elseif Index == Op.LOP_NAMECALL.Index then
        return `R{A} = R{B}:{RawConst(K(Aux))}()`
    elseif Index == Op.LOP_GETUDATAKS.Index then
        return `R{A} = R{B}.{RawConst(K(bit32.band(Aux, 0xFFFF)))}`
    elseif Index == Op.LOP_SETUDATAKS.Index then
        return `R{B}.{RawConst(K(bit32.band(Aux, 0xFFFF)))} = R{A}`
    elseif Index == Op.LOP_NAMECALLUDATA.Index then
        return `R{A} = R{B}:{RawConst(K(bit32.band(Aux, 0xFFFF)))}()`
    elseif Index == Op.LOP_GETTABLEN.Index then
        return `R{A} = R{B}[{C + 1}]`
    elseif Index == Op.LOP_SETTABLEN.Index then
        return `R{B}[{C + 1}] = R{A}`
    elseif Index == Op.LOP_LOADK.Index then
        return `R{A} = {ValConst(K(D))}`
    elseif Index == Op.LOP_LOADKX.Index then
        return `R{A} = {ValConst(K(Aux))}`
    elseif Index == Op.LOP_LOADN.Index then
        return `R{A} = {D}`
    elseif Index == Op.LOP_LOADB.Index then
        return `R{A} = {B == 1}`
    elseif Index == Op.LOP_LOADNIL.Index then
        return `R{A} = nil`
    elseif Index == Op.LOP_DUPTABLE.Index then
        return `R{A} = {ValConst(K(D))}`
    elseif Index == Op.LOP_DUPCLOSURE.Index then
        return `R{A} = {ValConst(K(D))}`
    elseif Index == Op.LOP_NEWCLOSURE.Index then
        local Child = Proto.Protos[D + 1]
        local Where = if Child and Child.LineDefined ~= 0 then ` @ line {Child.LineDefined}` else ""
        return `R{A} = function(){Where}`
    elseif Index == Op.LOP_ADDK.Index then
        return `R{A} = R{B} + {RawConst(K(C))}`
    elseif Index == Op.LOP_SUBK.Index then
        return `R{A} = R{B} - {RawConst(K(C))}`
    elseif Index == Op.LOP_MULK.Index then
        return `R{A} = R{B} * {RawConst(K(C))}`
    elseif Index == Op.LOP_DIVK.Index then
        return `R{A} = R{B} / {RawConst(K(C))}`
    elseif Index == Op.LOP_MODK.Index then
        return `R{A} = R{B} % {RawConst(K(C))}`
    elseif Index == Op.LOP_POWK.Index then
        return `R{A} = R{B} ^ {RawConst(K(C))}`
    elseif Index == Op.LOP_IDIVK.Index then
        return `R{A} = R{B} // {RawConst(K(C))}`
    elseif Index == Op.LOP_ANDK.Index then
        return `R{A} = R{B} and {ValConst(K(C))}`
    elseif Index == Op.LOP_ORK.Index then
        return `R{A} = R{B} or {ValConst(K(C))}`
    elseif Index == Op.LOP_SUBRK.Index then
        return `R{A} = {RawConst(K(B))} - R{C}`
    elseif Index == Op.LOP_DIVRK.Index then
        return `R{A} = {RawConst(K(B))} / R{C}`
    elseif Index == Op.LOP_FASTCALL2K.Index then
        return `{BuiltinsByIndex[A] or A}(R{B}, {ValConst(K(Aux))})`
    elseif Index == Op.LOP_NEWCLASSMEMBER.Index then
        return `.{RawConst(K(Aux))} = R{C}`
    elseif Index == Op.LOP_JUMPXEQKNIL.Index then
        local Negate = bit32.btest(Aux, 0x80000000)
        return `if R{A} {if Negate then "~=" else "=="} nil`
    elseif Index == Op.LOP_JUMPXEQKB.Index then
        local Negate = bit32.btest(Aux, 0x80000000)
        return `if R{A} {if Negate then "~=" else "=="} {bit32.band(Aux, 1) == 1}`
    elseif Index == Op.LOP_JUMPXEQKN.Index or Index == Op.LOP_JUMPXEQKS.Index then
        local Negate = bit32.btest(Aux, 0x80000000)
        return `if R{A} {if Negate then "~=" else "=="} {ValConst(K(bit32.band(Aux, 0xFFFFFF)))}`
    elseif Index == Op.LOP_CALL.Index or Index == Op.LOP_CALLFB.Index then
        -- B = arg count + 1 (0 = MULTRET), C = result count + 1 (0 = MULTRET)
        local Args = if B == 0 then "MULTRET" else tostring(B - 1)
        local Results = if C == 0 then "MULTRET" else tostring(C - 1)
        return `call R{A}, args={Args}, results={Results}`
    elseif Index == Op.LOP_RETURN.Index then
        local Count = if B == 0 then "MULTRET" else tostring(B - 1)
        return `return {Count} value(s) from R{A}`
    elseif Index == Op.LOP_GETVARARGS.Index then
        local Count = if B == 0 then "MULTRET" else tostring(B - 1)
        return `R{A}.. = ... ({Count})`
    elseif Index == Op.LOP_SETLIST.Index then
        local Count = if C == 0 then "MULTRET" else tostring(C - 1)
        return `R{A}[{Aux}..] = R{B}.. ({Count} value(s))`
    elseif Index == Op.LOP_NEWTABLE.Index then
        return `R{A} = table (array {Aux}, hash 2^{if B == 0 then 0 else B - 1})`
    elseif Index == Op.LOP_FORGLOOP.Index then
        return `for-in loop, {bit32.band(Aux, 0xFF)} variable(s)`
    end

    return nil
end

local function Test()
    local LongTab = string.rep(" ", 8)
    local ShortTab = string.rep(" ", 4)

    if Deserialized.HasRobloxEnvelope then
        WriteColor(`-- Roblox envelope detected (v{Deserialized.RobloxTrailerVersion}, {Deserialized.RobloxTrailerSize} bytes)\n`, "cyan")
    end

    WriteColor(`-- Bytecode v{Deserialized.BytecodeVersion}, types v{Deserialized.TypesVersion or "n/a"}, {Deserialized.ProtoCount} proto(s)\n`, "cyan")

    if next(Deserialized.UserdataNames) then
        WriteColor("-- userdata types:\n", "cyan")
        for Index, Name in Deserialized.UserdataNames do
            WriteColor(`--   [{Index}] {Name}\n`, "cyan")
        end
    end

    stdio.write("\n")

    local MainFunction = Deserialized.Protos[Deserialized.ProtoEntryPoint]
    local IsNativeModule = MainFunction.Flags and bit32.band(MainFunction.Flags, Iridium.LuauSpec.LuauProtoFlag.LPF_NATIVE_MODULE) == Iridium.LuauSpec.LuauProtoFlag.LPF_NATIVE_MODULE
    if IsNativeModule then
        WriteColor("--!native\n\n", "white")
    end

    for ProtoIndex: number, Proto in Deserialized.Protos do
        local IsMainFunction: boolean = Proto == MainFunction
        local GenericFunctionLabel: string = if (Proto.Name) then Proto.Name else `anonymous{ProtoIndex}`
        local FunctionLabel = if (IsMainFunction) then "main" else GenericFunctionLabel

        local function describeType(t)
            return if t.IsOptional then `{t.Name}?` else t.Name
        end

        local FunctionArgs = {}
        local ParamTypes = if Proto.FunctionType then Proto.FunctionType.ParameterTypes else nil
        for arg_index: number = 1, Proto.ParameterCount do
            local Arg = `arg{arg_index}`
            local Annotation = if ParamTypes and ParamTypes[arg_index] then `: {describeType(ParamTypes[arg_index])}` else ""
            table.insert(FunctionArgs, `{Arg}{Annotation}`)
        end

        if Proto.IsVararg then table.insert(FunctionArgs, "...") end

        local IsNativelyCompiled = Proto.Flags and bit32.band(Proto.Flags, Iridium.LuauSpec.LuauProtoFlag.LPF_NATIVE_FUNCTION) == Iridium.LuauSpec.LuauProtoFlag.LPF_NATIVE_FUNCTION
        if (IsNativelyCompiled) then
            WriteColor(`@native\n`, "red")
        end

        WriteColor("function ", "purple")
        WriteColor(FunctionLabel, "reset")
        WriteColor("(", "white")
        WriteColor(table.concat(FunctionArgs, ", "), "reset")
        WriteColor(")", "white")

        if (Proto.LineDefined ~= 0) then
            WriteColor(`{ShortTab}@ line {Proto.LineDefined}`, "red")
        end

        local IsNativeCold = Proto.Flags and bit32.band(Proto.Flags, Iridium.LuauSpec.LuauProtoFlag.LPF_NATIVE_COLD) == Iridium.LuauSpec.LuauProtoFlag.LPF_NATIVE_COLD
        if (IsNativeCold) then
            WriteColor(`{ShortTab}(Not profitable to compile natively)`, "red")
        end

        stdio.write("\n")

        WriteColor(`{ShortTab}-- frame: {Proto.MaxStackSize} regs, {Proto.ParameterCount} param(s), {Proto.UpvalueCount} upvalue(s), {Proto.ProtoCount} child proto(s)\n`, "cyan")

        for upvalIndex, upvalType in Proto.UpvalueTypes do
            WriteColor(`{ShortTab}-- U{upvalIndex - 1}: {describeType(upvalType)}\n`, "cyan")
        end

        for _, localType in Proto.LocalTypes do
            WriteColor(`{ShortTab}-- R{localType.Register}: {describeType(localType)} (pc {localType.StartPc}..{localType.EndPc})\n`, "cyan")
        end

        -- Debug names: present only when the bytecode kept debug info (Roblox
        -- usually strips it). When present these are the real source identifiers.
        if Proto.HasDebugInfo then
            for _, Local in Proto.LocalVariables do
                WriteColor(`{ShortTab}-- local "{Local.Name}" -> R{Local.Register} (pc {Local.StartPc}..{Local.EndPc})\n`, "green")
            end
            for UpvalueIndex, DebugUpvalue in Proto.Upvalues do
                WriteColor(`{ShortTab}-- upvalue U{UpvalueIndex - 1} = "{DebugUpvalue.Name}"\n`, "green")
            end
        end

        -- Constant pool: the canonical reference for every K-index the
        -- instructions resolve against (imports, strings, numbers, table
        -- templates, vectors, closures, ...).
        if Proto.ConstantCount > 0 then
            WriteColor(`{ShortTab}-- constants ({Proto.ConstantCount}):\n`, "cyan")
            for ConstantIndex, Constant in Proto.Constants do
                local Label = `K{ConstantIndex - 1}`
                local Tag = ConstantTag[Constant.__type] or Constant.__type
                WriteColor(`{ShortTab}{ShortTab}{Label}{string.rep(" ", math.max(1, 6 - #Label))}`, "blue")
                WriteColor(`{Tag}{string.rep(" ", math.max(1, 9 - #Tag))}`, "green")
                WriteColor(`{tostring(Constant)}\n`, "reset")
            end
        end

        local RegistersAlign: number = 0
        for _, instruction in Proto.Instructions do
            local OpcodeNameLength: number = #instruction.OpCodeInfo.Name
            if (OpcodeNameLength > RegistersAlign) then RegistersAlign = OpcodeNameLength end
        end

        local ExtraAlign: number = 0
        for _, instruction in Proto.Instructions do
            local RegistersString: string = `A: {instruction.A}, B: {instruction.B}, C: {instruction.C}, D: {instruction.D}, E: {instruction.E}`
            if (#RegistersString > ExtraAlign) then ExtraAlign = #RegistersString end
        end

        local Labels = {}
        local HasJump = false

        local JumpOpcodes = {
            [Iridium.LuauSpec.LuauOpcode.LOP_JUMPBACK.Index] = true,
            [Iridium.LuauSpec.LuauOpcode.LOP_JUMP.Index] = true,
            [Iridium.LuauSpec.LuauOpcode.LOP_JUMPIFNOTLT.Index] = true,
            [Iridium.LuauSpec.LuauOpcode.LOP_FORNPREP.Index] = true,
            [Iridium.LuauSpec.LuauOpcode.LOP_FORNLOOP.Index] = true,
            [Iridium.LuauSpec.LuauOpcode.LOP_JUMPXEQKN.Index] = true,
            [Iridium.LuauSpec.LuauOpcode.LOP_JUMPIFNOT.Index] = true,
            [Iridium.LuauSpec.LuauOpcode.LOP_JUMPIFNOTLE.Index] = true,
            [Iridium.LuauSpec.LuauOpcode.LOP_JUMPIF.Index] = true,
            [Iridium.LuauSpec.LuauOpcode.LOP_JUMPIFLE.Index] = true,
            [Iridium.LuauSpec.LuauOpcode.LOP_JUMPXEQKS.Index] = true,
            [Iridium.LuauSpec.LuauOpcode.LOP_JUMPXEQKB.Index] = true,
            [Iridium.LuauSpec.LuauOpcode.LOP_JUMPXEQKNIL.Index] = true,
            [Iridium.LuauSpec.LuauOpcode.LOP_JUMPIFLT.Index] = true,
            [Iridium.LuauSpec.LuauOpcode.LOP_JUMPX.Index] = true,
        }

        for InstructionIndex: number, Instruction in Proto.Instructions do
            if JumpOpcodes[Instruction.OpCodeInfo.Index] then
                local Jump = InstructionIndex + Instruction.D + 1
                local AlreadyFound = false
                for _, v in Labels do
                    if v.to_index == Jump then
                        v.from_instr[InstructionIndex] = true
                        AlreadyFound = true
                        break
                    end
                end
                if not AlreadyFound then
                    table.insert(Labels, {
                        from_instr = { [InstructionIndex] = true },
                        to_index = Jump,
                        label = Jump
                    })
                end
            end
        end

        local CaptureTypes = Iridium.LuauSpec.LuauCaptureTypeByIndex
        local Builtins = Iridium.LuauSpec.LuauBuiltinFunctionByIndex
        local Op = Iridium.LuauSpec.LuauOpcode

        local FastCallOps = {
            [Op.LOP_FASTCALL.Index] = true,
            [Op.LOP_FASTCALL1.Index] = true,
            [Op.LOP_FASTCALL2.Index] = true,
            [Op.LOP_FASTCALL2K.Index] = true,
            [Op.LOP_FASTCALL3.Index] = true,
        }

        for InstructionIndex: number, Instruction in Proto.Instructions do
            local OpcodeNameLength: number = #Instruction.OpCodeInfo.Name
            local OpcodeIndex = Instruction.OpCodeInfo.Index

            for _, label in Labels do
                if label.to_index == InstructionIndex then
                    WriteColor(`{LongTab}label_{label.label}:\n`, "purple")
                    HasJump = true
                end
            end

            local RegistersString: string = `A: {Instruction.A}, B: {Instruction.B}, C: {Instruction.C}, D: {Instruction.D}, E: {Instruction.E}`

            -- Semantic decode for opcodes whose A/B fields encode an enum/index.
            local SemanticNote: string? = nil
            if OpcodeIndex == Op.LOP_CAPTURE.Index then
                local Kind = CaptureTypes[Instruction.A] or `?{Instruction.A}`
                local Source = if Instruction.A == Iridium.LuauSpec.LuauCaptureType.LCT_UPVAL
                    then `U{Instruction.B}`
                    else `R{Instruction.B}`
                SemanticNote = `{Kind} {Source}`
            elseif FastCallOps[OpcodeIndex] then
                SemanticNote = Builtins[Instruction.A] or `LBF_?{Instruction.A}`
            end

            -- Source-level decode: resolve constant-bearing operands to text.
            local ResolvedNote: string? = ResolveConstants(Proto, Instruction)

            WriteColor(`{if HasJump then LongTab else ""}{LongTab}[{InstructionIndex}] #{InstructionIndex}`, "blue")
            WriteColor(`{ShortTab}{Instruction.OpCodeInfo.Name}`, "yellow")
            WriteColor(`{string.rep(" ", RegistersAlign - OpcodeNameLength)}{ShortTab}{RegistersString}`, "reset")
            if ResolvedNote then
                WriteColor(`{ShortTab}; {ResolvedNote}`, "cyan")
            elseif SemanticNote then
                WriteColor(`{ShortTab}; {SemanticNote}`, "green")
            end
            if Instruction.LineDefined ~= 0 then
                WriteColor(`{ShortTab}{string.rep(" ", ExtraAlign - #RegistersString)}@ line {Instruction.LineDefined}`, "red")
            end

            for _, label in Labels do
                if label.from_instr[InstructionIndex] then
                    WriteColor(`{LongTab}goto label_{label.label}`, "purple")
                end
            end

            if Instruction.OpCodeInfo.HasAux then
                WriteColor(`{LongTab}AUX: `, "reset")
                WriteColor(tostring(Instruction.AuxValue), "blue")
            end

            stdio.write("\n")
        end
        --[[
        if Proto.ConstantCount > 0 then
            stdio.write("\n")
            WriteColor(`{ShortTab}Constants:\n`, "cyan")
            for ConstantIndex, Constant in Proto.Constants do
                WriteColor(`{ShortTab}{ShortTab}[{ConstantIndex}] {Constant.__type} = `, "blue")
                WriteColor(tostring(Constant), "reset")
                stdio.write("\n")
            end
        end
        --]]

        stdio.write("\n")
    end
end

Test()