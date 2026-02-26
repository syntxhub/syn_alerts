local ADDON_NAME = ...
local ADDON_VERSION = "1.1"
local REQUIRED_INTERFACE = 20505

if not ADDON_NAME or ADDON_NAME == "" then
    ADDON_NAME = "syn_alerts"
end

local frame = CreateFrame("Frame")

local defaults = {
    announceCC = true,
    announceDots = true,
    announceCurse = true,
    announceDisease = true,
    announcePoison = true,
    announceMagic = true,
    announceEnrage = true,
    darkMode = true,
}

local CHECKBOX_UP = "Interface\\Buttons\\UI-CheckBox-Up"
local CHECKBOX_DOWN = "Interface\\Buttons\\UI-CheckBox-Down"
local CHECKBOX_CHECK = "Interface\\Buttons\\UI-CheckBox-Check"
local CHECKBOX_HIGHLIGHT = "Interface\\Buttons\\UI-CheckBox-Highlight"

local function PrintMessage(msg)
    print("|cff00ff00[syn_alerts]|r " .. msg)
end

local lastAlertMessage = nil
local lastAlertTime = 0
local ALERT_COOLDOWN = 15

local function PrintAlert(msg)
    local currentTime = GetTime()


    if msg ~= lastAlertMessage then
        lastAlertMessage = msg
        lastAlertTime = currentTime

        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            SendChatMessage(msg, "INSTANCE_CHAT")
        elseif IsInRaid() then
            SendChatMessage(msg, "RAID")
        elseif IsInGroup() then
            SendChatMessage(msg, "PARTY")
        else
            print("|cffff8800[syn_alerts]|r " .. msg)
        end
        return
    end


    if currentTime - lastAlertTime >= ALERT_COOLDOWN then
        lastAlertTime = currentTime

        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            SendChatMessage(msg, "INSTANCE_CHAT")
        elseif IsInRaid() then
            SendChatMessage(msg, "RAID")
        elseif IsInGroup() then
            SendChatMessage(msg, "PARTY")
        else
            print("|cffff8800[syn_alerts]|r " .. msg)
        end
    end
end

local function IsPlayer(destGUID)
    return destGUID == UnitGUID("player")
end

local function StartupMessage()
    local interfaceVersion = select(4, GetBuildInfo())

    if interfaceVersion ~= REQUIRED_INTERFACE then
        PrintMessage("Interface mismatch. Expected: "
            .. REQUIRED_INTERFACE .. " Current: " .. interfaceVersion)
    end

    PrintMessage("Version " .. ADDON_VERSION .. " loaded.")
end

local function ApplyTheme(winContent, cbs)
    local dark = (SynAlertsDB and SynAlertsDB.darkMode == true) or defaults.darkMode
    if winContent.Title then
        winContent.Title:SetTextColor(1, 0.82, 0)
    end
    if cbs then
        for _, cb in ipairs(cbs) do
            if cb._label then
                if dark then
                    cb._label:SetTextColor(0.9, 0.9, 0.85)
                else
                    cb._label:SetTextColor(0.2, 0.2, 0.2)
                end
            end
        end
    end
end

local function ApplyThemeForCheckboxes(cbs)
    local dark = (SynAlertsDB and SynAlertsDB.darkMode == true) or defaults.darkMode
    if SynAlertsOptionsFrameContentTitle then
        SynAlertsOptionsFrameContentTitle:SetTextColor(1, 0.82, 0)
    end
    if cbs then
        for _, cb in ipairs(cbs) do
            if cb._label then
                if dark then
                    cb._label:SetTextColor(0.9, 0.9, 0.85)
                else
                    cb._label:SetTextColor(0.2, 0.2, 0.2)
                end
            end
        end
    end
end

