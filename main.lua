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


local function PrintMessage(msg)
    print("|cff00ff00[syn_alerts]|r " .. msg)
end

local function PrintAlert(msg)
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


local DIALOG_BG = "Interface\\DialogFrame\\UI-DialogBox-Background"
local DIALOG_BORDER = "Interface\\DialogFrame\\UI-DialogBox-Border"
local DIALOG_HEADER = "Interface\\DialogFrame\\UI-DialogBox-Header"
local TOOLTIP_BG = "Interface\\Tooltips\\UI-Tooltip-Background"
local WHITE8 = "Interface\\Buttons\\WHITE8x8"
local CHECKBOX_UP = "Interface\\Buttons\\UI-CheckBox-Up"
local CHECKBOX_DOWN = "Interface\\Buttons\\UI-CheckBox-Down"
local CHECKBOX_CHECK = "Interface\\Buttons\\UI-CheckBox-Check"
local CHECKBOX_HIGHLIGHT = "Interface\\Buttons\\UI-CheckBox-Highlight"
local CLOSE_BG = "Interface\\Buttons\\UI-Panel-MinimizeButton-Up"
local CLOSE_DOWN = "Interface\\Buttons\\UI-Panel-MinimizeButton-Down"
local CLOSE_HIGHLIGHT = "Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight"


