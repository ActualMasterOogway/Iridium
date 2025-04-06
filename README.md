# Iridium - Luau Bytecode Deserializer

Iridium is a powerful Luau bytecode deserializer and disassembler written in Luau itself. It allows you to analyze, inspect, and understand compiled Luau bytecode by breaking it down into its constituent components.

## Description

Iridium provides a comprehensive toolkit for working with Luau bytecode. It can parse bytecode from various Luau versions (3-6) and extract detailed information about functions, constants, instructions, and more. This makes it an invaluable tool for reverse engineering, debugging, and understanding how Luau code is executed at a low level.

## Features

- [x] Bytecode Parsing
  - [x] Support for Luau bytecode versions 3-6
  - [x] Typed bytecode support (version 4-6)
  - [x] Complete bytecode structure analysis

- [x] Function Analysis
  - [x] Function prototype extraction
  - [x] Stack size information
  - [x] Parameter count detection
  - [x] Upvalue tracking
  - [x] Vararg function detection

- [x] Instruction Decoding
  - [x] Complete instruction set support
  - [x] Opcode identification
  - [x] Operand extraction
  - [x] Instruction flow analysis

- [x] Constant Pool Management
  - [x] String constants
  - [x] Number constants
  - [x] Boolean constants
  - [x] Table constants
  - [x] Vector constants
  - [x] Nil constants
  - [x] Closure constants
  - [x] Import constants

- [ ] Type System
  - [x] Type version detection
  - [ ] Userdata type mapping
  - [x] Type flags parsing
  - [x] Type data parsing
    - [x] Version 1
    - [x] Version 2
    - [x] Version 3

- [x] Debug Info
  - [x] Line information
  - [x] Debug name

- [x] Utility Functions
  - [x] String reference resolution
  - [x] Type mapping utilities
  - [x] Hexadecimal conversion

## Usage

```luau
local Iridium, Types = require("Iridium"), require("Iridium/Types")

-- Deserialize bytecode from a string or buffer
local deserialized = Iridium:Deserialize(bytecodeData)

-- Access function information
local mainFunction = deserialized.Protos[deserialized.ProtoEntryPoint]

-- Inspect instructions
for i, instruction in ipairs(mainFunction.Instructions) do
    print(instruction.Code, instruction.Operands.A, instruction.Operands.B, instruction.Operands.C)
end

-- Access constants
for i, constant in ipairs(mainFunction.Constants) do
    print(constant.ClassName, constant)
end
```

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
