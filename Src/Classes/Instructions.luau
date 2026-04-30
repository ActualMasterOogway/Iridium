local Buffer = require("@root/Utilities/Buffer")
local LuauSpec = require("@root/Luau/Spec")
local Instruction = require("@root/Classes/Instruction")

--[=[
	@class Instructions

	Lazy-decoded sequence of Luau instruction words. Behaves like a 1-indexed
	array of `Instruction` values without materialising them up-front: words are
	stored packed in a single u32 buffer and decoded on demand through
	`__index`, `__iter`, and `__len`.

	Aux slots (the slot following an instruction whose `OpCodeInfo.HasAux` is
	true) decode as NOP-shaped Instructions. The actual aux word is exposed on
	the primary instruction via `.AuxValue` so consumers can inspect it directly
	without indexing the placeholder slot.

	Returned `Instruction` objects are freshly allocated on every access; do not
	rely on instance identity (`a == b`) across calls. Per-call mutations are
	discarded.
]=]
local Instructions = {}
Instructions.__type = "Instructions"

--[=[
	AuxFlags is a packed bitset: bit (Pc - 1) marks Pc as an aux slot.
	Byte = (Pc - 1) >> 3, mask = 1 << ((Pc - 1) & 7).
]=]
local function IsAuxSlot(AuxFlags: buffer, Pc: number): boolean
	return bit32.btest(buffer.readu8(AuxFlags, bit32.rshift(Pc - 1, 3)), bit32.lshift(1, bit32.band(Pc - 1, 7)))
end

local function MarkAuxSlot(AuxFlags: buffer, Pc: number)
	local ByteOffset = bit32.rshift(Pc - 1, 3)
	buffer.writeu8(AuxFlags, ByteOffset, bit32.bor(buffer.readu8(AuxFlags, ByteOffset), bit32.lshift(1, bit32.band(Pc - 1, 7))))
end

local function Decode(self, Pc: number): Instruction.Instruction?
	local Count: number = self.Count
	if Pc < 1 or Pc > Count then
		return nil
	end

	local AuxFlags: buffer = self.AuxFlags
	local Words: buffer = self.Words
	local LineInfo = self.LineInfo
	local Line: number = if LineInfo then LineInfo[Pc] else 0

	if IsAuxSlot(AuxFlags, Pc) then
		-- Aux slot: surface a NOP-shaped placeholder. The aux bytes themselves
		-- are owned by the primary instruction via its AuxValue field.
		return Instruction.fromRaw(0, nil, nil, Pc, Line)
	end

	local raw = buffer.readu32(Words, (Pc - 1) * 4)
	local AuxRaw: number? = nil

	if Pc < Count and IsAuxSlot(AuxFlags, Pc + 1) then
		AuxRaw = buffer.readu32(Words, Pc * 4)
	end

	return Instruction.fromRaw(raw, self.EncodingKey, AuxRaw, Pc, Line)
end

function Instructions.__index(self, key)
	if type(key) == "number" then
		return Decode(self, key)
	end
	return Instructions[key]
end

function Instructions.__iter(self)
	local Pc = 0
	local Count: number = self.Count
	return function()
		Pc += 1
		if Pc > Count then
			return nil
		end
		return Pc, Decode(self, Pc)
	end
end

function Instructions.__len(self): number
	return self.Count
end

--[=[
	@within Instructions

	Read `Count` u32 instruction words from the bytecode buffer, packing them
	into a contiguous buffer and recording which slots are aux placeholders.

	@param Bytecode Buffer.BufferReader
	@param Count Total instruction slot count (includes aux slots)
	@param EncodingKey Optional opcode encoding key
	@return Instructions
]=]
function Instructions.new(Bytecode: Buffer.BufferReader, Count: number, EncodingKey: number?)
	local Words = buffer.create(Count * 4)
	local AuxFlags = buffer.create(bit32.rshift(Count, 3) + 2)

	local Pc = 1
	while Pc <= Count do
		local raw = Bytecode:readu32()
		buffer.writeu32(Words, (Pc - 1) * 4, raw)

		local opcode = bit32.band(raw, 0xFF)
		if EncodingKey then
			opcode = bit32.band(opcode * EncodingKey, 0xFF)
		end

		local Info = LuauSpec.LuauOpcodeByIndex[opcode]

		if Info and Info.HasAux then
			Pc += 1
			if Pc <= Count then
				local auxRaw = Bytecode:readu32()
				buffer.writeu32(Words, (Pc - 1) * 4, auxRaw)
				MarkAuxSlot(AuxFlags, Pc)
			end
		end

		Pc += 1
	end

	local self = setmetatable({}, Instructions)
	self.Words = Words
	self.AuxFlags = AuxFlags
	self.Count = Count
	self.EncodingKey = EncodingKey
	self.LineInfo = nil :: { number }?

	return self
end

--[=[
	@within Instructions

	Attach a per-Pc line-number array. After this call, decoded instructions
	will report `LineDefined` from this array rather than 0.
]=]
function Instructions:SetLineInfo(LineInfoArr: { number })
	self.LineInfo = LineInfoArr
end

export type Instructions = typeof(Instructions.new(nil :: never, nil :: never, nil :: never))

return Instructions
