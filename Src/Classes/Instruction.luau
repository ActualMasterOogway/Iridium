local LuauSpec = require("@root/Luau/Spec")

local Hexadecimal = require("@root/Classes/Hexadecimal")

--[=[
	@class Instruction

	The Instruction class is used to lift a luau instruction
]=]
local Instruction = {}
Instruction.__type = "Instruction"
Instruction.__index = Instruction

function Instruction.__eq(a, b): boolean
	return a.Pc == b.Pc and a.Value.Value == b.Value.Value
end

--[=[
	@within Instruction

	Build an Instruction from a raw 32-bit instruction word. The encoding key,
	if any, is applied to the low byte before opcode lookup. AuxRaw populates
	`AuxValue` for opcodes whose `OpCodeInfo.HasAux` is true; pass nil otherwise.

	@param raw The raw 32-bit instruction word
	@param EncodingKey Optional opcode encoding key
	@param AuxRaw Optional aux 32-bit word
	@param Pc Program counter (1-based, bytecode-aligned including aux slots)
	@param LineDefined Source line number (0 if no line info)
	@return Instruction
]=]
function Instruction.fromRaw(raw: number, EncodingKey: number?, AuxRaw: number?, Pc: number, LineDefined: number): Instruction
	local self = setmetatable({}, Instruction)

    local Value = if EncodingKey then bit32.bor(bit32.band(raw, 0xFFFFFF00), bit32.band(bit32.band(raw, 0xFF) * EncodingKey, 0xFF)) else raw

    self.Value = Hexadecimal.new(Value)
    self.Code = Hexadecimal.new(bit32.band(Value, 0xFF))

    local Info = LuauSpec.LuauOpcodeByIndex[self.Code.Value]
    assert(Info, `Invalid opcode {self.Code}`)
    self.OpCodeInfo = Info

    if AuxRaw then
        self.AuxValue = Hexadecimal.new(AuxRaw)
    end

    -- Encodings (D and E are signed per upstream Bytecode.h LUAU_INSN_D/E macros)

    local D = bit32.rshift(Value, 16)
    local E = bit32.rshift(Value, 8)

    self.A = bit32.band(bit32.rshift(Value, 8), 0xFF)
    self.B = bit32.band(bit32.rshift(Value, 16), 0xFF)
    self.C = bit32.band(bit32.rshift(Value, 24), 0xFF)
    self.D = if D >= 0x8000 then D - 0x10000 else D
    self.E = if E >= 0x800000 then E - 0x1000000 else E

    self.Pc = Pc
    self.LineDefined = LineDefined

	return self
end

export type Instruction = typeof(Instruction.fromRaw(0, nil, nil, 0, 0))

return Instruction
