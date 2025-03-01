-- https://github.com/luau-lang/luau/blob/master/Common/include/Luau/Bytecode.h
-- https://github.com/Lovreware/Platinum/blob/main/deserializer/luau/spec.luau

export type OpCodeInfo = { Index: number, Name: string, HasAux: boolean }

local LuauOpcode = {
    -- NOP: noop
    LOP_NOP = { Index = 0, Name = "NOP", HasAux = false },

    -- BREAK: debugger break
    LOP_BREAK = { Index = 1, Name = "BREAK", HasAux = false },

    -- LOADNIL: sets register to nil
    -- A: target register
    LOP_LOADNIL = { Index = 2, Name = "LOADNIL", HasAux = false },

    -- LOADB: sets register to boolean and jumps to a given short offset (used to compile comparison results into a boolean)
    -- A: target register
    -- B: value (0/1)
    -- C: jump offset
    LOP_LOADB = { Index = 3, Name = "LOADB", HasAux = false },

    -- LOADN: sets register to a number literal
    -- A: target register
    -- D: value (-32768..32767)
    LOP_LOADN = { Index = 4, Name = "LOADN", HasAux = false },

    -- LOADK: sets register to an entry from the constant table from the proto (number/vector/string)
    -- A: target register
    -- D: constant table index (0..32767)
    LOP_LOADK = { Index = 5, Name = "LOADK", HasAux = false },

    -- MOVE: move (copy) value from one register to another
    -- A: target register
    -- B: source register
    LOP_MOVE = { Index = 6, Name = "MOVE", HasAux = false },

    -- GETGLOBAL: load value from global table using constant string as a key
    -- A: target register
    -- C: predicted slot index (based on hash)
    -- AUX: constant table index
    LOP_GETGLOBAL = { Index = 7, Name = "GETGLOBAL", HasAux = true },

    -- SETGLOBAL: set value in global table using constant string as a key
    -- A: source register
    -- C: predicted slot index (based on hash)
    -- AUX: constant table index
    LOP_SETGLOBAL = { Index = 8, Name = "SETGLOBAL", HasAux = true },

    -- GETUPVAL: load upvalue from the upvalue table for the current function
    -- A: target register
    -- B: upvalue index
    LOP_GETUPVAL = { Index = 9, Name = "GETUPVAL", HasAux = false },

    -- SETUPVAL: store value into the upvalue table for the current function
    -- A: target register
    -- B: upvalue index
    LOP_SETUPVAL = { Index = 10, Name = "SETUPVAL", HasAux = false },

    -- CLOSEUPVALS: close (migrate to heap) all upvalues that were captured for registers >= target
    -- A: target register
    LOP_CLOSEUPVALS = { Index = 11, Name = "CLOSEUPVALS", HasAux = false },

    -- GETIMPORT: load imported global table global from the constant table
    -- A: target register
    -- D: constant table index (0..32767); we assume that imports are loaded into the constant table
    -- AUX: 3 10-bit indices of constant strings that, combined, constitute an import path; length of the path is set by the top 2 bits (1,2,3)
    LOP_GETIMPORT = { Index = 12, Name = "GETIMPORT", HasAux = true },

    -- GETTABLE: load value from table into target register using key from register
    -- A: target register
    -- B: table register
    -- C: index register
    LOP_GETTABLE = { Index = 13, Name = "GETTABLE", HasAux = false },

    -- SETTABLE: store source register into table using key from register
    -- A: source register
    -- B: table register
    -- C: index register
    LOP_SETTABLE = { Index = 14, Name = "SETTABLE", HasAux = false },

    -- GETTABLEKS: load value from table into target register using constant string as a key
    -- A: target register
    -- B: table register
    -- C: predicted slot index (based on hash)
    -- AUX: constant table index
    LOP_GETTABLEKS = { Index = 15, Name = "GETTABLEKS", HasAux = true },

    -- SETTABLEKS: store source register into table using constant string as a key
    -- A: source register
    -- B: table register
    -- C: predicted slot index (based on hash)
    -- AUX: constant table index
    LOP_SETTABLEKS = { Index = 16, Name = "SETTABLEKS", HasAux = true },

    -- GETTABLEN: load value from table into target register using small integer index as a key
    -- A: target register
    -- B: table register
    -- C: index-1 (index is 1..256)
    LOP_GETTABLEN = { Index = 17, Name = "GETTABLEN", HasAux = false },

    -- SETTABLEN: store source register into table using small integer index as a key
    -- A: source register
    -- B: table register
    -- C: index-1 (index is 1..256)
    LOP_SETTABLEN = { Index = 18, Name = "SETTABLEN", HasAux = false },

    -- NEWCLOSURE: create closure from a child proto; followed by a CAPTURE instruction for each upvalue
    -- A: target register
    -- D: child proto index (0..32767)
    LOP_NEWCLOSURE = { Index = 19, Name = "NEWCLOSURE", HasAux = false },

    -- NAMECALL: prepare to call specified method by name by loading function from source register using constant index into target register and copying source register into target register + 1
    -- A: target register
    -- B: source register
    -- C: predicted slot index (based on hash)
    -- AUX: constant table index
    -- Note that this instruction must be followed directly by CALL; it prepares the arguments
    -- This instruction is roughly equivalent to GETTABLEKS + MOVE pair, but we need a special instruction to support custom __namecall metamethod
    LOP_NAMECALL = { Index = 20, Name = "NAMECALL", HasAux = true },

    -- CALL: call specified function
    -- A: register where the function object lives, followed by arguments; results are placed starting from the same register
    -- B: argument count + 1, or 0 to preserve all arguments up to top (MULTRET)
    -- C: result count + 1, or 0 to preserve all values and adjust top (MULTRET)
    LOP_CALL = { Index = 21, Name = "CALL", HasAux = false },

    -- RETURN: returns specified values from the function
    -- A: register where the returned values start
    -- B: number of returned values + 1, or 0 to return all values up to top (MULTRET)
    LOP_RETURN = { Index = 22, Name = "RETURN", HasAux = false },

    -- JUMP: jumps to target offset
    -- D: jump offset (-32768..32767; 0 means "next instruction" aka "don't jump")
    LOP_JUMP = { Index = 23, Name = "JUMP", HasAux = false },

    -- JUMPBACK: jumps to target offset; this is equivalent to JUMP but is used as a safepoint to be able to interrupt while/repeat loops
    -- D: jump offset (-32768..32767; 0 means "next instruction" aka "don't jump")
    LOP_JUMPBACK = { Index = 24, Name = "JUMPBACK", HasAux = false },

    -- JUMPIF: jumps to target offset if register is not nil/false
    -- A: source register
    -- D: jump offset (-32768..32767; 0 means "next instruction" aka "don't jump")
    LOP_JUMPIF = { Index = 25, Name = "JUMPIF", HasAux = false },

    -- JUMPIFNOT: jumps to target offset if register is nil/false
    -- A: source register
    -- D: jump offset (-32768..32767; 0 means "next instruction" aka "don't jump")
    LOP_JUMPIFNOT = { Index = 26, Name = "JUMPIFNOT", HasAux = false },

    -- JUMPIFEQ, JUMPIFLE, JUMPIFLT, JUMPIFNOTEQ, JUMPIFNOTLE, JUMPIFNOTLT: jumps to target offset if the comparison is true (or false, for NOT variants)
    -- A: source register 1
    -- D: jump offset (-32768..32767; 1 means "next instruction" aka "don't jump")
    -- AUX: source register 2
    LOP_JUMPIFEQ = { Index = 27, Name = "JUMPIFEQ", HasAux = true },
    LOP_JUMPIFLE = { Index = 28, Name = "JUMPIFLE", HasAux = true },
    LOP_JUMPIFLT = { Index = 29, Name = "JUMPIFLT", HasAux = true },
    LOP_JUMPIFNOTEQ = { Index = 30, Name = "JUMPIFNOTEQ", HasAux = true },
    LOP_JUMPIFNOTLE = { Index = 31, Name = "JUMPIFNOTLE", HasAux = true },
    LOP_JUMPIFNOTLT = { Index = 32, Name = "JUMPIFNOTLT", HasAux = true },

    -- ADD, SUB, MUL, DIV, MOD, POW: compute arithmetic operation between two source registers and put the result into target register
    -- A: target register
    -- B: source register 1
    -- C: source register 2
    LOP_ADD = { Index = 33, Name = "ADD", HasAux = false },
    LOP_SUB = { Index = 34, Name = "SUB", HasAux = false },
    LOP_MUL = { Index = 35, Name = "MUL", HasAux = false },
    LOP_DIV = { Index = 36, Name = "DIV", HasAux = false },
    LOP_MOD = { Index = 37, Name = "MOD", HasAux = false },
    LOP_POW = { Index = 38, Name = "POW", HasAux = false },

    -- ADDK, SUBK, MULK, DIVK, MODK, POWK: compute arithmetic operation between the source register and a constant and put the result into target register
    -- A: target register
    -- B: source register
    -- C: constant table index (0..255); must refer to a number
    LOP_ADDK = { Index = 39, Name = "ADDK", HasAux = false },
    LOP_SUBK = { Index = 40, Name = "SUBK", HasAux = false },
    LOP_MULK = { Index = 41, Name = "MULK", HasAux = false },
    LOP_DIVK = { Index = 42, Name = "DIVK", HasAux = false },
    LOP_MODK = { Index = 43, Name = "MODK", HasAux = false },
    LOP_POWK = { Index = 44, Name = "POWK", HasAux = false },

    -- AND, OR: perform `and` or `or` operation (selecting first or second register based on whether the first one is truthy) and put the result into target register
    -- A: target register
    -- B: source register 1
    -- C: source register 2
    LOP_AND = { Index = 45, Name = "AND", HasAux = false },
    LOP_OR = { Index = 46, Name = "OR", HasAux = false },

    -- ANDK, ORK: perform `and` or `or` operation (selecting source register or constant based on whether the source register is truthy) and put the result into target register
    -- A: target register
    -- B: source register
    -- C: constant table index (0..255)
    LOP_ANDK = { Index = 47, Name = "ANDK", HasAux = false },
    LOP_ORK = { Index = 48, Name = "ORK", HasAux = false },

    -- CONCAT: concatenate all strings between B and C (inclusive) and put the result into A
    -- A: target register
    -- B: source register start
    -- C: source register end
    LOP_CONCAT = { Index = 49, Name = "CONCAT", HasAux = false },

    -- NOT, MINUS, LENGTH: compute unary operation for source register and put the result into target register
    -- A: target register
    -- B: source register
    LOP_NOT = { Index = 50, Name = "NOT", HasAux = false },
    LOP_MINUS = { Index = 51, Name = "MINUS", HasAux = false },
    LOP_LENGTH = { Index = 52, Name = "LENGTH", HasAux = false },

    -- NEWTABLE: create table in target register
    -- A: target register
    -- B: table size, stored as 0 for v=0 and ceil(log2(v))+1 for v!=0
    -- AUX: array size
    LOP_NEWTABLE = { Index = 53, Name = "NEWTABLE", HasAux = true },

    -- DUPTABLE: duplicate table using the constant table template to target register
    -- A: target register
    -- D: constant table index (0..32767)
    LOP_DUPTABLE = { Index = 54, Name = "DUPTABLE", HasAux = false },

    -- SETLIST: set a list of values to table in target register
    -- A: target register
    -- B: source register start
    -- C: value count + 1, or 0 to use all values up to top (MULTRET)
    -- AUX: table index to start from
    LOP_SETLIST = { Index = 55, Name = "SETLIST", HasAux = true },

    -- FORNPREP: prepare a numeric for loop, jump over the loop if first iteration doesn't need to run
    -- A: target register; numeric for loops assume a register layout [limit, step, index, variable]
    -- D: jump offset (-32768..32767)
    -- limit/step are immutable, index isn't visible to user code since it's copied into variable
    LOP_FORNPREP = { Index = 56, Name = "FORNPREP", HasAux = false },

    -- FORNLOOP: adjust loop variables for one iteration, jump back to the loop header if loop needs to continue
    -- A: target register; see FORNPREP for register layout
    -- D: jump offset (-32768..32767)
    LOP_FORNLOOP = { Index = 57, Name = "FORNLOOP", HasAux = false },

    -- FORGLOOP: adjust loop variables for one iteration of a generic for loop, jump back to the loop header if loop needs to continue
    -- A: target register; generic for loops assume a register layout [generator, state, index, variables...]
    -- D: jump offset (-32768..32767)
    -- AUX: variable count (1..255) in the low 8 bits, high bit indicates whether to use ipairs-style traversal in the fast path
    -- loop variables are adjusted by calling generator(state, index) and expecting it to return a tuple that's copied to the user variables
    -- the first variable is then copied into index; generator/state are immutable, index isn't visible to user code
    LOP_FORGLOOP = { Index = 58, Name = "FORGLOOP", HasAux = true },

    -- FORGPREP_INEXT: prepare FORGLOOP with 2 output variables (no AUX encoding), assuming generator is luaB_inext, and jump to FORGLOOP
    -- A: target register (see FORGLOOP for register layout)
    LOP_FORGPREP_INEXT = { Index = 59, Name = "FORGPREP_INEXT", HasAux = false },

    -- FASTCALL3: perform a fast call of a built-in function using 3 register arguments
    -- A: builtin function id (see LuauBuiltinFunction)
    -- B: source argument register
    -- C: jump offset to get to following CALL
    -- AUX: source register 2 in least-significant byte
    -- AUX: source register 3 in second least-significant byte
    LOP_FASTCALL3 = { Index = 60, Name = "FASTCALL3", HasAux = true },

    -- FORGPREP_NEXT: prepare FORGLOOP with 2 output variables (no AUX encoding), assuming generator is luaB_next, and jump to FORGLOOP
    -- A: target register (see FORGLOOP for register layout)
    LOP_FORGPREP_NEXT = { Index = 61, Name = "FORGPREP_NEXT", HasAux = false },

    -- NATIVECALL: start executing new function in native code
    -- this is a pseudo-instruction that is never emitted by bytecode compiler, but can be constructed at runtime to accelerate native code dispatch
    LOP_NATIVECALL = { Index = 62, Name = "NATIVECALL", HasAux = false },

    -- GETVARARGS: copy variables into the target register from vararg storage for current function
    -- A: target register
    -- B: variable count + 1, or 0 to copy all variables and adjust top (MULTRET)
    LOP_GETVARARGS = { Index = 63, Name = "GETVARARGS", HasAux = false },

    -- DUPCLOSURE: create closure from a pre-created function object (reusing it unless environments diverge)
    -- A: target register
    -- D: constant table index (0..32767)
    LOP_DUPCLOSURE = { Index = 64, Name = "DUPCLOSURE", HasAux = false },

    -- PREPVARARGS: prepare stack for variadic functions so that GETVARARGS works correctly
    -- A: number of fixed arguments
    LOP_PREPVARARGS = { Index = 65, Name = "PREPVARARGS", HasAux = false },

    -- LOADKX: sets register to an entry from the constant table from the proto (number/string)
    -- A: target register
    -- AUX: constant table index
    LOP_LOADKX = { Index = 66, Name = "LOADKX", HasAux = true },

    -- JUMPX: jumps to the target offset; like JUMPBACK, supports interruption
    -- E: jump offset (-2^23..2^23; 0 means "next instruction" aka "don't jump")
    LOP_JUMPX = { Index = 67, Name = "JUMPX", HasAux = false },

    -- FASTCALL: perform a fast call of a built-in function
    -- A: builtin function id (see LuauBuiltinFunction)
    -- C: jump offset to get to following CALL
    -- FASTCALL is followed by one of (GETIMPORT, MOVE, GETUPVAL) instructions and by CALL instruction
    -- This is necessary so that if FASTCALL can't perform the call inline, it can continue normal execution
    -- If FASTCALL *can* perform the call, it jumps over the instructions *and* over the next CALL
    -- Note that FASTCALL will read the actual call arguments, such as argument/result registers and counts, from the CALL instruction
    LOP_FASTCALL = { Index = 68, Name = "FASTCALL", HasAux = false },

    -- COVERAGE: update coverage information stored in the instruction
    -- E: hit count for the instruction (0..2^23-1)
    -- The hit count is incremented by VM every time the instruction is executed, and saturates at 2^23-1
    LOP_COVERAGE = { Index = 69, Name = "COVERAGE", HasAux = false },

    -- CAPTURE: capture a local or an upvalue as an upvalue into a newly created closure; only valid after NEWCLOSURE
    -- A: capture type, see LuauCaptureType
    -- B: source register (for VAL/REF) or upvalue index (for UPVAL/UPREF)
    LOP_CAPTURE = { Index = 70, Name = "CAPTURE", HasAux = false },

    -- SUBRK, DIVRK: compute arithmetic operation between the constant and a source register and put the result into target register
    -- A: target register
    -- B: constant table index (0..255); must refer to a number
    -- C: source register
    LOP_SUBRK = { Index = 71, Name = "SUBRK", HasAux = false },
    LOP_DIVRK = { Index = 72, Name = "DIVRK", HasAux = false },

    -- FASTCALL1: perform a fast call of a built-in function using 1 register argument
    -- A: builtin function id (see LuauBuiltinFunction)
    -- B: source argument register
    -- C: jump offset to get to following CALL
    LOP_FASTCALL1 = { Index = 73, Name = "FASTCALL1", HasAux = false },

    -- FASTCALL2: perform a fast call of a built-in function using 2 register arguments
    -- A: builtin function id (see LuauBuiltinFunction)
    -- B: source argument register
    -- C: jump offset to get to following CALL
    -- AUX: source register 2 in least-significant byte
    LOP_FASTCALL2 = { Index = 74, Name = "FASTCALL2", HasAux = true },

    -- FASTCALL2K: perform a fast call of a built-in function using 1 register argument and 1 constant argument
    -- A: builtin function id (see LuauBuiltinFunction)
    -- B: source argument register
    -- C: jump offset to get to following CALL
    -- AUX: constant index
    LOP_FASTCALL2K = { Index = 75, Name = "FASTCALL2K", HasAux = true },

    -- FORGPREP: prepare loop variables for a generic for loop, jump to the loop backedge unconditionally
    -- A: target register; generic for loops assume a register layout [generator, state, index, variables...]
    -- D: jump offset (-32768..32767)
    LOP_FORGPREP = { Index = 76, Name = "FORGPREP", HasAux = false },

    -- JUMPXEQKNIL, JUMPXEQKB: jumps to target offset if the comparison with constant is true (or false, see AUX)
    -- A: source register 1
    -- D: jump offset (-32768..32767; 1 means "next instruction" aka "don't jump")
    -- AUX: constant value (for boolean) in low bit, NOT flag (that flips comparison result) in high bit
    LOP_JUMPXEQKNIL = { Index = 77, Name = "JUMPXEQKNIL", HasAux = true },
    LOP_JUMPXEQKB = { Index = 78, Name = "JUMPXEQKB", HasAux = true },

    -- JUMPXEQKN, JUMPXEQKS: jumps to target offset if the comparison with constant is true (or false, see AUX)
    -- A: source register 1
    -- D: jump offset (-32768..32767; 1 means "next instruction" aka "don't jump")
    -- AUX: constant table index in low 24 bits, NOT flag (that flips comparison result) in high bit
    LOP_JUMPXEQKN = { Index = 79, Name = "JUMPXEQKN", HasAux = true },
    LOP_JUMPXEQKS = { Index = 80, Name = "JUMPXEQKS", HasAux = true },

    -- IDIV: compute floor division between two source registers and put the result into target register
    -- A: target register
    -- B: source register 1
    -- C: source register 2
    LOP_IDIV = { Index = 81, Name = "IDIV", HasAux = false },

    -- IDIVK compute floor division between the source register and a constant and put the result into target register
    -- A: target register
    -- B: source register
    -- C: constant table index (0..255)
    LOP_IDIVK = { Index = 82, Name = "IDIVK", HasAux = false },

    -- Enum entry for number of opcodes, not a valid opcode by itself!
    LOP__COUNT = { Index = 83, Name = "_COUNT", HasAux = false },
}

