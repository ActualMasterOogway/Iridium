export type Upvalue = {
    ClassName: "Upvalue",
    Name: string
}

export type VectorConstant = {
    ClassName: "Vector",
    X: number,
    Y: number,
    Z: number,
    W: number
}

export type TableConstant = {
    ClassName: "Table",
    Value: { [number]: any }
}

export type StringConstant = {
    ClassName: "String",
    Value: string
}

export type NumberConstant = {
    ClassName: "Number",
    Value: number
}

export type NilConstant = {
    ClassName: "Nil",
    Value: nil
}

export type ImportConstant = {
    ClassName: "Import",
    Value: { [number]: StringConstant }
}

export type ClosureConstant = {
    ClassName: "Closure",
    Value: number
}

export type BooleanConstant = {
    ClassName: "Boolean",
    Value: boolean
}

export type Constant = BooleanConstant | ClosureConstant | ImportConstant | NilConstant | NumberConstant | StringConstant | TableConstant | VectorConstant

export type Hexadecimal = {
    ClassName: "Hexadecimal",
    Value: number
}

export type Instruction = {
    ClassName: "Instruction",
    Value: Hexadecimal,
    Code: Hexadecimal,
    OpCode: {
        Index: number,
        Name: string,
        HasAux: boolean
    },
    AuxValue: Hexadecimal?,
    Aux: Instruction?,
    Encodings: {
        A: number,
        B: number,
        C: number,
        D: number,
        E: number
    },
    Context: {
        LineDefined: number,
        Pc: number
    }
}

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
	resize: (BufferReader, newSize: number) -> (),

	ReadVarInt: (BufferReader, shift: boolean?) -> number,
	ReadString: (BufferReader, length: number?, shift: boolean?) -> string,
	ReadBoolean: (BufferReader, shift: boolean?) -> boolean,
	ReadBytes: (BufferReader, size: number, shift: boolean?) -> BufferReader
}

export type Proto = {
    ClassName: "Proto",
    Main: boolean,
    MaxStackSize: number,
    ParameterCount: number,
    UpvalueCount: number,
    IsVararg: number,
    Flags: number?,
    TypeSize: number?,
    SizeTypeInfo: number?,
    TypeInfo: BufferReader?,
    UserdataInfo: {
        TypeSize: number,
        UpvalueCount: number,
        LocalCount: number
    },
    InstructionCount: number,
    Instructions: { [number]: Instruction },
    ConstantCount: number,
    Constants: { [number]: Constant },
    ProtoCount: number,
    Protos: { [number]: Proto },
    LineDefined: number,
    LastLineDefined: number,
    Name: string,
    HasLineInfo: boolean,
    HasDebugInfo: boolean,
    LocalVariableCount: number?,
    LocalVariables: {
        [number]: {
            Name: string,
            StartPc: number,
            EndPc: number,
            Register: number
        }
    }?,
    DebugUpvalueCount: number?,
    Upvalues: { [number]: Upvalue },
}

export type DeserializerConfig = {
    RobloxBytecode: boolean?,
    _stop_key_overwrite_rblx: boolean?,
    EncodingKey: number?,
    PostFinish: (Deserializer: Deserializer) -> ()
}

export type Deserializer = {
    new: (Bytecode: BufferReader, Config: DeserializerConfig) -> Deserializer,
    ReadStringRef: (self: Deserializer) -> string?,
    GetTypeMapping: (self: Deserializer, Name: string, Length: number) -> number,

    ClassName: "Deserializer",
    Source: BufferReader,
    BytecodeVersion: number,
    IsTyped: boolean,
    TypesVersion: number?,
    StringCount: number,
    Strings: { [number]: string },
    UserdataTypeLimit: number,
    UserdataRemapping: { [number]: number },
    ProtoCount: number,
    Protos: { [number]: Proto },
    ProtoEntryPoint: number,
    FunctionCount: number,
    Functions: { [number]: Proto },
    FunctionEntryPoint: number,

    MagicA: number?,
    MagicB: number?,
    Hash: string?
}

export type Iridium = {
    Deserialize: (self: Iridium, Bytecode: string | buffer | BufferReader, Config: DeserializerConfig?) -> Deserializer
}

return nil