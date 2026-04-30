# Iridium - Luau Bytecode Deserializer

Iridium is a Luau bytecode deserializer and disassembler written in Luau. It takes compiled bytecode and gives you back the protos, instructions, constants, and type info as plain Luau values you can read directly.

## Description

Iridium parses Luau bytecode versions 3 through 9, including Roblox-flavoured blobs with their MAC-envelope trailer. You get structured access to the proto tree, constant pools, the instruction stream (operands and AUX words included), and the type-info section. Use it for reverse engineering, compiler work, or any tool that needs to read bytecode below the source level.

## Features

- [x] Bytecode Parsing
  - [x] Support for Luau bytecode versions 3-9
  - [x] Typed bytecode support (typesversion 1-3)
  - [x] Encoding-key recovery for opcode-shuffled bytecode
  - [x] Roblox bytecode envelope detection (v0 and v1 trailer formats)

- [x] Function Analysis
  - [x] Function prototype extraction
  - [x] Stack size information
  - [x] Parameter count detection
  - [x] Upvalue tracking
  - [x] Vararg function detection
  - [x] Native-compilation flag inspection

- [x] Instruction Decoding
  - [x] Complete instruction set support
  - [x] Opcode identification
  - [x] Operand extraction (A/B/C/D/E, signed where appropriate)
  - [x] AUX-word handling and instruction flow analysis
  - [x] Lazy decoding via a packed `Instructions` container

- [x] Constant Pool Management
  - [x] Nil constants
  - [x] Boolean constants
  - [x] Number constants
  - [x] String constants
  - [x] Import constants
  - [x] Table constants
  - [x] Closure constants
  - [x] Vector constants
  - [x] TableWithConstants constants
  - [x] Integer constants

- [x] Type System
  - [x] Type version detection
  - [x] Userdata type mapping
  - [x] Type flags parsing
  - [x] Type data parsing
    - [x] Version 1
    - [x] Version 2
    - [x] Version 3

- [x] Debug Info
  - [x] Line information
  - [x] Local-variable scopes
  - [x] Debug names

- [x] Utility Functions
  - [x] String reference resolution
  - [x] Type mapping utilities
  - [x] Hexadecimal conversion

## Usage

```luau
local Iridium, Types = require("Iridium"), require("Iridium/Types")

-- Deserialize bytecode from a string, buffer, or BufferReader
local deserialized = Iridium:Deserialize(bytecodeData)

-- Access function information
local mainFunction = deserialized.Protos[deserialized.ProtoEntryPoint]

-- Inspect instructions (Instructions implements __iter / __index / __len,
-- so iteration and indexing work like a 1-indexed array)
for pc, instruction in mainFunction.Instructions do
    print(pc, instruction.OpCodeInfo.Name, instruction.A, instruction.B, instruction.C)
end

-- Access constants
for i, constant in mainFunction.Constants do
    print(constant.__type, constant)
end

-- Roblox bytecode envelope (when present)
if deserialized.HasRobloxEnvelope then
    print("Roblox trailer v" .. deserialized.RobloxTrailerVersion)
end
```

For advanced usage I'd suggest checking [this example](main.client.luau) out

## Building from Source

Click [here](CONTRIBUTING.md#development-environment-setup).

## Contributing

Contributions are welcome! [Feel free to submit issues or pull requests to help improve Iridium.](CONTRIBUTING.md#pull-request-process)

## Authors

- ActualMasterOogway - Creator and main developer

## Acknowledgements

- [atrexus](https://github.com/atrexus/) - [Unluau](https://github.com/atrexus/unluau/tree/archive/) was a really helpful resource
- [lovre](https://github.com/lovrewe/) - [Platinum](https://github.com/Lovreware/Platinum) helped me find where I was underreading/overreading
- [GRH](https://github.com/grh-official/) - Helped me reading line information correctly ❤
