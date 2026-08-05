-- Pure domain helpers for EmpowerSquare (no WoW API dependency).
-- Loaded before EmpowerSquare.lua in-game; dofile()'d by unit tests.

EmpowerSquareLogic = EmpowerSquareLogic or {}
local Logic = EmpowerSquareLogic

function Logic.clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

--- Normalize a raw stage duration to milliseconds.
--- Values > 50 are treated as already-ms (or DurationObject totals in ms);
--- smaller values are treated as seconds.
function Logic.normalizeDurationMilliseconds(rawDuration)
    if type(rawDuration) ~= "number" then
        return 0
    end
    if rawDuration > 50 then
        return rawDuration
    end
    return rawDuration * 1000
end

--- Convert a single stage duration entry (number only in pure path) to ms.
function Logic.stageDurationMilliseconds(durationValue)
    if type(durationValue) == "number" then
        return Logic.normalizeDurationMilliseconds(durationValue)
    end
    return 0
end

--- Resolve current empower stage from start time, per-stage durations, and now.
--- startTimeMs: cast/channel start in ms, or nil if not empowering.
--- durations: array of stage durations (numbers: seconds if <=50, else ms).
--- nowMs: current time in ms.
--- Returns stage index 1..N, or nil when not empowering.
function Logic.getEmpowerStage(startTimeMs, durations, nowMs)
    if not startTimeMs or type(durations) ~= "table" or #durations == 0 then
        return nil
    end

    local elapsedMs = math.max(0, nowMs - startTimeMs)
    local totalMs = 0
    for index, durationValue in ipairs(durations) do
        totalMs = totalMs + Logic.stageDurationMilliseconds(durationValue)
        if elapsedMs < totalMs then
            return index
        end
    end

    return #durations
end

--- Ensure stage color indexes are unique and within 1..paletteSize.
function Logic.normalizeStageColorIndexes(source, stageCount, paletteSize, defaults)
    local normalized = {}
    local used = {}
    source = type(source) == "table" and source or defaults

    for stage = 1, stageCount do
        local requested = tonumber(source[stage]) or defaults[stage] or stage
        requested = Logic.clamp(math.floor(requested + 0.5), 1, paletteSize)

        if not used[requested] then
            normalized[stage] = requested
            used[requested] = true
        else
            for paletteIndex = 1, paletteSize do
                if not used[paletteIndex] then
                    normalized[stage] = paletteIndex
                    used[paletteIndex] = true
                    break
                end
            end
        end
    end

    return normalized
end

function Logic.isColorIndexUsedByOtherStage(stageColorIndexes, stage, colorIndex)
    if type(stageColorIndexes) ~= "table" then
        return false
    end
    for index, usedColorIndex in ipairs(stageColorIndexes) do
        if index ~= stage and usedColorIndex == colorIndex then
            return true
        end
    end
    return false
end

return Logic
