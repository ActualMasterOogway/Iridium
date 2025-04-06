local Deserializer = require("Distribution/Iridium")

local _Luau, FileSystem = require("@lune/luau"), require("@lune/fs")

local ByteCode = FileSystem.readFile("Tests/Example 2.luauc") --_Luau.compile(FileSystem.readFile("Tests/Example.luau"), { optimizationLevel = 2, debugLevel = 2 })

local Deserialized = Deserializer:Deserialize(ByteCode)

-- https://github.com/Lovreware/Platinum/blob/main/init.luau#L26

local stdio = require("@lune/stdio")

local function WriteColor(str: string, color: "black" | "blue" | "cyan" | "green" | "purple" | "red" | "reset" | "white" | "yellow")
    stdio.write(stdio.color(color))
    stdio.write(str)
    stdio.write(stdio.color("reset"))
end

local function Test()
    local LongTab = string.rep(" ", 8)
    local ShortTab = string.rep(" ", 4)
    
    local MainFuntion = Deserialized.Protos[Deserialized.ProtoEntryPoint]
    local IsNativeModule = bit32.band(MainFuntion.Flags, Deserializer.LuauSpec.LuauProtoFlag.LPF_NATIVE_MODULE) == Deserializer.LuauSpec.LuauProtoFlag.LPF_NATIVE_MODULE
    if IsNativeModule then
        WriteColor("--!native\n\n", "white")
    end
    
    for ProtoIndex: number, Proto in Deserialized.Protos do
    
        local IsMainFunction: boolean = Proto == MainFuntion
        local GenericFunctionLabel: string = if (Proto.Name) then Proto.Name else `anonymous{ProtoIndex}`
        local FunctionLabel = if (IsMainFunction) then "main" else GenericFunctionLabel
    
        local FunctionArgs = {}
        for arg_index: number = 1, Proto.ParameterCount do
            table.insert(FunctionArgs, `arg{arg_index}`)
        end
        
        if (Proto.IsVararg) then table.insert(FunctionArgs, "...") end
    
        local is_natively_compiled = bit32.band(Proto.Flags, Deserializer.LuauSpec.LuauProtoFlag.LPF_NATIVE_FUNCTION) == Deserializer.LuauSpec.LuauProtoFlag.LPF_NATIVE_FUNCTION
        if (is_natively_compiled) then
            WriteColor(`@native\n`, "red")
        end
    
        WriteColor("function ", "purple")
        WriteColor(FunctionLabel, "reset")
        WriteColor("(", "white")
        WriteColor(table.concat(FunctionArgs, ", "), "reset")
        WriteColor(")", "white")
    
        if (Proto.LineDefined) then
            WriteColor(`{ShortTab}@ line {Proto.LineDefined}`, "red")
        end
    
        local IsNativeCold = bit32.band(Proto.Flags, Deserializer.LuauSpec.LuauProtoFlag.LPF_NATIVE_COLD) == Deserializer.LuauSpec.LuauProtoFlag.LPF_NATIVE_COLD
        if (IsNativeCold) then
            WriteColor(`{ShortTab}(Not profitable to compile natively)`, "red")
        end
    
        stdio.write("\n")
    
        local registers_align: number = 0
        for _, instruction in Proto.Instructions do
            local opcode_name_length: number = #instruction.OpCode.Information.Name
            if (opcode_name_length > registers_align) then registers_align = opcode_name_length end
        end
    
        local extra_align: number = 0
        for _, instruction in Proto.Instructions do
            local registers_string: string = `A: {instruction.Operands.A}, B: {instruction.Operands.B}, C: {instruction.Operands.C}, D: {instruction.Operands.D}, E: {instruction.Operands.E}`
            if (#registers_string > extra_align) then extra_align = #registers_string end
        end
    
        local stoopid_labels = {}
    
        local has_jump = false
    
        for instruction_index: number, instruction in Proto.Instructions do
            if (instruction.OpCode.Information == Deserializer.LuauSpec.LuauOpcode.LOP_JUMPBACK or 
                instruction.OpCode.Information == Deserializer.LuauSpec.LuauOpcode.LOP_JUMP or 
                instruction.OpCode.Information == Deserializer.LuauSpec.LuauOpcode.LOP_JUMPIFNOTLT or 
                instruction.OpCode.Information == Deserializer.LuauSpec.LuauOpcode.LOP_FORNPREP or
                instruction.OpCode.Information == Deserializer.LuauSpec.LuauOpcode.LOP_FORNLOOP or
                instruction.OpCode.Information == Deserializer.LuauSpec.LuauOpcode.LOP_JUMPXEQKN or
                instruction.OpCode.Information == Deserializer.LuauSpec.LuauOpcode.LOP_JUMPIFNOT or
                instruction.OpCode.Information == Deserializer.LuauSpec.LuauOpcode.LOP_JUMPIFNOTLE or
                instruction.OpCode.Information == Deserializer.LuauSpec.LuauOpcode.LOP_JUMPIF or
                instruction.OpCode.Information == Deserializer.LuauSpec.LuauOpcode.LOP_JUMPIFLE or
                instruction.OpCode.Information == Deserializer.LuauSpec.LuauOpcode.LOP_JUMPXEQKS or
                instruction.OpCode.Information == Deserializer.LuauSpec.LuauOpcode.LOP_JUMPIFLT) then
                    print(instruction.Operands.D + 1)
                    local jmp = ((instruction_index) + instruction.Operands.D) + 1
                    local already_found = false
                    for _, v in stoopid_labels do
                        if (v.to_index == jmp) then 
                            v.from_instr[instruction_index] = true
                            already_found = true
                            break
                        end
                    end
                    if (not already_found) then
                        table.insert(stoopid_labels, { 
                            from_instr = { [instruction_index] = true },
                            to_index = jmp,
                            label = jmp
                        })
                    end
            end
        end
    
        for instruction_index: number, instruction in Proto.Instructions do
            local opcode_name_length: number = #instruction.OpCode.Information.Name
    
            for index: number, label in stoopid_labels do
                if (label.to_index == (instruction_index)) then
                    WriteColor(`{LongTab}label_{label.label}:\n`, "purple")
                    has_jump = true
                end
            end
    
            local registers_string: string = `A: {instruction.Operands.A}, B: {instruction.Operands.B}, C: {instruction.Operands.C}, D: {instruction.Operands.D}, E: {instruction.Operands.E}`
            
            WriteColor(`{if (has_jump) then LongTab else ""}{LongTab}[{instruction_index}] #{instruction_index}`, "blue")
            WriteColor(`{ShortTab}{instruction.OpCode.Information.Name}`, "yellow")
            WriteColor(`{string.rep(" ", registers_align - opcode_name_length)}{ShortTab}{registers_string}`, "reset")
            if (instruction.Context.LineDefined) then
                WriteColor(`{ShortTab}{string.rep(" ", extra_align - #registers_string)}@ line {instruction.Context.LineDefined}`, "red")
            end
    
            for index: number, label in stoopid_labels do
                if (label.from_instr[instruction_index]) then
                    WriteColor(`{LongTab}goto label_{label.label}`, "purple")
                end
            end
    
            if (instruction.OpCode.Information.HasAux) then
                WriteColor(`{LongTab}AUX: `, "reset")
                WriteColor(tostring(instruction.AuxValue), "blue")
            end
    
            stdio.write("\n")
        end
    
        stdio.write("\n")
    end
end

Test()