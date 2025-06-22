
local addonName, ns = ...

-- Saved variables default table
EnemyPartyFramesDB = EnemyPartyFramesDB or {
    namePriorities = {},
    exactMatch = false,
}

local panel = CreateFrame("Frame", "EPFOptionsPanel", UIParent)
panel.name = "EnemyPartyFrames"
InterfaceOptions_AddCategory(panel)

-- Priority input box
local priorityBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
priorityBox:SetSize(260, 24)
priorityBox:SetPoint("TOPLEFT", 20, -20)
priorityBox:SetAutoFocus(false)
priorityBox:SetText("")
priorityBox:SetScript("OnEnterPressed", function(self)
    local text = self:GetText()
    for line in text:gmatch('[^\n]+') do
        local name, prio = line:match('^(.+)%s*=\s*(%d+)$')
        if name and prio then
            EnemyPartyFramesDB.namePriorities[name] = tonumber(prio)
        end
    end
    RefreshPriorityListUI()
    UpdateEnemyFrames()
    self:SetText("")
end)

local priorityLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
priorityLabel:SetPoint("BOTTOMLEFT", priorityBox, "TOPLEFT", 0, 2)
priorityLabel:SetText("Add/Update Priorities (name = number), multiple lines allowed")

-- Filter box
local filterBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
filterBox:SetSize(260, 24)
filterBox:SetPoint("TOPLEFT", priorityBox, "BOTTOMLEFT", 0, -50)
filterBox:SetAutoFocus(false)
filterBox:SetText("")

local filterLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
filterLabel:SetPoint("BOTTOMLEFT", filterBox, "TOPLEFT", 0, 2)
filterLabel:SetText("Filter by name:")

filterBox:SetScript("OnTextChanged", function()
    RefreshPriorityListUI()
end)

-- Clear all priorities button
local clearBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
clearBtn:SetSize(120, 24)
clearBtn:SetPoint("TOPLEFT", filterBox, "BOTTOMLEFT", 0, -10)
clearBtn:SetText("Clear All Priorities")

clearBtn:SetScript("OnClick", function()
    for k in pairs(EnemyPartyFramesDB.namePriorities) do
        EnemyPartyFramesDB.namePriorities[k] = nil
    end
    RefreshPriorityListUI()
    UpdateEnemyFrames()
    print("All custom priorities cleared.")
end)

-- Scroll frame for priority list
local scrollFrame = CreateFrame("ScrollFrame", "EPFPriorityScrollList", panel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", clearBtn, "BOTTOMLEFT", 0, -10)
scrollFrame:SetSize(360, 180)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(340, 1) -- height will be updated dynamically
scrollFrame:SetScrollChild(content)

scrollFrame.content = content
scrollFrame.buttons = {}

-- Helper function to trim whitespace
local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Refresh priority list UI
function RefreshPriorityListUI()
    local content = scrollFrame.content
    local buttons = scrollFrame.buttons
    local filterText = string.lower(filterBox:GetText() or "")
    local i = 0

    for _, btn in ipairs(buttons) do
        btn:Hide()
        if btn.label then btn.label:Hide() end
        if btn.editBox then btn.editBox:Hide() end
        if btn.icon then btn.icon:Hide() end
        if btn.bg then btn.bg:Hide() end
    end

    local sorted = {}
    for name, prio in pairs(EnemyPartyFramesDB.namePriorities) do
        if filterText == "" or string.find(string.lower(name), filterText, 1, true) then
            table.insert(sorted, { name = name, prio = prio })
        end
    end
    table.sort(sorted, function(a, b)
        return tonumber(a.prio) > tonumber(b.prio)
    end)

    for _, entry in ipairs(sorted) do
        i = i + 1
        local btn = buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
            btn:SetSize(20, 20)
            buttons[i] = btn

            btn.editBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
            btn.editBox:SetSize(60, 20)
            btn.editBox:SetAutoFocus(false)
            btn.editBox:SetNumeric(true)

            btn.label = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        end

        btn:SetPoint("TOPLEFT", 0, -((i - 1) * 26))
        btn:SetText("")
        btn:SetScript("OnClick", function()
            EnemyPartyFramesDB.namePriorities[entry.name] = nil
            RefreshPriorityListUI()
            UpdateEnemyFrames()
        end)

        -- Icon for remove button
        if not btn.icon then
            btn.icon = btn:CreateTexture(nil, "OVERLAY")
            btn.icon:SetSize(16, 16)
            btn.icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
            btn.icon:SetTexture("Interface\Buttons\UI-GroupLoot-Pass-Up")
        end
        btn.icon:Show()

        btn.label:SetPoint("LEFT", btn, "RIGHT", 4, 0)
        btn.label:SetText(entry.name)
        btn.label:Show()

        btn.editBox:SetPoint("LEFT", btn.label, "RIGHT", 6, 0)
        btn.editBox:SetNumber(entry.prio or 0)
        btn.editBox:SetScript("OnEnterPressed", function(self)
            local newVal = tonumber(self:GetText())
            if newVal then
                EnemyPartyFramesDB.namePriorities[entry.name] = newVal
                UpdateEnemyFrames()
                RefreshPriorityListUI()
            end
            self:ClearFocus()
        end)
        btn.editBox:Show()

        if not btn.bg then
            btn.bg = btn:CreateTexture(nil, "BACKGROUND")
            btn.bg:SetAllPoints()
        end

        if entry.prio >= 900 then
            btn.bg:SetColorTexture(1, 0, 0, 0.2)
        elseif entry.prio >= 700 then
            btn.bg:SetColorTexture(1, 0.5, 0, 0.15)
        else
            btn.bg:SetColorTexture(0.2, 0.2, 0.2, 0.1)
        end
        btn.bg:Show()

        btn:Show()
    end

    content:SetHeight(i * 26)
end

-- Dummy UpdateEnemyFrames function to avoid errors
function UpdateEnemyFrames()
    -- Placeholder: your existing logic to update enemy frames goes here
end

panel:SetScript("OnShow", function()
    RefreshPriorityListUI()
end)
