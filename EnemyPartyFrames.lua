-- EnemyPartyFrames.lua

local addonName, ns = ...

EnemyPartyFramesDB = EnemyPartyFramesDB or {
    namePriorities = {},
    exactMatch = false,
}

local inCombat = false

-- Combat watcher to track player's combat state
local combatWatcher = CreateFrame("Frame")
combatWatcher:RegisterEvent("PLAYER_REGEN_DISABLED")
combatWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
combatWatcher:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
    end
    UpdateEnemyFrames()
end)

-- Main container for enemy frames
local function CreateEnemyFramesContainer()
    local container = CreateFrame("Frame", "EnemyPartyFramesContainer", UIParent)
    container:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
    container:SetSize(200, 400)
    container.frames = {}
    container:Hide()

    -- Pre-create 10 secure unit buttons
    for i = 1, 10 do
        local frame = CreateFrame("Button", "EnemyPartyUnitFrame" .. i, container, "SecureUnitButtonTemplate, BackdropTemplate")
        frame:SetSize(160, 30)
        frame:SetPoint("TOPLEFT", 0, -((i - 1) * 35))
        frame:SetAttribute("type", "target")  -- Clicking sets your target to unit

        frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.nameText:SetPoint("LEFT", 6, 0)

        frame.prioText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.prioText:SetPoint("RIGHT", -6, 0)

        frame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
        frame:SetBackdropColor(0, 0, 0, 0.5)

        container.frames[i] = frame
    end

    return container
end

EnemyPartyFramesContainer = CreateEnemyFramesContainer()

-- Update one enemy frame with unit info
local function UpdateEnemyFrame(frame, unitID, name, prio)
    if not InCombatLockdown() then
        frame:SetAttribute("unit", unitID)
    end

    frame.nameText:SetText(name)
    frame.prioText:SetText(prio)

    if prio >= 900 then
        frame:SetBackdropColor(1, 0, 0, 0.6)
    elseif prio >= 700 then
        frame:SetBackdropColor(1, 0.5, 0, 0.4)
    else
        frame:SetBackdropColor(0.2, 0.2, 0.2, 0.3)
    end

    frame:Show()
end

-- Update all enemy frames
function UpdateEnemyFrames()
    if not EnemyPartyFramesContainer then return end

    local enemies = {}

    -- Gather up to 40 enemies within 40 yards
    for i = 1, 40 do
        local unitID = "nameplate" .. i
        if UnitExists(unitID)
            and UnitCanAttack("player", unitID)
            and not UnitIsPlayer(unitID)
            and UnitIsEnemy("player", unitID)
        then
            local dist = 40 -- WoW API doesn't give exact distances, assume 40 yards max

            if dist <= 40 then
                local name = GetUnitName(unitID, false)
                local prio = EnemyPartyFramesDB.namePriorities[name] or 0
                table.insert(enemies, {unit = unitID, name = name, prio = prio, dist = dist})
            end
        end
    end

    -- Sort by distance (ascending)
    table.sort(enemies, function(a,b) return a.dist < b.dist end)

    local count = math.min(#enemies, 10)
    for i = 1, count do
        local e = enemies[i]
        UpdateEnemyFrame(EnemyPartyFramesContainer.frames[i], e.unit, e.name, e.prio)
    end

    -- Hide unused frames
    for i = count + 1, 10 do
        EnemyPartyFramesContainer.frames[i]:Hide()
    end

    EnemyPartyFramesContainer:SetShown(count > 0)
end

-- Frame to update on relevant events
local updateFrame = CreateFrame("Frame")
updateFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
updateFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
updateFrame:RegisterEvent("UNIT_TARGET")
updateFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
updateFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
updateFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
updateFrame:SetScript("OnEvent", UpdateEnemyFrames)

-- Setup options panel safely inside OnShow
local function SetupOptionsPanel()
    local optionsPanel = EPFOptionsPanel
    if not optionsPanel then
        print("|cff00ff00EnemyPartyFrames:|r ERROR - Options panel missing!")
        return
    end

    optionsPanel:SetScript("OnShow", function(self)
        local exactMatchCheckbox = _G["EPFOptionsPanelExactMatchCheckbox"]
        local resetButton = _G["EPFOptionsPanelResetButton"]

        if exactMatchCheckbox then
            exactMatchCheckbox:SetChecked(EnemyPartyFramesDB.exactMatch)
            exactMatchCheckbox:SetScript("OnClick", function(cb)
                EnemyPartyFramesDB.exactMatch = cb:GetChecked()
            end)
        else
            print("|cff00ff00EnemyPartyFrames:|r ERROR - ExactMatchCheckbox not found!")
        end

        if resetButton then
            resetButton:SetScript("OnClick", function()
                EnemyPartyFramesDB.namePriorities = {}
                print("|cff00ff00EnemyPartyFrames:|r Priorities reset.")
                UpdateEnemyFrames()
            end)
        else
            print("|cff00ff00EnemyPartyFrames:|r ERROR - ResetButton not found!")
        end
    end)

    -- Delayed adding to Interface Options to avoid nil global error
    local function AddPanel()
        if InterfaceOptions_AddCategory then
            InterfaceOptions_AddCategory(optionsPanel)
        else
            C_Timer.After(0.5, AddPanel)
        end
    end
    AddPanel()
end

-- Listen for addon loaded event
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
    if name == addonName then
        EnemyPartyFramesDB = EnemyPartyFramesDB or {
            namePriorities = {},
            exactMatch = false,
        }

        SetupOptionsPanel()
        UpdateEnemyFrames()
    end
end)

