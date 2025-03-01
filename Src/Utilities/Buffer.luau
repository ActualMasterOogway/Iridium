export type BufferReader = {
	Buffer: buffer,
	Offset: number,
	Length: number,
	LastUnreadBytes: number,
	
	tostring: (BufferReader) -> string,
	len: (BufferReader) -> number,
	
	readi8: (BufferReader, shift: boolean?) -> number,
	readu8: (BufferReader, shift: boolean?) -> number,
	readi16: (BufferReader, shift: boolean?) -> number,
	readu16: (BufferReader, shift: boolean?) -> number,
	readi32: (BufferReader, shift: boolean?) -> number,
	readu32: (BufferReader, shift: boolean?) -> number,
	readf32: (BufferReader, shift: boolean?) -> number,
	readf64: (BufferReader, shift: boolean?) -> number,
	
	writei8: (BufferReader, value: number, shift: boolean?) -> number,
	writeu8: (BufferReader, value: number, shift: boolean?) -> number,
	writei16: (BufferReader, value: number, shift: boolean?) -> number,
	writeu16: (BufferReader, value: number, shift: boolean?) -> number,
	writei32: (BufferReader, value: number, shift: boolean?) -> number,
	writeu32: (BufferReader, value: number, shift: boolean?) -> number,
	writef32: (BufferReader, value: number, shift: boolean?) -> number,
	writef64: (BufferReader, value: number, shift: boolean?) -> number,
	
	readstring: (BufferReader, size: number, shift: boolean?) -> string,
	writestring: (BufferReader, value: string, size: number?, shift: boolean?) -> (),
	
	fill: (BufferReader, value: number, count: number?) -> (),
	
	seek: (BufferReader, dst: number) -> (),
	resize: (BufferReader, newSize: number) -> (), -- this is expensive

	ReadVarInt: (BufferReader, shift: boolean?) -> number,
	ReadString: (BufferReader, length: number?, shift: boolean?) -> string,
	ReadBoolean: (BufferReader, shift: boolean?) -> boolean,
	ReadBytes: (BufferReader, size: number, shift: boolean?) -> BufferReader
}

local BufferWrapper = {}

