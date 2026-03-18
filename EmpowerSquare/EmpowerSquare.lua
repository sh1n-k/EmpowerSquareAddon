local addonName = ...

local defaults = {
    size = 96,
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
    locked = true,
}

local DEFAULT_STAGE_COLOR_INDEXES = {1, 2, 3, 4}

local state = {
    currentStage = nil,
    optionsOpen = false,
}

local COLOR_PALETTE = {
    {name = "Green", rgba = {0.0, 1.0, 0.0, 1.0}},
    {name = "Yellow", rgba = {1.0, 1.0, 0.0, 1.0}},
    {name = "Orange", rgba = {1.0, 0.5, 0.0, 1.0}},
    {name = "Red", rgba = {1.0, 0.0, 0.0, 1.0}},
    {name = "Cyan", rgba = {0.0, 1.0, 1.0, 1.0}},
    {name = "Blue", rgba = {0.0, 0.45, 1.0, 1.0}},
    {name = "Purple", rgba = {0.7, 0.2, 1.0, 1.0}},
    {name = "White", rgba = {1.0, 1.0, 1.0, 1.0}},
}

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

local function copyDefaults(target, source)
    for key, value in pairs(source) do
        if target[key] == nil then
            target[key] = value
        end
    end
end

local addon = CreateFrame("Frame")
addon:RegisterEvent("ADDON_LOADED")

local square = CreateFrame("Frame", "EmpowerSquareIndicator", UIParent, "BackdropTemplate")
square:SetMovable(true)
square:SetClampedToScreen(true)
square:EnableMouse(false)
square:RegisterForDrag("LeftButton")
square:SetFrameStrata("FULLSCREEN_DIALOG")
square:SetFrameLevel(100)
square:SetBackdrop({
    bgFile = "Interface/Buttons/WHITE8X8",
    edgeFile = "Interface/Buttons/WHITE8X8",
    edgeSize = 2,
})
square:SetBackdropColor(0, 1, 0, 1)
square:SetBackdropBorderColor(0.05, 0.05, 0.05, 0.95)
square:Hide()

local label = square:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
label:SetPoint("BOTTOM", square, "TOP", 0, 6)
label:SetText("STAGE 1")
label:SetTextColor(0, 0, 0, 0.85)

local options
local sizeSlider
local xSlider
local ySlider
local lockCheck
local sizeInput
local xInput
local yInput
local stageColorDropdowns = {}
local controlId = 0

local function db()
    return EmpowerSquareDB
end

local function copyArray(source)
    local target = {}
    for index, value in ipairs(source) do
        target[index] = value
    end
    return target
end

