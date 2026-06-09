-- Runs Iridium against the v10/v11 bytecode fixtures produced by the patched
-- luau-compile (CLASS_SHAPE constants, NEWCLASSMEMBER/CALLFB opcodes, the v11
-- feedback vector). Reports per-file deserialization status and a summary of
-- the new bytecode features that were recovered.

local Iridium = require("@root")
local fs = require("@lune/fs")

local FixtureDir = "Tests/"

local Files = {
    "v10_class_basic",
    "v10_class_methods",
    "v10_class_empty",
    "v10_class_meta",
    "v10_class_typed",
    "v10_class_mixed",
    "v11_callfb",
    "v11_general",
    "v11_modern_syntax",
    "v11_behavioral",
}

local function CountFeatures(Deserializer)
    local ClassShapes, FeedbackSlots, NewClassMembers, CallFbs = 0, 0, 0, 0

    for _, Proto in Deserializer.Protos do
        for _, Constant in Proto.Constants do
            if Constant.__type == "ClassShape" then
                ClassShapes += 1
            end
        end

        FeedbackSlots += #Proto.FeedbackSlots

        for _, Instruction in Proto.Instructions do
            local Name = Instruction.OpCodeInfo.Name

            if Name == "NEWCLASSMEMBER" then
                NewClassMembers += 1
            elseif Name == "CALLFB" then
                CallFbs += 1
            end
        end
    end

    return ClassShapes, NewClassMembers, CallFbs, FeedbackSlots
end

local Pass, Fail = 0, 0

for _, Name in Files do
    local ReadOk, Blob = pcall(fs.readFile, FixtureDir .. Name .. ".luac")

    if not ReadOk then
        print(`SKIP {Name}: {Blob}`)
        continue
    end

    local Ok, Result = pcall(function()
        return Iridium:Deserialize(Blob)
    end)

    if Ok then
        Pass += 1
        local Shapes, Members, Calls, Slots = CountFeatures(Result)
        print(
            `OK   {Name}: v{Result.BytecodeVersion}, {Result.ProtoCount} protos`
                .. ` | class-shapes={Shapes} newclassmember={Members} callfb={Calls} feedback-slots={Slots}`
        )
    else
        Fail += 1
        print(`FAIL {Name}: {Result}`)
    end
end

print(`\n{Pass} passed, {Fail} failed`)
