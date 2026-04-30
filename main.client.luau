local Iridium = require("@root")

local fs, io, process = zune.fs, zune.io, zune.process

local Path = process.args[2] or "Tests/BLChar2.bin"
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

local stdout = io.stdout

local function WriteColor(str: string, color: string)
    stdout:write(`{Colors[color]}{str}{Reset}`)
end

local function Test()
    local LongTab = string.rep(" ", 8)
    local ShortTab = string.rep(" ", 4)

    if Deserialized.HasRobloxEnvelope then
        WriteColor(`-- Roblox envelope detected (v{Deserialized.RobloxTrailerVersion}, {Deserialized.RobloxTrailerSize} bytes)\n`, "cyan")
    end

    WriteColor(`-- Bytecode v{Deserialized.BytecodeVersion}, types v{Deserialized.TypesVersion or "n/a"}, {Deserialized.ProtoCount} proto(s)\n\n`, "cyan")

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

        stdout:write("\n")

        for upvalIndex, upvalType in Proto.UpvalueTypes do
            WriteColor(`{ShortTab}-- U{upvalIndex - 1}: {describeType(upvalType)}\n`, "cyan")
        end

        for _, localType in Proto.LocalTypes do
            WriteColor(`{ShortTab}-- R{localType.Register}: {describeType(localType)} (pc {localType.StartPc}..{localType.EndPc})\n`, "cyan")
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

            WriteColor(`{if HasJump then LongTab else ""}{LongTab}[{InstructionIndex}] #{InstructionIndex}`, "blue")
            WriteColor(`{ShortTab}{Instruction.OpCodeInfo.Name}`, "yellow")
            WriteColor(`{string.rep(" ", RegistersAlign - OpcodeNameLength)}{ShortTab}{RegistersString}`, "reset")
            if SemanticNote then
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

            stdout:write("\n")
        end
        --[[
        if Proto.ConstantCount > 0 then
            stdout:write("\n")
            WriteColor(`{ShortTab}Constants:\n`, "cyan")
            for ConstantIndex, Constant in Proto.Constants do
                WriteColor(`{ShortTab}{ShortTab}[{ConstantIndex}] {Constant.__type} = `, "blue")
                WriteColor(tostring(Constant), "reset")
                stdout:write("\n")
            end
        end
        --]]

        stdout:write("\n")
    end
end

Test()