local function getStageColorIndex(stage)
    local settings = db()
    if not settings or type(settings.stageColorIndexes) ~= "table" then
        return DEFAULT_STAGE_COLOR_INDEXES[math.min(stage or 1, #DEFAULT_STAGE_COLOR_INDEXES)]
    end
    return settings.stageColorIndexes[math.min(stage or 1, #DEFAULT_STAGE_COLOR_INDEXES)]
end

local function getColorName(index)
    local choice = COLOR_PALETTE[index]
    return choice and choice.name or "Unknown"
end

local function getStageColor(stage)
    local paletteIndex = getStageColorIndex(stage)
    local choice = COLOR_PALETTE[paletteIndex] or COLOR_PALETTE[DEFAULT_STAGE_COLOR_INDEXES[math.min(stage or 1, #DEFAULT_STAGE_COLOR_INDEXES)]]
    return unpack(choice.rgba)
end

local function isColorIndexUsedByOtherStage(stage, colorIndex)
    local settings = db()
    if not settings or type(settings.stageColorIndexes) ~= "table" then
        return false
    end

    for index, usedColorIndex in ipairs(settings.stageColorIndexes) do
        if index ~= stage and usedColorIndex == colorIndex then
            return true
        end
    end

    return false
end

local function normalizeStageColorIndexes(settings)
    local source = type(settings.stageColorIndexes) == "table" and settings.stageColorIndexes or DEFAULT_STAGE_COLOR_INDEXES
    local normalized = {}
    local used = {}

    for stage = 1, #DEFAULT_STAGE_COLOR_INDEXES do
        local requested = tonumber(source[stage]) or DEFAULT_STAGE_COLOR_INDEXES[stage]
        requested = clamp(math.floor(requested + 0.5), 1, #COLOR_PALETTE)

        if not used[requested] then
            normalized[stage] = requested
            used[requested] = true
        else
            for paletteIndex = 1, #COLOR_PALETTE do
                if not used[paletteIndex] then
                    normalized[stage] = paletteIndex
                    used[paletteIndex] = true
                    break
                end
            end
        end
    end

    settings.stageColorIndexes = normalized
end

local function updateStageColorDropdowns()
    if not options then
        return
    end

    for stage = 1, #DEFAULT_STAGE_COLOR_INDEXES do
        local dropdown = stageColorDropdowns[stage]
        if dropdown then
            local paletteIndex = getStageColorIndex(stage)
            UIDropDownMenu_SetSelectedValue(dropdown, paletteIndex)
            UIDropDownMenu_SetText(dropdown, getColorName(paletteIndex))
        end
    end
end

local function getEmpowerTiming()
    local durations = {UnitEmpoweredStageDurations("player")}
    if #durations == 1 and type(durations[1]) == "table" and durations[1][1] ~= nil then
        durations = durations[1]
    end
    if #durations == 0 then
        return nil, nil
    end

    local channelInfo = {UnitChannelInfo("player")}
    if channelInfo[1] and channelInfo[4] then
        return channelInfo[4], durations
    end

    local castInfo = {UnitCastingInfo("player")}
    if castInfo[1] and castInfo[4] then
        return castInfo[4], durations
    end

    return nil, nil
end

local function normalizeDurationMilliseconds(rawDuration)
    if type(rawDuration) ~= "number" then
        return 0
    end

    if rawDuration > 50 then
        return rawDuration
    end

    return rawDuration * 1000
end

local function getStageDurationMilliseconds(durationValue)
    if type(durationValue) == "number" then
        return normalizeDurationMilliseconds(durationValue)
    end

    if durationValue and durationValue.GetTotalDuration then
        local ok, totalDuration = pcall(durationValue.GetTotalDuration, durationValue)
        if ok then
            return normalizeDurationMilliseconds(totalDuration)
        end
    end

    return 0
end

local function getCurrentEmpowerStage()
    local startTimeMs, durations = getEmpowerTiming()
    if not startTimeMs or not durations then
        return nil
    end

    local elapsedMs = math.max(0, (GetTime() * 1000) - startTimeMs)
    local totalMs = 0
    for index, durationValue in ipairs(durations) do
        totalMs = totalMs + getStageDurationMilliseconds(durationValue)
        if elapsedMs < totalMs then
            return index
        end
    end

    return #durations
end

local function applyPosition()
    local settings = db()
    square:ClearAllPoints()
    square:SetPoint(settings.point, UIParent, settings.relativePoint, settings.x, settings.y)
end

local function applySize()
    local settings = db()
    square:SetSize(settings.size, settings.size)
end

local function refreshVisibility()
    local settings = db()
    local optionsPreview = state.optionsOpen
    local unlockedPreview = not settings.locked
    local showSquare = state.currentStage ~= nil or optionsPreview or unlockedPreview
    if showSquare then
        square:Show()
    else
        square:Hide()
    end

    if state.currentStage ~= nil then
        square:SetBackdropColor(getStageColor(state.currentStage))
        square:SetAlpha(1)
        label:SetText("STAGE " .. state.currentStage)
    elseif optionsPreview then
        square:SetBackdropColor(getStageColor(1))
        square:SetAlpha(1)
        label:SetText("PREVIEW")
    else
        square:SetBackdropColor(0.25, 0.25, 0.25, 0.45)
        square:SetAlpha(unlockedPreview and 1 or 0)
        label:SetText("MOVE")
    end

    square:EnableMouse(not settings.locked)
end

local function updateState()
    state.currentStage = getCurrentEmpowerStage()
    refreshVisibility()
end

local function sanitizeSettings()
    local settings = db()
    settings.size = clamp(tonumber(settings.size) or defaults.size, 24, 300)
    settings.x = clamp(math.floor((tonumber(settings.x) or defaults.x) + 0.5), -1000, 1000)
    settings.y = clamp(math.floor((tonumber(settings.y) or defaults.y) + 0.5), -1000, 1000)
    settings.point = type(settings.point) == "string" and settings.point or defaults.point
    settings.relativePoint = type(settings.relativePoint) == "string" and settings.relativePoint or defaults.relativePoint
    settings.locked = settings.locked ~= false
    normalizeStageColorIndexes(settings)
end

local function syncControlsFromDB()
    if not options then
        return
    end
    local settings = db()
    sizeSlider:SetValue(settings.size)
    xSlider:SetValue(settings.x)
    ySlider:SetValue(settings.y)
    lockCheck:SetChecked(settings.locked)
    sizeInput:SetText(tostring(settings.size))
    xInput:SetText(tostring(settings.x))
    yInput:SetText(tostring(settings.y))
    updateStageColorDropdowns()
end

local function onDragStop(self)
    self:StopMovingOrSizing()
    local _, _, _, x, y = self:GetPoint(1)
    local settings = db()
    settings.point = "CENTER"
    settings.relativePoint = "CENTER"
    settings.x = math.floor((x or 0) + 0.5)
    settings.y = math.floor((y or 0) + 0.5)
    applyPosition()
    syncControlsFromDB()
end

square:SetScript("OnDragStart", function(self)
    if not db().locked then
        self:StartMoving()
    end
end)
square:SetScript("OnDragStop", onDragStop)

local function createSlider(parent, labelText, minValue, maxValue, step, onChanged)
    controlId = controlId + 1
    local slider = CreateFrame("Slider", addonName .. "Slider" .. controlId, parent, "OptionsSliderTemplate")
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider.Text:SetText(labelText)
    slider.Low:SetText(tostring(minValue))
    slider.High:SetText(tostring(maxValue))
    slider:SetScript("OnValueChanged", onChanged)
    return slider
end

local function createNumericInput(parent, labelText, width, onApply)
    controlId = controlId + 1

    local holder = CreateFrame("Frame", addonName .. "InputHolder" .. controlId, parent)
    holder:SetSize(width, 44)

    holder.label = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    holder.label:SetPoint("TOPLEFT", 0, 0)
    holder.label:SetText(labelText)

    holder.input = CreateFrame("EditBox", addonName .. "Input" .. controlId, holder, "InputBoxTemplate")
    holder.input:SetSize(width, 28)
    holder.input:SetPoint("TOPLEFT", holder.label, "BOTTOMLEFT", 0, -4)
    holder.input:SetAutoFocus(false)
    holder.input:SetNumeric(false)
    holder.input:SetMaxLetters(8)

    local function applyValue()
        onApply(holder.input:GetText())
    end

    holder.input:SetScript("OnEnterPressed", function(self)
        applyValue()
        self:ClearFocus()
    end)
    holder.input:SetScript("OnEditFocusLost", applyValue)

    return holder
end

local function initializeStageColorDropdown(dropdown, stage)
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        if level ~= 1 then
            return
        end

        for paletteIndex, color in ipairs(COLOR_PALETTE) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = color.name
            info.value = paletteIndex
            info.func = function()
                local settings = db()
                settings.stageColorIndexes[stage] = paletteIndex
                updateStageColorDropdowns()
                refreshVisibility()
            end
            info.checked = paletteIndex == getStageColorIndex(stage)
            info.disabled = isColorIndexUsedByOtherStage(stage, paletteIndex)
            UIDropDownMenu_AddButton(info, level)
        end
    end)
end

local function createStageColorDropdown(parent, stage)
    controlId = controlId + 1

    local holder = CreateFrame("Frame", addonName .. "StageColorHolder" .. controlId, parent)
    holder:SetSize(300, 44)

    holder.label = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    holder.label:SetPoint("TOPLEFT", 0, 0)
    holder.label:SetText("Stage " .. stage)

    holder.dropdown = CreateFrame("Frame", addonName .. "StageColorDropdown" .. controlId, holder, "UIDropDownMenuTemplate")
    holder.dropdown:SetPoint("TOPLEFT", holder.label, "BOTTOMLEFT", -16, -2)
    UIDropDownMenu_SetWidth(holder.dropdown, 180)
    UIDropDownMenu_SetSelectedValue(holder.dropdown, getStageColorIndex(stage))
    UIDropDownMenu_JustifyText(holder.dropdown, "LEFT")
    initializeStageColorDropdown(holder.dropdown, stage)

    return holder
end

local function createOptionsWindow()
    options = CreateFrame("Frame", "EmpowerSquareOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
    options:SetSize(360, 600)
    options:SetPoint("CENTER")
    options:SetMovable(true)
    options:SetClampedToScreen(true)
    options:EnableMouse(true)
    options:RegisterForDrag("LeftButton")
    options:SetScript("OnDragStart", options.StartMoving)
    options:SetScript("OnDragStop", options.StopMovingOrSizing)
    options:Hide()

    options.TitleText:SetText("EmpowerSquare")

    local subtitle = options:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", 16, -32)
    subtitle:SetWidth(320)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText("Shows a solid square for the current empower stage.")

    sizeSlider = createSlider(options, "Square Size", 24, 300, 1, function(self, value)
        if not db() then
            return
        end
        db().size = math.floor(value + 0.5)
        applySize()
    end)
    sizeSlider:SetPoint("TOPLEFT", 18, -76)
    sizeSlider:SetWidth(300)

    xSlider = createSlider(options, "Horizontal Offset", -1000, 1000, 1, function(self, value)
        if not db() then
            return
        end
        db().x = math.floor(value + 0.5)
        applyPosition()
        xInput:SetText(tostring(db().x))
    end)
    xSlider:SetPoint("TOPLEFT", sizeSlider, "BOTTOMLEFT", 0, -32)
    xSlider:SetWidth(300)

    ySlider = createSlider(options, "Vertical Offset", -1000, 1000, 1, function(self, value)
        if not db() then
            return
        end
        db().y = math.floor(value + 0.5)
        applyPosition()
        yInput:SetText(tostring(db().y))
    end)
    ySlider:SetPoint("TOPLEFT", xSlider, "BOTTOMLEFT", 0, -32)
    ySlider:SetWidth(300)

    local inputRow = CreateFrame("Frame", nil, options)
    inputRow:SetSize(300, 52)
    inputRow:SetPoint("TOPLEFT", ySlider, "BOTTOMLEFT", 0, -28)

    local function parseInteger(text)
        local value = tonumber(text)
        if not value then
            return nil
        end
        return math.floor(value + 0.5)
    end

    local sizeHolder = createNumericInput(inputRow, "Size", 80, function(text)
        local value = parseInteger(text)
        if not value then
            sizeInput:SetText(tostring(db().size))
            return
        end
        db().size = clamp(value, 24, 300)
        applySize()
        sizeSlider:SetValue(db().size)
        sizeInput:SetText(tostring(db().size))
    end)
    sizeHolder:SetPoint("TOPLEFT", 0, 0)
    sizeInput = sizeHolder.input

    local xHolder = createNumericInput(inputRow, "X", 80, function(text)
        local value = parseInteger(text)
        if not value then
            xInput:SetText(tostring(db().x))
            return
        end
        db().x = clamp(value, -1000, 1000)
        applyPosition()
        xSlider:SetValue(db().x)
        xInput:SetText(tostring(db().x))
    end)
    xHolder:SetPoint("TOPLEFT", sizeHolder, "TOPRIGHT", 26, 0)
    xInput = xHolder.input

    local yHolder = createNumericInput(inputRow, "Y", 80, function(text)
        local value = parseInteger(text)
        if not value then
            yInput:SetText(tostring(db().y))
            return
        end
        db().y = clamp(value, -1000, 1000)
        applyPosition()
        ySlider:SetValue(db().y)
        yInput:SetText(tostring(db().y))
    end)
    yHolder:SetPoint("TOPLEFT", xHolder, "TOPRIGHT", 26, 0)
    yInput = yHolder.input

    sizeSlider:SetScript("OnValueChanged", function(self, value)
        if not db() then
            return
        end
        db().size = math.floor(value + 0.5)
        applySize()
        sizeInput:SetText(tostring(db().size))
    end)

    lockCheck = CreateFrame("CheckButton", addonName .. "LockCheck", options, "UICheckButtonTemplate")
    lockCheck:SetPoint("TOPLEFT", inputRow, "BOTTOMLEFT", 0, -12)
    lockCheck.text:SetText("Lock Square")
    lockCheck:SetScript("OnClick", function(self)
        db().locked = self:GetChecked() and true or false
        refreshVisibility()
    end)

    local colorLabel = options:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colorLabel:SetPoint("TOPLEFT", lockCheck, "BOTTOMLEFT", 4, -14)
    colorLabel:SetText("Stage Colors")

    local colorHint = options:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colorHint:SetPoint("TOPLEFT", colorLabel, "BOTTOMLEFT", 0, -4)
    colorHint:SetWidth(300)
    colorHint:SetJustifyH("LEFT")
    colorHint:SetText("Select from the fixed palette. The same color cannot be assigned to two stages.")

    local previousDropdown = nil
    for stage = 1, #DEFAULT_STAGE_COLOR_INDEXES do
        local dropdownHolder = createStageColorDropdown(options, stage)
        if previousDropdown then
            dropdownHolder:SetPoint("TOPLEFT", previousDropdown, "BOTTOMLEFT", 0, -12)
        else
            dropdownHolder:SetPoint("TOPLEFT", colorHint, "BOTTOMLEFT", 0, -10)
        end
        stageColorDropdowns[stage] = dropdownHolder.dropdown
        previousDropdown = dropdownHolder
    end

    local resetButton = CreateFrame("Button", nil, options, "GameMenuButtonTemplate")
    resetButton:SetPoint("BOTTOMLEFT", 18, 20)
    resetButton:SetSize(120, 24)
    resetButton:SetText("Reset Defaults")
    resetButton:SetScript("OnClick", function()
        local settings = db()
        settings.point = defaults.point
        settings.relativePoint = defaults.relativePoint
        settings.x = defaults.x
        settings.y = defaults.y
        settings.size = defaults.size
        settings.locked = defaults.locked
        settings.stageColorIndexes = copyArray(DEFAULT_STAGE_COLOR_INDEXES)
        applySize()
        applyPosition()
        syncControlsFromDB()
        refreshVisibility()
    end)

    local closeButton = CreateFrame("Button", nil, options, "GameMenuButtonTemplate")
    closeButton:SetPoint("BOTTOMRIGHT", -18, 20)
    closeButton:SetSize(120, 24)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        options:Hide()
    end)

    options:SetScript("OnShow", function()
        state.optionsOpen = true
        syncControlsFromDB()
        refreshVisibility()
    end)

    options:SetScript("OnHide", function()
        state.optionsOpen = false
        refreshVisibility()
    end)
end

local function printUsage()
    print("|cff33ff99EmpowerSquare|r commands:")
    print("/empowersquare or /es - Open settings")
    print("/es lock - Lock the square")
    print("/es unlock - Unlock and show move preview")
    print("/es size <number> - Set square size")
    print("/es reset - Reset defaults")
end

SLASH_EMPOWERSQUARE1 = "/empowersquare"
SLASH_EMPOWERSQUARE2 = "/es"
SlashCmdList.EMPOWERSQUARE = function(msg)
    local input = (msg or ""):match("^%s*(.-)%s*$")
    local command, value = input:match("^(%S+)%s*(.-)$")
    command = command and command:lower() or ""

    if command == "" then
        if not options then
            createOptionsWindow()
        end
        if options:IsShown() then
            options:Hide()
        else
            options:Show()
        end
        return
    end

    if command == "lock" then
        db().locked = true
        syncControlsFromDB()
        refreshVisibility()
        print("|cff33ff99EmpowerSquare|r locked.")
        return
    end

    if command == "unlock" then
        db().locked = false
        syncControlsFromDB()
        refreshVisibility()
        print("|cff33ff99EmpowerSquare|r unlocked. Drag the square to move it.")
        return
    end

    if command == "size" then
        local numeric = tonumber(value)
        if not numeric then
            print("|cff33ff99EmpowerSquare|r size must be a number.")
            return
        end
        db().size = clamp(math.floor(numeric + 0.5), 24, 300)
        applySize()
        syncControlsFromDB()
        refreshVisibility()
        print("|cff33ff99EmpowerSquare|r size set to " .. db().size .. ".")
        return
    end

    if command == "reset" then
        local settings = db()
        settings.point = defaults.point
        settings.relativePoint = defaults.relativePoint
        settings.x = defaults.x
        settings.y = defaults.y
        settings.size = defaults.size
        settings.locked = defaults.locked
        applySize()
        applyPosition()
        syncControlsFromDB()
        refreshVisibility()
        print("|cff33ff99EmpowerSquare|r reset to defaults.")
        return
    end

    printUsage()
end

local function initialize()
    EmpowerSquareDB = EmpowerSquareDB or {}
    copyDefaults(EmpowerSquareDB, defaults)
    if type(EmpowerSquareDB.stageColorIndexes) ~= "table" then
        EmpowerSquareDB.stageColorIndexes = copyArray(DEFAULT_STAGE_COLOR_INDEXES)
    end
    sanitizeSettings()

    applySize()
    applyPosition()
    updateState()

    addon:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
    addon:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_UPDATE", "player")
    addon:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "player")
    addon:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
    addon:RegisterEvent("PLAYER_ENTERING_WORLD")

    if C_Timer and C_Timer.NewTicker then
        C_Timer.NewTicker(0.05, function()
            if db() then
                local current = getCurrentEmpowerStage()
                if current ~= state.currentStage then
                    state.currentStage = current
                    refreshVisibility()
                elseif current ~= nil then
                    refreshVisibility()
                end
            end
        end)
    end
end

addon:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            initialize()
        end
        return
    end

    updateState()
end)