local function CreateOptionsWindow()
    if SynAlertsOptionsFrame then
        SynAlertsOptionsFrame:Show()
        return SynAlertsOptionsFrame
    end
    
    if not SynAlertsDB then
        SynAlertsDB = {}
        for k, v in pairs(defaults) do
            SynAlertsDB[k] = v
        end
    end
    
    local isDark = (SynAlertsDB.darkMode == nil and defaults.darkMode) or SynAlertsDB.darkMode
    
    local BORDER_WHITE = 2
    local W = 350
    local H = 400
    
    local container = CreateFrame("Frame", "SynAlertsOptionsFrame", UIParent)
    container:SetFrameStrata("DIALOG")
    container:SetSize(W + BORDER_WHITE * 2, H + BORDER_WHITE * 2)
    container:SetPoint("CENTER", 0, 0)
    container:SetMovable(true)
    container:EnableMouse(true)
    container:SetClampedToScreen(true)
    
    local function addBorderEdge(point, relPoint, x, y, w, h)
        local t = container:CreateTexture(nil, "OVERLAY")
        t:SetTexture(WHITE8)
        t:SetVertexColor(1, 1, 1)
        t:SetPoint(point, container, relPoint, x, y)
        t:SetSize(w, h)
        return t
    end
    addBorderEdge("TOPLEFT", "TOPLEFT", 0, 0, container:GetWidth(), BORDER_WHITE)
    addBorderEdge("BOTTOMLEFT", "BOTTOMLEFT", 0, 0, container:GetWidth(), BORDER_WHITE)
    addBorderEdge("TOPLEFT", "TOPLEFT", 0, 0, BORDER_WHITE, container:GetHeight())
    addBorderEdge("TOPRIGHT", "TOPRIGHT", 0, 0, BORDER_WHITE, container:GetHeight())
    
    local win = CreateFrame("Frame", nil, container)
    win:SetSize(W, H)
    win:SetPoint("CENTER", 0, 0)
    
    if win.SetBackdrop then
        win:SetBackdrop({
            bgFile = TOOLTIP_BG,
            edgeFile = DIALOG_BORDER,
            tile = true,
            tileSize = 16,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
    else
        local bg = win:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(win)
        bg:SetTexture(TOOLTIP_BG)
        bg:SetTexCoord(0, 1, 0, 1)
        local edge = win:CreateTexture(nil, "BORDER")
        edge:SetAllPoints(win)
        edge:SetTexture(DIALOG_BORDER)
    end
    
    local TITLE_HEIGHT = 40
    local PAD = 24
    
    local titleBar = win:CreateTexture(nil, "ARTWORK")
    titleBar:SetTexture(DIALOG_HEADER)
    titleBar:SetPoint("TOPLEFT", 12, -8)
    titleBar:SetPoint("TOPRIGHT", -12, -8)
    titleBar:SetHeight(32)
    titleBar:SetTexCoord(0, 1, 0, 32/64)
    
    local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", win, "TOPLEFT", PAD, -TITLE_HEIGHT / 2 - 4)
    title:SetPoint("RIGHT", win, "TOPRIGHT", -44, -TITLE_HEIGHT / 2 - 4)
    title:SetJustifyH("LEFT")
    title:SetText("syn_alerts")
    title:SetTextColor(1, 0.82, 0)
    win._title = title
    
    local close = CreateFrame("Button", nil, win)
    close:SetSize(24, 24)
    close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -14, -10)
    close:SetScript("OnClick", function()
        container:Hide()
    end)
    local closeTex = close:CreateTexture(nil, "ARTWORK")
    closeTex:SetAllPoints(close)
    closeTex:SetTexture(CLOSE_BG)
    close:SetNormalTexture(closeTex)
    local closePushed = close:CreateTexture(nil, "ARTWORK")
    closePushed:SetAllPoints(close)
    closePushed:SetTexture(CLOSE_DOWN)
    close:SetPushedTexture(closePushed)
    close:SetHighlightTexture(CLOSE_HIGHLIGHT)
    win._close = close
    
    local drag = CreateFrame("Button", nil, win)
    drag:SetPoint("TOPLEFT", 12, -4)
    drag:SetPoint("TOPRIGHT", -40, -4)
    drag:SetHeight(TITLE_HEIGHT)
    drag:SetScript("OnMouseDown", function()
        container:StartMoving()
    end)
    drag:SetScript("OnMouseUp", function()
        container:StopMovingOrSizing()
    end)
    
    local content = CreateFrame("Frame", nil, win)
    content:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -TITLE_HEIGHT - PAD)
    content:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -PAD, PAD)
    
    local cbs = {}
    local yOff = 0
    local ROW = 28
    
    local function AddCheckbox(label, key, isDarkMode)
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(280, ROW)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOff)
        
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
        if isDark then
            labelText:SetTextColor(0.9, 0.9, 0.85)
        else
            labelText:SetTextColor(0.2, 0.2, 0.2)
        end
        cb._label = labelText
        
        cb:SetScript("OnClick", function(self)
            if SynAlertsDB then
                SynAlertsDB[key] = self:GetChecked()
                if key == "darkMode" then
                    win:ApplyTheme()
                end
            end
        end)
        
        local v = SynAlertsDB and SynAlertsDB[key]
        if v == nil then v = (isDarkMode and defaults.darkMode) or defaults[key] or false end
        cb:SetChecked(v)
        
        cbs[#cbs + 1] = cb
        yOff = yOff - ROW
        return cb
    end
    
    AddCheckbox("Dark mode", "darkMode", true)
    yOff = yOff - 8
    
    AddCheckbox("Announce CC", "announceCC")
    AddCheckbox("Announce DoTs", "announceDots")
    AddCheckbox("Announce Curse", "announceCurse")
    AddCheckbox("Announce Disease", "announceDisease")
    AddCheckbox("Announce Poison", "announcePoison")
    AddCheckbox("Announce Magic", "announceMagic")
    AddCheckbox("Announce Enrage", "announceEnrage")
    
    win._cbs = cbs
    
    function win:ApplyTheme()
        local dark = (SynAlertsDB and SynAlertsDB.darkMode == true) or (SynAlertsDB.darkMode == nil and defaults.darkMode)
        if self._title then
            self._title:SetTextColor(1, 0.82, 0)
        end
        for _, cb in ipairs(self._cbs) do
            if cb._label then
                if dark then
                    cb._label:SetTextColor(0.9, 0.9, 0.85)
                else
                    cb._label:SetTextColor(0.2, 0.2, 0.2)
                end
            end
        end
    end
    
    win:SetScript("OnShow", function(self)
        for _, c in ipairs(cbs) do
            if c.key and SynAlertsDB then
                local v = SynAlertsDB[c.key]
                if v == nil then v = defaults[c.key] or (c.key == "darkMode" and defaults.darkMode) or false end
                c:SetChecked(v)
            end
        end
        self:ApplyTheme()
    end)
    
    container:Hide()
    return container
end

local function ShowOptions()
    local ok, win = pcall(CreateOptionsWindow)
    if ok and win then
        win:Show()
        win:Raise()
    else
        PrintMessage("Could not open options. Error: " .. tostring(win))
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
        local combatLogData = {CombatLogGetCurrentEventInfo()}
        local subEvent = combatLogData[2]
        local destGUID = combatLogData[8]
        local spellId = combatLogData[12]
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
                PrintAlert(" {rt8} " .. spellName .. " (CC) on " .. playerName .. " {rt8} ")

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