function BufferWrapper.new(Buffer: number | string | buffer | BufferReader): BufferReader
	assert(typeof(Buffer) == "buffer" or typeof(Buffer) == "string" or BufferWrapper.IsBufferReader(Buffer), `Expected type 'buffer' or 'string' at Argument #1 (got '{typeof(Buffer)}')`)

	if typeof(Buffer) == "string" then
		Buffer = buffer.fromstring(Buffer)
	elseif BufferWrapper.IsBufferReader(Buffer) then
		return Buffer :: BufferReader
	elseif typeof(Buffer) == "number" then
		Buffer = buffer.create(Buffer)
	end
	
	local BufferReader = setmetatable({}, {__tostring = function(self: BufferReader) return `BufferReader: {tostring(self.Buffer):sub(9, -1)}` end})
	BufferReader.Buffer = Buffer :: buffer
	BufferReader.Offset = 0
	BufferReader.Length = buffer.len(BufferReader.Buffer)
	BufferReader.LastUnreadBytes = BufferReader.Length
	
	-- all functions are proxies to the buffer lib basically, and moves the offset
	-- except seek
	
	function BufferReader:seek(dst: number)
		-- seek should move the offset add/sub dst
		self.Offset += dst
		self.LastUnreadBytes -= dst
	end

	function BufferReader:tostring(): string
		return buffer.tostring(self.Buffer)
	end
	
	function BufferReader:len(): number
		return self.Length
	end
	
	function BufferReader:readi8(shift: boolean?): number
		local dat = buffer.readi8(self.Buffer, self.Offset)
		
		if shift ~= false then
			self:seek(1)
		end

		return dat
	end
	
	function BufferReader:readu8(shift: boolean?): number
		local dat = buffer.readu8(self.Buffer, self.Offset)

		if shift ~= false then
			self:seek(1)
		end

		return dat
	end
	
	function BufferReader:readi16(shift: boolean?): number
		local dat = buffer.readi16(self.Buffer, self.Offset)

		if shift ~= false then
			self:seek(2)
		end

		return dat
	end
	
	function BufferReader:readu16(shift: boolean?): number
		local dat = buffer.readu16(self.Buffer, self.Offset)

		if shift ~= false then
			self:seek(2)
		end

		return dat
	end
	
	function BufferReader:readi32(shift: boolean?): number
		local dat = buffer.readi32(self.Buffer, self.Offset)

		if shift ~= false then
			self:seek(4)
		end

		return dat
	end
	
	function BufferReader:readu32(shift: boolean?): number
		local dat = buffer.readu32(self.Buffer, self.Offset)
	
		if shift ~= false then
			self:seek(4)
		end

		return dat
	end
	
	function BufferReader:readf32(shift: boolean?): number
		local dat = buffer.readf32(self.Buffer, self.Offset)

		if shift ~= false then
			self:seek(4)
		end

		return dat
	end
	
	function BufferReader:readf64(shift: boolean?): number
		local dat = buffer.readf64(self.Buffer, self.Offset)

		if shift ~= false then
			self:seek(8)
		end

		return dat
	end
	
	function BufferReader:readstring(size: number, shift: boolean?): string
		local dat = buffer.readstring(self.Buffer, self.Offset, size)

		if shift ~= false then
			self:seek(size)
		end

		return dat
	end
	
	function BufferReader:writestring(value: string, size: number?, shift: boolean?)
        local Size = if typeof(size) == "number" then size else #value

		buffer.writestring(self.Buffer, self.Offset, value, Size)

		if shift ~= false then
			self:seek(Size)
		end
	end
	
	function BufferReader:writei8(value: number, shift: boolean?): number
		local dat = buffer.writei8(self.Buffer, self.Offset, value)

		if shift ~= false then
			self:seek(1)
		end

		return dat
	end
	
	function BufferReader:writeu8(value: number, shift: boolean?): number
		local dat = buffer.writeu8(self.Buffer, self.Offset, value)

		if shift ~= false then
			self:seek(1)
		end

		return dat
	end
	
	function BufferReader:writei16(value: number, shift: boolean?): number
		local dat = buffer.writei16(self.Buffer, self.Offset, value)

		if shift ~= false then
			self:seek(2)
		end

		return dat
	end
	
	function BufferReader:writeu16(value: number, shift: boolean?): number
		local dat = buffer.writeu16(self.Buffer, self.Offset, value)

		if shift ~= false then
			self:seek(2)
		end

		return dat
	end
	
	function BufferReader:writei32(value: number, shift: boolean?): number
		local dat = buffer.writei32(self.Buffer, self.Offset, value)

		if shift ~= false then
			self:seek(4)
		end

		return dat
	end
	
	function BufferReader:writeu32(value: number, shift: boolean?): number
		local dat = buffer.writeu32(self.Buffer, self.Offset, value)

		if shift ~= false then
			self:seek(4)
		end

		return dat
	end
	
	function BufferReader:writef32(value: number, shift: boolean?): number
		local dat = buffer.writef32(self.Buffer, self.Offset, value)

		if shift ~= false then
			self:seek(4)
		end

		return dat
	end
	
	function BufferReader:writef64(value: number, shift: boolean?): number
		local dat = buffer.writef64(self.Buffer, self.Offset, value)

		if shift ~= false then
			self:seek(8)
		end

		return dat
	end

	function BufferReader:copy(source: BufferReader | buffer, sourceOffset: number?, count: number?, shift: boolean?)
		local Source = (if BufferWrapper.IsBufferReader(source) then (source :: BufferReader).Buffer else source) :: buffer
		local Offset = if BufferWrapper.IsBufferReader(source) then (sourceOffset or (source :: BufferReader).Offset) else (sourceOffset or 0)
		local Count = if typeof(count) == "number" then count else self.LastUnreadBytes

		buffer.copy(self.Buffer, self.Offset, Source, Offset, Count)

		if shift ~= false then
			self:seek(Count)
		end
	end
	
	function BufferReader:resize(newSize: number)
		-- to do this, we need to make a new buffer and copy the data into it
		local resized = buffer.create(newSize)

		buffer.copy(resized, 0, self.Buffer, 0, newSize)
		self.Buffer = resized
        self.Length = newSize
	end
	
	function BufferReader:fill(value: number, size: number?)
		buffer.fill(self.Buffer, self.Offset, value, size)
	end

	function BufferReader:ReadVarInt(shift: boolean?) -- https://github.com/luau-lang/luau/blob/c13b5b7440a65987ee9dd592ee468d421d83f223/VM/src/lvmload.cpp#L120
		local Result, Shift, Offset = 0, 0, self.Offset

		repeat
			local Byte: number = self:readu8()
			
			Result = bit32.bor(Result, bit32.lshift(bit32.band(Byte, 127), Shift))
			Shift += 7
		until bit32.band(Byte, 128) == 0

		if shift == false then
			self.Offset = Offset
		end

		return Result
	end

	function BufferReader:ReadString(length: number?, shift: boolean?)
		local Length = if typeof(length) == "number" then length else self:ReadVarInt(shift)

		return self:readstring(Length, shift)
	end

	function BufferReader:ReadBoolean(shift: boolean?)
		return self:readu8(shift) == 1
	end

	function BufferReader:ReadBytes(size: number, shift: boolean?)
		local bytes = buffer.create(size)

		buffer.copy(bytes, 0, self.Buffer, self.Offset, size)

		if shift ~= false then
			self:seek(size)
		end

		return BufferWrapper.new(bytes)
	end

	return BufferReader
end

function BufferWrapper.IsBufferReader(BufferReader: any)
	return tostring(BufferReader):sub(1, 16) == "BufferReader: 0x"
end

return BufferWrapper