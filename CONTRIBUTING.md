# Contributing to Iridium

Thank you for your interest in contributing to Iridium! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Contributing to Iridium](#contributing-to-iridium)
  - [Table of Contents](#table-of-contents)
  - [Development Environment Setup](#development-environment-setup)
  - [Building Iridium](#building-iridium)
  - [Code Style Guidelines](#code-style-guidelines)
  - [Documentation Guidelines](#documentation-guidelines)
  - [Pull Request Process](#pull-request-process)
  - [Reporting Issues](#reporting-issues)

## Development Environment Setup

1. **Required Tools:**
   - [Git](https://git-scm.com/)
   - [RoKit](https://github.com/rojo-rbx/rokit) - Package manager for Roblox tools

2. **Recommended IDE:**
   - [Visual Studio Code](https://code.visualstudio.com/) with the following extensions:
     - [Luau LSP](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.luau-lsp)
     - [Rojo](https://marketplace.visualstudio.com/items?itemName=evaera.vscode-rojo)
     - [StyLua](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.stylua)

3. **Clone the Repository:**

   ```bash
   git clone https://github.com/ActualMasterOogway/Iridium.git
   cd Iridium
   ```

4. **Install Dependencies:**

   ```bash
   rokit trust rojo-rbx/rojo
   rokit trust lune-org/lune
   rokit trust seaofvoices/darklua
   rokit install
   ```

## Building Iridium

Iridium uses Lune for building. There are several ways to build the project:

1. **Standard Build:**

   ```bash
   lune run Build bundle header=Build/Header.luau
   ```

2. **Minified Build:**

   ```bash
   lune run Build bundle header=Build/Header.luau minify=true
   ```

3. **Build and Run:**

   ```bash
   lune run Build bundle header=Build/Header.luau minify=false ci-mode=true && lune run init.client.luau
   ```

The build output will be placed in the `Distribution` directory, generating:

- `Iridium.luau` - The bundled Luau script
- `Iridium.rbxm` - The Roblox model file

## Code Style Guidelines

Iridium follows a specific code style to maintain consistency across the codebase:

1. **Formatting:**
   - We use [StyLua](https://github.com/JohnnyMorganz/StyLua) for code formatting
   - The project includes a `stylua.toml` configuration file
   - Always run StyLua before submitting a pull request

2. **Naming Conventions:**
   - Use PascalCase for ==EVERYTHING== (e.g., `Proto`, `Deserializer`, `ReadStringRef`, `BytecodeVersion`)

3. **Indentation and Spacing:**
   - Use tabs for indentation
   - Use spaces for alignment
   - Keep lines under 120 characters when possible

4. **Class Structure:**
   - Define the class table and metatable at the top
   - Constructor should be the first method
   - Group related methods together
   - Export type at the bottom of the file

5. **Type Annotations:**
   - Use Luau's type system for all public APIs
   - Include return type annotations
   - Use `nil :: never` pattern for type exports

Example:

```luau
--[=[
	@class MyClass

	Description of what this class does
]=]
local MyClass = {}
MyClass.__index = MyClass

--[=[
	@within MyClass

	Constructor description

	@param Param1 Description of Param1
	@return MyClass
]=]
function MyClass.new(Param1: string): MyClass
	local self = setmetatable({}, MyClass)
	self.ClassName = "MyClass"
    self.Property = Param1

	return self
end

export type MyClass = typeof(MyClass.new(nil :: never))

return MyClass
```

## Documentation Guidelines

Iridium uses a custom documentation format based on Luau Doc:

1. **Class Documentation:**
   - Use `--[=[` and `]=]` for multi-line documentation blocks
   - Document classes with `@class ClassName`
   - Include a brief description of the class

2. **Method Documentation:**
   - Use `@within ClassName` to associate methods with classes
   - Document parameters with `@param ParamName Description`
   - Document return values with `@return Type Description`
   - Use `@tag Constructor` or `@tag Method` when appropriate

3. **Examples:**
   - Include examples in documentation when helpful
   - Use code blocks with ```luau``` and ``` delimiters

4. **Type Documentation:**
   - Document interfaces with `@interface InterfaceName`
   - Document types with descriptions of their purpose

## Pull Request Process

1. **Fork the Repository:**
   - Create a fork of the repository on GitHub
   - Clone your fork locally

2. **Create a Branch:**
   - Create a branch for your feature or bugfix
   - Use a descriptive name (e.g., `feature/new-instruction-support` or `fix/version-detection-bug`)

3. **Make Changes:**
   - Implement your changes following the code style guidelines
   - Add or update tests as necessary
   - Update documentation to reflect your changes

4. **Build and Test:**
   - Ensure the project builds successfully
   - Run tests to verify your changes work as expected

5. **Submit a Pull Request:**
   - Push your changes to your fork
   - Create a pull request to the main repository
   - Provide a clear description of the changes
   - Reference any related issues

6. **Code Review:**
   - Address any feedback from code review
   - Make requested changes and push updates to your branch

## Reporting Issues

If you find a bug or have a feature request, please create an issue on the GitHub repository:

1. **Search Existing Issues:**
   - Check if the issue has already been reported
   - Look for related issues that might provide insight

2. **Create a New Issue:**
   - Use a clear and descriptive title
   - Provide detailed steps to reproduce bugs
   - Include expected behavior and actual behavior
   - Attach screenshots or code samples if relevant
   - Specify the version of Iridium you're using

3. **Issue Labels:**
   - Bug: Something isn't working as expected
   - Enhancement: New feature or request
   - Documentation: Improvements to documentation
   - Question: Request for information

Thank you for contributing to Iridium!