local LuauBytecodeTag = {
    LBC_VERSION_MIN = 3,
    LBC_VERSION_MAX = 6,

    LBC_TYPE_VERSION_MIN = 1,
    LBC_TYPE_VERSION_MAX = 3,
}

local LuauBytecodeConstants = {
    LBC_CONSTANT_NIL = 0,
    LBC_CONSTANT_BOOLEAN = 1,
    LBC_CONSTANT_NUMBER = 2,
    LBC_CONSTANT_STRING = 3,
    LBC_CONSTANT_IMPORT = 4,
    LBC_CONSTANT_TABLE = 5,
    LBC_CONSTANT_CLOSURE = 6,
    LBC_CONSTANT_VECTOR = 7,
}

local LuauBytecodeType = {
    LBC_TYPE_NIL = 0,
    LBC_TYPE_BOOLEAN = 1,
    LBC_TYPE_NUMBER = 2,
    LBC_TYPE_STRING = 3,
    LBC_TYPE_TABLE = 4,
    LBC_TYPE_FUNCTION = 5,
    LBC_TYPE_THREAD = 6,
    LBC_TYPE_USERDATA = 7,
    LBC_TYPE_VECTOR = 8,
    LBC_TYPE_BUFFER = 9,

    LBC_TYPE_ANY = 15,

    LBC_TYPE_TAGGED_USERDATA_BASE = 64,
    LBC_TYPE_TAGGED_USERDATA_END = 64 + 32,

    LBC_TYPE_OPTIONAL_BIT = bit32.lshift(1, 7),

    LBC_TYPE_INVALID = 256,
}

