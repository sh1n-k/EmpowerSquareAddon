#!/usr/bin/env lua
-- Unit tests for EmpowerSquareLogic (shipped pure domain).

local root = arg[0]:match("(.*/)")
package.path = root .. "../EmpowerSquare/?.lua;" .. package.path

dofile(root .. "../EmpowerSquare/EmpowerSquareLogic.lua")
local Logic = EmpowerSquareLogic

local failures = 0

local function check(name, condition, detail)
    if condition then
        print("  OK  " .. name)
    else
        failures = failures + 1
        print("  FAIL  " .. name .. (detail and (" — " .. detail) or ""))
    end
end

print("EmpowerSquareLogic")

check("clamp mid", Logic.clamp(3, 1, 8) == 3)
check("seconds under 50 become ms", Logic.normalizeDurationMilliseconds(1.5) == 1500)
check("large values stay ms", Logic.normalizeDurationMilliseconds(800) == 800)
check("non-number duration is 0", Logic.normalizeDurationMilliseconds(nil) == 0)

-- Stages: 1s + 1s + 1s (as seconds, each <=50 → *1000)
local durationsSec = {1, 1, 1}
local start = 10000
check("stage1 at start", Logic.getEmpowerStage(start, durationsSec, start) == 1)
check("stage2 mid", Logic.getEmpowerStage(start, durationsSec, start + 1500) == 2)
check("stage3 late", Logic.getEmpowerStage(start, durationsSec, start + 2500) == 3)
check("stage last after all", Logic.getEmpowerStage(start, durationsSec, start + 5000) == 3)
check("nil start → nil stage", Logic.getEmpowerStage(nil, durationsSec, start) == nil)
check("empty durations → nil", Logic.getEmpowerStage(start, {}, start) == nil)

-- ms form (>50)
local durationsMs = {1000, 1000, 1000, 1000}
check("ms stage2", Logic.getEmpowerStage(0, durationsMs, 1500) == 2)
check("ms stage4 at end", Logic.getEmpowerStage(0, durationsMs, 3999) == 4)

local defaults = {1, 2, 3, 4}
local normalized = Logic.normalizeStageColorIndexes({1, 1, 2, 99}, 4, 8, defaults)
check("duplicate stage colors resolved", normalized[1] ~= normalized[2])
check("out of range clamped into palette", normalized[4] >= 1 and normalized[4] <= 8)
check("all unique after normalize", (function()
    local seen = {}
    for _, v in ipairs(normalized) do
        if seen[v] then
            return false
        end
        seen[v] = true
    end
    return true
end)())

check(
    "used by other stage",
    Logic.isColorIndexUsedByOtherStage({1, 2, 3, 4}, 1, 2) == true
)
check(
    "not used by other stage",
    Logic.isColorIndexUsedByOtherStage({1, 2, 3, 4}, 1, 1) == false
)

if failures > 0 then
    print(string.format("%d failure(s)", failures))
    os.exit(1)
end
print("all passed")
