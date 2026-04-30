export type Upvalue = {
    __type: "Upvalue",
    Name: string
}

export type VectorConstant = {
    __type: "Vector",
    X: number,
    Y: number,
    Z: number,
    W: number,
    Display: string?
}

export type TableConstant = {
    __type: "Table",
    Value: { [number]: Constant },
    Display: string?
}

export type StringConstant = {
    __type: "String",
    Value: buffer,
    Display: string?
}

export type NumberConstant = {
    __type: "Number",
    Value: number,
    Display: string?
}

export type NilConstant = {
    __type: "Nil",
    Value: nil
}

export type ImportConstant = {
    __type: "Import",
    Value: { [number]: StringConstant },
    Display: string?
}

export type ClosureConstant = {
    __type: "Closure",
    Value: number,
    Display: string?
}

export type BooleanConstant = {
    __type: "Boolean",
    Value: boolean
}

export type IntegerConstant = {
    __type: "Integer",
    Value: number,
    IsNegative: boolean,
    Display: string?
}

export type TableWithConstantsPair = {
    Key: Constant,
    Value: Constant?
}

export type TableWithConstantsConstant = {
    __type: "TableWithConstants",
    Value: { [number]: TableWithConstantsPair },
    Display: string?
}

export type Constant =
    BooleanConstant
    | ClosureConstant
    | ImportConstant
    | NilConstant
    | NumberConstant
    | StringConstant
    | TableConstant
    | VectorConstant
    | TableWithConstantsConstant
    | IntegerConstant

export type Hexadecimal = {
    __type: "Hexadecimal",
    Value: number
}

export type Instruction = {
    __type: "Instruction",
    Value: Hexadecimal,
    Code: Hexadecimal,
    OpCodeInfo: {
        Index: number,
        Name: string,
        HasAux: boolean
    },
    AuxValue: Hexadecimal?,
    A: number,
    B: number,
    C: number,
    D: number,
    E: number,
    LineDefined: number,
    Pc: number
}

export type Instructions = {
    __type: "Instructions",
    Count: number,
    [number]: Instruction,
    SetLineInfo: (Instructions, { number }) -> ()
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
	ReadVarInt64: (BufferReader, shift: boolean?) -> number,
	ReadString: (BufferReader, length: number?, shift: boolean?) -> string,
	ReadBoolean: (BufferReader, shift: boolean?) -> boolean,
	ReadBytes: (BufferReader, size: number, shift: boolean?) -> BufferReader
}

export type ParsedType = {
    Byte: number,
    Tag: number,
    IsOptional: boolean,
    Name: string,
    UserdataName: string?
}

export type ParsedLocalType = {
    Byte: number,
    Tag: number,
    IsOptional: boolean,
    Name: string,
    UserdataName: string?,
    Register: number,
    StartPc: number,
    EndPc: number
}

export type FunctionTypeInfo = {
    NumParams: number,
    ParameterTypes: { ParsedType }
}

export type Proto = {
    __type: "Proto",
    Main: boolean,
    MaxStackSize: number,
    ParameterCount: number,
    UpvalueCount: number,
    IsVararg: boolean,
    Flags: number?,
    TypeSize: number?,
    FunctionType: FunctionTypeInfo?,
    UpvalueTypes: { ParsedType },
    LocalTypes: { ParsedLocalType },
    InstructionCount: number,
    Instructions: Instructions,
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
    EncodingKey: number?,
    PostFinish: (Deserializer: Deserializer) -> ()?
}

export type Deserializer = {
    new: (Bytecode: BufferReader, Config: DeserializerConfig) -> Deserializer,
    ReadStringRef: (self: Deserializer) -> string?,

    __type: "Deserializer",
    Source: BufferReader,
    BytecodeVersion: number,
    IsTyped: boolean,
    TypesVersion: number?,
    StringCount: number,
    Strings: { [number]: string },
    UserdataTypeLimit: number,
    UserdataNames: { [number]: string },
    ProtoCount: number,
    Protos: { [number]: Proto },
    ProtoEntryPoint: number,
    FunctionCount: number,
    Functions: { [number]: Proto },
    FunctionEntryPoint: number,

    HasRobloxEnvelope: boolean,
    RobloxTrailerVersion: number?,
    RobloxTrailerSize: number?,

    MagicA: number?,
    MagicB: number?,
    Hash: string?,
    Trailer: string?
}

export type Iridium = {
    Deserialize: (self: Iridium, Bytecode: string | buffer | BufferReader, Config: DeserializerConfig?) -> Deserializer
}

return nil