local LuauBuiltinFunction = {
    LBF_NONE = 0,

    -- assert()
    LBF_ASSERT = 1,

    -- math.
    LBF_MATH_ABS = 2,
    LBF_MATH_ACOS = 3,
    LBF_MATH_ASIN = 4,
    LBF_MATH_ATAN2 = 5,
    LBF_MATH_ATAN = 6,
    LBF_MATH_CEIL = 7,
    LBF_MATH_COSH = 8,
    LBF_MATH_COS = 9,
    LBF_MATH_DEG = 10,
    LBF_MATH_EXP = 11,
    LBF_MATH_FLOOR = 12,
    LBF_MATH_FMOD = 13,
    LBF_MATH_FREXP = 14,
    LBF_MATH_LDEXP = 15,
    LBF_MATH_LOG10 = 16,
    LBF_MATH_LOG = 17,
    LBF_MATH_MAX = 18,
    LBF_MATH_MIN = 19,
    LBF_MATH_MODF = 20,
    LBF_MATH_POW = 21,
    LBF_MATH_RAD = 22,
    LBF_MATH_SINH = 23,
    LBF_MATH_SIN = 24,
    LBF_MATH_SQRT = 25,
    LBF_MATH_TANH = 26,
    LBF_MATH_TAN = 27,

    -- bit32.
    LBF_BIT32_ARSHIFT = 28,
    LBF_BIT32_BAND = 29,
    LBF_BIT32_BNOT = 30,
    LBF_BIT32_BOR = 31,
    LBF_BIT32_BXOR = 32,
    LBF_BIT32_BTEST = 33,
    LBF_BIT32_EXTRACT = 34,
    LBF_BIT32_LROTATE = 35,
    LBF_BIT32_LSHIFT = 36,
    LBF_BIT32_REPLACE = 37,
    LBF_BIT32_RROTATE = 38,
    LBF_BIT32_RSHIFT = 39,

    -- type()
    LBF_TYPE = 40,

    -- string.
    LBF_STRING_BYTE = 41,
    LBF_STRING_CHAR = 42,
    LBF_STRING_LEN = 43,

    -- typeof()
    LBF_TYPEOF = 44,

    -- string.
    LBF_STRING_SUB = 45,

    -- math.
    LBF_MATH_CLAMP = 46,
    LBF_MATH_SIGN = 47,
    LBF_MATH_ROUND = 48,

    -- raw*
    LBF_RAWSET = 49,
    LBF_RAWGET = 50,
    LBF_RAWEQUAL = 51,

    -- table.
    LBF_TABLE_INSERT = 52,
    LBF_TABLE_UNPACK = 53,

    -- vector ctor
    LBF_VECTOR = 54,

    -- bit32.count
    LBF_BIT32_COUNTLZ = 55,
    LBF_BIT32_COUNTRZ = 56,

    -- select(_, ...)
    LBF_SELECT_VARARG = 57,

    -- rawlen
    LBF_RAWLEN = 58,

    -- bit32.extract(_, k, k)
    LBF_BIT32_EXTRACTK = 59,

    -- get/setmetatable
    LBF_GETMETATABLE = 60,
    LBF_SETMETATABLE = 61,

    -- tonumber/tostring
    LBF_TONUMBER = 62,
    LBF_TOSTRING = 63,

    -- bit32.byteswap(n)
    LBF_BIT32_BYTESWAP = 64,

    -- buffer.
    LBF_BUFFER_READI8 = 65,
    LBF_BUFFER_READU8 = 66,
    LBF_BUFFER_WRITEU8 = 67,
    LBF_BUFFER_READI16 = 68,
    LBF_BUFFER_READU16 = 69,
    LBF_BUFFER_WRITEU16 = 70,
    LBF_BUFFER_READI32 = 71,
    LBF_BUFFER_READU32 = 72,
    LBF_BUFFER_WRITEU32 = 73,
    LBF_BUFFER_READF32 = 74,
    LBF_BUFFER_WRITEF32 = 75,
    LBF_BUFFER_READF64 = 76,
    LBF_BUFFER_WRITEF64 = 77,

    -- vector.
    LBF_VECTOR_MAGNITUDE = 78,
    LBF_VECTOR_NORMALIZE = 79,
    LBF_VECTOR_CROSS = 80,
    LBF_VECTOR_DOT = 81,
    LBF_VECTOR_FLOOR = 82,
    LBF_VECTOR_CEIL = 83,
    LBF_VECTOR_ABS = 84,
    LBF_VECTOR_SIGN = 85,
    LBF_VECTOR_CLAMP = 86,
    LBF_VECTOR_MIN = 87,
    LBF_VECTOR_MAX = 88,

    -- math.lerp
    LBF_MATH_LERP = 89,
}

local LuauCaptureType = {
    LCT_VAL = 0,
    LCT_REF = 2,
    LCT_UPVAL = 3,
}

local LuauProtoFlag = {
    -- used to tag main proto for modules with --!native
    LPF_NATIVE_MODULE = bit32.lshift(1, 0),
    -- used to tag individual protos as not profitable to compile natively
    LPF_NATIVE_COLD = bit32.lshift(1, 1),
    -- used to tag main proto for modules that have at least one function with native attribute
    LPF_NATIVE_FUNCTION = bit32.lshift(1, 2),
}

return {
    LuauOpcode = table.freeze(LuauOpcode),
    LuauBytecodeTag = table.freeze(LuauBytecodeTag),
    LuauBytecodeConstants = table.freeze(LuauBytecodeConstants),
    LuauBytecodeType = table.freeze(LuauBytecodeType),
    LuauBuiltinFunction = table.freeze(LuauBuiltinFunction),
    LuauCaptureType = table.freeze(LuauCaptureType),
    LuauProtoFlag = table.freeze(LuauProtoFlag)
}