local function SetupOptionsWindow()
    if SynAlertsOptionsFrame then
        return true
    end

    if not SynAlertsDB then
        SynAlertsDB = {}
        for k, v in pairs(defaults) do
            SynAlertsDB[k] = v
        end
    end


    local frame = CreateFrame("Frame", "SynAlertsOptionsFrame", UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:SetWidth(750)
    frame:SetHeight(400)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)


    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetColorTexture(0.1, 0.1, 0.1, 1.0)


    local borderTop = frame:CreateTexture(nil, "BORDER")
    borderTop:SetColorTexture(0.5, 0.5, 0.5, 1.0)
    borderTop:SetPoint("TOPLEFT", 0, 0)
    borderTop:SetSize(350, 2)

    local borderBottom = frame:CreateTexture(nil, "BORDER")
    borderBottom:SetColorTexture(0.5, 0.5, 0.5, 1.0)
    borderBottom:SetPoint("BOTTOMLEFT", 0, 0)
    borderBottom:SetSize(350, 2)

    local borderLeft = frame:CreateTexture(nil, "BORDER")
    borderLeft:SetColorTexture(0.5, 0.5, 0.5, 1.0)
    borderLeft:SetPoint("TOPLEFT", 0, 0)
    borderLeft:SetSize(2, 400)

    local borderRight = frame:CreateTexture(nil, "BORDER")
    borderRight:SetColorTexture(0.5, 0.5, 0.5, 1.0)
    borderRight:SetPoint("TOPRIGHT", 0, 0)
    borderRight:SetSize(2, 400)


    local titleBg = frame:CreateTexture(nil, "ARTWORK")
    titleBg:SetColorTexture(0.2, 0.2, 0.3, 1.0)
    titleBg:SetPoint("TOPLEFT", 0, 0)
    titleBg:SetPoint("TOPRIGHT", 0, 0)
    titleBg:SetHeight(35)


    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 15, -10)
    title:SetText("Syn - Simple Debuff Alerts")
    title:SetTextColor(1, 1, 1)
    title:SetJustifyH("LEFT")


    local close = CreateFrame("Button", nil, frame)
    close:SetSize(24, 24)
    close:SetPoint("TOPRIGHT", -8, -5)
    close:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    close:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    close:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    close:SetScript("OnClick", function()
        frame:Hide()
    end)


    local drag = CreateFrame("Button", nil, frame)
    drag:SetPoint("TOPLEFT", 0, 0)
    drag:SetPoint("TOPRIGHT", -30, 0)
    drag:SetHeight(35)
    drag:SetScript("OnMouseDown", function()
        frame:StartMoving()
    end)
    drag:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)


    local scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:SetPoint("TOPLEFT", 3, -35)
    scroll:SetPoint("BOTTOMRIGHT", -6, 4)

    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(340, 360)
    scroll:SetScrollChild(scrollChild)

    local ROW = 28
    local yOff = 0
    local cbs = {}

    local function AddCheckbox(label, key)
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetSize(320, ROW)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOff)

        local cb = CreateFrame("CheckButton", nil, row)
        cb:SetSize(24, 24)
        cb:SetPoint("LEFT", row, "LEFT", 0, 0)
        cb.key = key

        cb:SetNormalTexture(CHECKBOX_UP)
        cb:SetPushedTexture(CHECKBOX_DOWN)
        cb:SetHighlightTexture(CHECKBOX_HIGHLIGHT)
        cb:SetCheckedTexture(CHECKBOX_CHECK)
        cb:SetDisabledCheckedTexture(CHECKBOX_CHECK)

        local labelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        labelText:SetPoint("LEFT", cb, "RIGHT", 8, 0)
        labelText:SetJustifyH("LEFT")
        labelText:SetText(label)
        labelText:SetTextColor(1, 1, 1)
        cb._label = labelText

        cb:SetScript("OnClick", function(self)
            if SynAlertsDB then
                SynAlertsDB[key] = self:GetChecked()
                if key == "darkMode" then
                    ApplyThemeForCheckboxes(cbs)
                end
            end
        end)

        local v = SynAlertsDB and SynAlertsDB[key] or defaults[key]
        cb:SetChecked(v)

        cbs[#cbs + 1] = cb
        yOff = yOff - ROW
    end

    AddCheckbox("Totally useless tickbox (For Brainrot kids 67 skibidi amiright)", "darkMode")
    yOff = yOff - 8

    AddCheckbox("Announce CC", "announceCC")
    AddCheckbox("Announce DoTs", "announceDots")
    AddCheckbox("Announce Curse", "announceCurse")
    AddCheckbox("Announce Disease", "announceDisease")
    AddCheckbox("Announce Poison", "announcePoison")
    AddCheckbox("Announce Magic", "announceMagic")
    AddCheckbox("Announce Enrage", "announceEnrage")


    scrollChild:SetHeight(math.abs(yOff))

    frame._cbs = cbs
    ApplyThemeForCheckboxes(cbs)

    frame:SetScript("OnShow", function(self)
        for _, c in ipairs(cbs) do
            if c.key and SynAlertsDB then
                local v = SynAlertsDB[c.key]
                if v == nil then v = defaults[c.key] or false end
                c:SetChecked(v)
            end
        end
    end)

    frame:Hide()
    return true
end

local optionsSetupDone = false

local function ShowOptions()
    if not optionsSetupDone then
        local ok = SetupOptionsWindow()
        if not ok then
            PrintMessage("ERROR: Failed to create options window.")
            return
        end
        optionsSetupDone = true
    end

    if SynAlertsOptionsFrame then
        SynAlertsOptionsFrame:Show()
        SynAlertsOptionsFrame:Raise()
    else
        PrintMessage("ERROR: Failed to show options window.")
    end
end


SLASH_syn_alerts1 = "/sa"
SLASH_syn_alerts2 = "/synalerts"

SlashCmdList["syn_alerts"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "test" then
        PrintAlert("{rt8} TEST DEBUFF" .. " on " .. UnitName("player") .. " {rt8}")
    elseif msg == "config" or msg == "options" or msg == "settings" then
        ShowOptions()
    else
        PrintMessage("Commands:")
        PrintMessage("/sa test - Trigger test alert")
        PrintMessage("/sa config - Open settings")
    end
end


frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        SynAlertsDB = SynAlertsDB or {}

        for k, v in pairs(defaults) do
            if SynAlertsDB[k] == nil then
                SynAlertsDB[k] = v
            end
        end

        StartupMessage()
        return
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local combatLogData = { CombatLogGetCurrentEventInfo() }
        local subEvent = combatLogData[2]
        local destGUID = combatLogData[8]
        local spellName = combatLogData[13]

        if (subEvent == "SPELL_AURA_APPLIED"
                or subEvent == "SPELL_AURA_REFRESH"
                or subEvent == "SPELL_AURA_APPLIED_DOSE")
            and IsPlayer(destGUID)
            and spellName then
            local playerName = UnitName("player")

            local name, icon, count, debuffType, duration, expirationTime =
                AuraUtil.FindAuraByName(spellName, "player", "HARMFUL")

            if not name then return end

            local isCC = (not debuffType or debuffType == "")

            if isCC and SynAlertsDB.announceCC then
                PrintAlert(" {rt8} " .. spellName .. " on " .. playerName .. " {rt8} ")
            elseif debuffType == "Curse" and SynAlertsDB.announceCurse then
                PrintAlert(" {rt8} " .. spellName .. " on " .. playerName .. " {rt8} ")
            elseif debuffType == "Disease" and SynAlertsDB.announceDisease then
                PrintAlert(" {rt8} " .. spellName .. " on " .. playerName .. " {rt8} ")
            elseif debuffType == "Poison" and SynAlertsDB.announcePoison then
                PrintAlert(" {rt8} " .. spellName .. " on " .. playerName .. " {rt8} ")
            elseif debuffType == "Magic" and SynAlertsDB.announceMagic then
                PrintAlert(" {rt8} " .. spellName .. " on " .. playerName .. " {rt8} ")
            elseif debuffType == "Enrage" and SynAlertsDB.announceEnrage then
                PrintAlert(" {rt8} " .. spellName .. " on " .. playerName .. " {rt8} ")
            elseif SynAlertsDB.announceDots then
                if debuffType and debuffType ~= "" and
                    debuffType ~= "Curse" and debuffType ~= "Disease" and
                    debuffType ~= "Poison" and debuffType ~= "Magic" and
                    debuffType ~= "Enrage" then
                    PrintAlert(" {rt8} " .. spellName .. " on " .. playerName .. " {rt8} ")
                end
            end
        end
    end
end)
