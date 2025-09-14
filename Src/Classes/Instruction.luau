local Buffer = require(script.Parent.Parent.Utilities.Buffer)

local LuauSpec = require(script.Parent.Parent.Luau.Spec)

local Hexadecimal = require(script.Parent.Hexadecimal)

export type Context = {
    LineDefined: number,
    Pc: number
}

--[=[
	@class Instruction

	The Instruction class is used to lift a luau instruction
]=]
local Instruction = {}
Instruction.__index = Instruction

--[=[
	@within Instruction

	The Instruction class is used to lift a luau instruction

	@param Bytecode Buffer.BufferReader
	@return Instruction
]=]
function Instruction.new(Bytecode: Buffer.BufferReader, Value: number?, EncodingKey: number?): Instruction
	local self = setmetatable({}, Instruction)
	self.ClassName = "Instruction"

    -- Opcode

    local real = Value or Bytecode:readu32()
    self.Value = Hexadecimal.new(if EncodingKey then bit32.band(real, 0xFF) * EncodingKey else real)
    self.Code = Hexadecimal.new(bit32.band(self.Value.Value, 0xFF))
    self.OpCode = {}

    assert(self.Code.Value >= 0 and self.Code.Value < LuauSpec.LuauOpcode.LOP__COUNT.Index, `Invalid opcode {self.Code}`)

    for i, OpCodeInfo in LuauSpec.LuauOpcode :: { LuauSpec.OpCodeInfo } do
        if OpCodeInfo.Index == self.Code.Value then
            self.OpCode.Information = OpCodeInfo
            break
        end
    end

    -- Aux

    if self.OpCode.Information.HasAux then
        self.AuxValue = Hexadecimal.new(Bytecode:readu32(false))
        self.Aux = Instruction.new(Bytecode, bit32.rshift(Bytecode:readu32(), 32))
    end

    -- Encodings

    self.Encodings = {
        A = bit32.band(bit32.rshift(real, 8), 0xFF),
        B = bit32.band(bit32.rshift(real, 16), 0xFF),
        C = bit32.band(bit32.rshift(real, 24), 0xFF),
        D = bit32.rshift(real, 16),
        E = bit32.rshift(real, 8)
    }

    -- Context

    self.Context = {
        LineDefined = 0,
        Pc = 0
    }

	return self
end

export type Instruction = typeof(Instruction.new(nil :: never))

return Instruction