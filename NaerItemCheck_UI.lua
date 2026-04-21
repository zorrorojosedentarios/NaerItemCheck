-- ==================================
-- NaerItemCheck UI
-- Versión con Editor de Base de Datos
-- ==================================

NIC_CurrentRaid = "ICC"
NIC_CurrentSize = "10"
NIC_IsHeroic = false

local QUERY_COOLDOWN = 1.5
local lastQueryTime = 0

NIC_ItemStatus = {}

-- Forward declarations
local helpFrame
local BuildList
local ShowEditor

-- =========================
-- Utils y Consultas
-- =========================

local function CanQuery()
    return (GetTime() - lastQueryTime) >= QUERY_COOLDOWN
end

local function UpdateItemStatus(itemID, status)
    if not itemID then return end
    NIC_ItemStatus[itemID] = status
    if BuildList then BuildList() end
end

local PendingQueries = {}

local timeoutFrame = CreateFrame("Frame")
timeoutFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = GetTime()
    for id, timeSent in pairs(PendingQueries) do
        if now - timeSent > 1.5 then
            PendingQueries[id] = nil
            if NIC_ItemStatus[id] == "WAIT" then
                UpdateItemStatus(id, "NOT")
            end
        end
    end
end)

function SendQuery(itemID)
    if not itemID then return end
    if not CanQuery() then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[NaerItemCheck]|r Esperá un segundo más...")
        return
    end

    lastQueryTime = GetTime()
    UpdateItemStatus(itemID, "WAIT")
    PendingQueries[itemID] = GetTime()

    local cmd = ".player iteminfo " .. itemID
    SendChatMessage(cmd, "SAY")
end

-- =========================
-- Ventana de Ayuda
-- =========================

helpFrame = CreateFrame("Frame", "NIC_HelpFrame", UIParent)
helpFrame:SetSize(350, 250)
helpFrame:SetPoint("CENTER", 50, 50)
helpFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
helpFrame:Hide()
helpFrame:SetFrameStrata("DIALOG")

local helpTitle = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
helpTitle:SetPoint("TOP", 0, -15)
helpTitle:SetText("Funcionamiento del Addon")

local helpText = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
helpText:SetPoint("TOPLEFT", 20, -45)
helpText:SetPoint("BOTTOMRIGHT", -20, 45)
helpText:SetJustifyH("LEFT")
helpText:SetJustifyV("TOP")
helpText:SetText(
    "1. Selecciona a un jugador como objetivo.\n" ..
    "2. Elige la dificultad de la banda arriba.\n" ..
    "3. Haz clic en un objeto de la lista para consultarlo.\n\n" ..
    "Significado de Colores:\n" ..
    "|cff888888• Gris:|r Objeto no consultado aún.\n" ..
    "|cff00ccff• Celeste:|r Consultando al servidor...\n" ..
    "|cff00ff00• Verde:|r El objetivo tiene el objeto.\n" ..
    "|cffff5555• Rojo:|r El objetivo NO tiene el objeto."
)

local closeHelp = CreateFrame("Button", nil, helpFrame, "UIPanelButtonTemplate")
closeHelp:SetSize(80, 24)
closeHelp:SetPoint("BOTTOM", 0, 15)
closeHelp:SetText("Cerrar")
closeHelp:SetScript("OnClick", function() helpFrame:Hide() end)

-- =========================
-- Frame principal
-- =========================

NIC_Frame = CreateFrame("Frame", "NIC_Frame", UIParent)
NIC_Frame:SetSize(600, 500)
NIC_Frame:SetPoint("CENTER")
NIC_Frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
NIC_Frame:Hide()
tinsert(UISpecialFrames, "NIC_Frame")

NIC_Frame:SetMovable(true)
NIC_Frame:EnableMouse(true)
NIC_Frame:RegisterForDrag("LeftButton")
NIC_Frame:SetScript("OnDragStart", NIC_Frame.StartMoving)
NIC_Frame:SetScript("OnDragStop", NIC_Frame.StopMovingOrSizing)

local title = NIC_Frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -12)
title:SetText("NaerItemCheck")

-- Botones de Control (Cerrar, Ayuda, Editar)
local closeBtn = CreateFrame("Button", nil, NIC_Frame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -5, -5)

local helpBtn = CreateFrame("Button", nil, NIC_Frame)
helpBtn:SetSize(24, 24)
helpBtn:SetPoint("TOPRIGHT", -80, -9)
helpBtn:SetNormalTexture("Interface\\GossipFrame\\ActiveQuestIcon")
helpBtn:SetScript("OnClick", function()
    if helpFrame:IsShown() then helpFrame:Hide() else helpFrame:Show() end
end)

local editBtn = CreateFrame("Button", nil, NIC_Frame)
editBtn:SetSize(22, 22)
editBtn:SetPoint("TOPRIGHT", -50, -10)
editBtn:SetNormalTexture("Interface\\Icons\\INV_Misc_Gear_01")
editBtn:SetScript("OnClick", function()
    if NIC_EditorFrame and NIC_EditorFrame:IsShown() then
        NIC_EditorFrame:Hide()
    else
        ShowEditor()
    end
end)

-- Botón del Minimapa
local NIC_MinimapBtn = CreateFrame("Button", "NIC_MinimapButton", Minimap)
NIC_MinimapBtn:SetSize(31, 31)
NIC_MinimapBtn:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -2, -2)
NIC_MinimapBtn:SetNormalTexture("Interface\\Icons\\INV_Misc_Eye_02")
NIC_MinimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local border = NIC_MinimapBtn:CreateTexture(nil, "OVERLAY")
border:SetSize(53, 53)
border:SetPoint("TOPLEFT")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
NIC_MinimapBtn:SetScript("OnClick", function()
    if NIC_Frame:IsShown() then NIC_Frame:Hide() else NIC_Frame:Show() end
end)
NIC_MinimapBtn:SetMovable(true)
NIC_MinimapBtn:RegisterForDrag("LeftButton")
NIC_MinimapBtn:SetScript("OnDragStart", function(self) self:StartMoving() end)
NIC_MinimapBtn:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

-- Leyenda al pie
local legend = NIC_Frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
legend:SetPoint("BOTTOMLEFT", 30, 15)
legend:SetText("|cff888888Gris: Sin datos|r   |cff00ccffCeleste: Buscando|r   |cff00ff00Ver: Lo tiene|r   |cffff5555Roj: No tiene|r")

-- =========================
-- Lista de Items (Scroll)
-- =========================

local scroll = CreateFrame("ScrollFrame", "NIC_ScrollFrame", NIC_Frame, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 20, -80)
scroll:SetPoint("BOTTOMRIGHT", -40, 45)

local content = CreateFrame("Frame", "NIC_ScrollChild", scroll)
content:SetSize(1, 1)
scroll:SetScrollChild(content)

local rows = {}

local function ClearRows()
    for _, r in ipairs(rows) do r:Hide() end
    wipe(rows)
end

BuildList = function()
    ClearRows()
    local y = -10
    local diffKey = NIC_CurrentSize .. (NIC_IsHeroic and "H" or "N")
    local db = (NaerItemCheckDB and NaerItemCheckDB.Items) or NaerItemsDB
    local data = db and db[NIC_CurrentRaid] and db[NIC_CurrentRaid][diffKey]

    if not data then return end

    for bIdx, boss in ipairs(data) do
        local h = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        h:SetPoint("TOPLEFT", 10, y)
        h:SetText("-" .. boss.boss .. "-")
        table.insert(rows, h)
        y = y - 30

        for iIdx, item in ipairs(boss.items) do
            local btn = CreateFrame("Button", nil, content)
            btn:SetSize(520, 34)
            btn:SetPoint("TOPLEFT", 0, y)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetSize(32, 32)
            icon:SetPoint("LEFT", 4, 0)
            icon:SetTexture(GetItemIcon(item.id) or "Interface\\Icons\\INV_Misc_QuestionMark")

            local name = GetItemInfo(item.id)
            local status = NIC_ItemStatus[item.id]
            local color = "|cff888888"
            if status == "HAS" then color = "|cff00ff00"
            elseif status == "NOT" then color = "|cffff5555"
            elseif status == "WAIT" then color = "|cff00ccff" end

            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            text:SetPoint("LEFT", icon, "RIGHT", 12, 0)
            text:SetText(color .. (name or "Cargando...") .. " |cff777777(" .. item.id .. ")|r")

            btn:SetScript("OnEnter", function() 
                GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
                local success, err = pcall(function() GameTooltip:SetHyperlink("item:" .. item.id) end)
                if not success then GameTooltip:SetText("No se pudo cargar el tooltip (Conflicto con ClassLoot u otro addon)") end
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", GameTooltip_Hide)
            btn:SetScript("OnClick", function() SendQuery(item.id) end)

            table.insert(rows, btn)
            y = y - 36
        end
        y = y - 10
    end
end

-- =========================
-- EDITOR DE IDs
-- =========================

NIC_EditorFrame = CreateFrame("Frame", "NIC_EditorFrame", UIParent)
NIC_EditorFrame:SetSize(400, 500)
NIC_EditorFrame:SetPoint("LEFT", NIC_Frame, "RIGHT", 10, 0)
NIC_EditorFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
NIC_EditorFrame:Hide()
tinsert(UISpecialFrames, "NIC_EditorFrame")

local edScroll = CreateFrame("ScrollFrame", "NIC_EdScroll", NIC_EditorFrame, "UIPanelScrollFrameTemplate")
edScroll:SetPoint("TOPLEFT", 20, -40)
edScroll:SetPoint("BOTTOMRIGHT", -35, 60)
local edContent = CreateFrame("Frame", nil, edScroll)
edContent:SetSize(1, 1)
edScroll:SetScrollChild(edContent)

local ebPool = {}
local fsPool = {}

ShowEditor = function()
    NIC_EditorFrame:Show()
    for _, obj in ipairs(ebPool) do obj:Hide() end
    for _, obj in ipairs(fsPool) do obj:Hide() end

    local diffKey = NIC_CurrentSize .. (NIC_IsHeroic and "H" or "N")
    local db = (NaerItemCheckDB and NaerItemCheckDB.Items) or NaerItemsDB
    local data = db[NIC_CurrentRaid][diffKey]
    local y = -10
    local ebCount, fsCount = 0, 0

    for bIdx, boss in ipairs(data) do
        fsCount = fsCount + 1
        local h = fsPool[fsCount]
        if not h then
            h = edContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            table.insert(fsPool, h)
        end
        h:SetPoint("TOPLEFT", 10, y)
        h:SetText(boss.boss)
        h:Show()
        y = y - 25

        for iIdx, item in ipairs(boss.items) do
            ebCount = ebCount + 1
            local eb = ebPool[ebCount]
            if not eb then
                eb = CreateFrame("EditBox", nil, edContent)
                eb:SetSize(60, 24)
                eb:SetAutoFocus(false)
                eb:SetFontObject("ChatFontNormal")
                eb:SetJustifyH("CENTER")
                eb:SetBackdrop({
                    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true, tileSize = 16, edgeSize = 16,
                    insets = { left = 4, right = 4, top = 4, bottom = 4 }
                })
                eb:SetBackdropColor(0, 0, 0, 0.8)
                eb:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
                table.insert(ebPool, eb)
            end
            eb:ClearAllPoints()
            eb:SetPoint("TOPLEFT", 15, y)
            eb:SetTextInsets(0, 0, 0, 0)
            eb:SetText(tostring(item.id))
            eb:ClearFocus()
            eb.bIdx = bIdx
            eb.iIdx = iIdx
            eb:Show()
            
            fsCount = fsCount + 1
            local name = fsPool[fsCount]
            if not name then
                name = edContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                table.insert(fsPool, name)
            end
            name:ClearAllPoints()
            name:SetPoint("LEFT", eb, "RIGHT", 10, 0)
            name:SetText(GetItemInfo(item.id) or "Item "..item.id)
            name:Show()

            y = y - 28
        end
        y = y - 10
    end
end

local saveBtn = CreateFrame("Button", nil, NIC_EditorFrame, "UIPanelButtonTemplate")
saveBtn:SetSize(130, 25)
saveBtn:SetPoint("BOTTOMLEFT", 20, 15)
saveBtn:SetText("Guardar Cambios")
saveBtn:SetScript("OnClick", function()
    local diffKey = NIC_CurrentSize .. (NIC_IsHeroic and "H" or "N")
    for _, eb in ipairs(editBoxes) do
        if eb:GetObjectType() == "EditBox" then
            local val = tonumber(eb:GetText())
            if val then NaerItemCheckDB.Items[NIC_CurrentRaid][diffKey][eb.bIdx].items[eb.iIdx].id = val end
        end
    end
    print("|cff00ff00[NaerItemCheck]|r Cambios guardados.")
    BuildList()
    NIC_EditorFrame:Hide()
end)

local resetBtn = CreateFrame("Button", nil, NIC_EditorFrame, "UIPanelButtonTemplate")
resetBtn:SetSize(130, 25)
resetBtn:SetPoint("BOTTOMRIGHT", -20, 15)
resetBtn:SetText("Restablecer")
resetBtn:SetScript("OnClick", function()
    StaticPopupDialogs["NIC_RESET_CONFIRM"] = {
        text = "¿Estás seguro de que quieres restablecer todos los IDs a sus valores originales?",
        button1 = "Sí",
        button2 = "No",
        OnAccept = function()
            NaerItemCheckDB.Items = nil
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show("NIC_RESET_CONFIRM")
end)


-- =========================
-- Botones de Modos
-- =========================

local modes = {
    { text = "10 N", size = "10", heroic = false },
    { text = "10 H", size = "10", heroic = true },
    { text = "25 N", size = "25", heroic = false },
    { text = "25 H", size = "25", heroic = true },
}

for i, m in ipairs(modes) do
    local btn = CreateFrame("Button", nil, NIC_Frame, "UIPanelButtonTemplate")
    btn:SetSize(85, 28)
    btn:SetPoint("TOPLEFT", 40 + (i-1)*135, -45)
    btn:SetText(m.text)
    btn:SetScript("OnClick", function()
        NIC_CurrentSize = m.size
        NIC_IsHeroic = m.heroic
        wipe(NIC_ItemStatus)
        BuildList()
        if NIC_EditorFrame and NIC_EditorFrame:IsShown() and ShowEditor then ShowEditor() end
    end)
end

-- =========================
-- Pestañas de Banda (Tabs)
-- =========================

local function Tab_OnClick(self)
    PanelTemplates_SetTab(NIC_Frame, self:GetID())
    if self:GetID() == 1 then
        NIC_CurrentRaid = "ICC"
    else
        NIC_CurrentRaid = "SR"
    end
    wipe(NIC_ItemStatus)
    if BuildList then BuildList() end
    if NIC_EditorFrame and NIC_EditorFrame:IsShown() and ShowEditor then ShowEditor() end
end

NIC_Frame.numTabs = 2

local tab1 = CreateFrame("Button", "NIC_FrameTab1", NIC_Frame, "CharacterFrameTabButtonTemplate")
tab1:SetID(1)
tab1:SetText("ICC")
tab1:SetPoint("BOTTOMLEFT", NIC_Frame, "BOTTOMLEFT", 15, -30)
tab1:SetScript("OnClick", Tab_OnClick)

local tab2 = CreateFrame("Button", "NIC_FrameTab2", NIC_Frame, "CharacterFrameTabButtonTemplate")
tab2:SetID(2)
tab2:SetText("SR")
tab2:SetPoint("LEFT", tab1, "RIGHT", -16, 0)
tab2:SetScript("OnClick", Tab_OnClick)

PanelTemplates_SetNumTabs(NIC_Frame, 2)
PanelTemplates_SetTab(NIC_Frame, 1)

-- Eventos
local listener = CreateFrame("Frame")
listener:RegisterEvent("CHAT_MSG_SYSTEM")
listener:RegisterEvent("PLAYER_TARGET_CHANGED")
listener:SetScript("OnEvent", function(self, event, msg)
    if event == "PLAYER_TARGET_CHANGED" then
        wipe(NIC_ItemStatus)
        if NIC_Frame:IsShown() then BuildList() end
    elseif event == "CHAT_MSG_SYSTEM" then
        local id = tonumber(msg:match("item:(%d+)")) or tonumber(msg:match("ID (%d+)"))
        if id then
            local lowerMsg = msg:lower()
            if lowerMsg:find("no tiene") or lowerMsg:find("doesn't have") or lowerMsg:find("0 copias") or lowerMsg:find("cantidad 0") or lowerMsg:find("no encontr") or lowerMsg:find("no se encontr") then
                UpdateItemStatus(id, "NOT")
            elseif lowerMsg:find("tiene") or lowerMsg:find("has") or lowerMsg:find("encontrado") then
                UpdateItemStatus(id, "HAS")
            end
        end
    end
end)

NIC_Frame:SetScript("OnShow", BuildList)
NIC_Frame:SetScript("OnHide", function()
    if helpFrame and helpFrame:IsShown() then helpFrame:Hide() end
    if NIC_EditorFrame and NIC_EditorFrame:IsShown() then NIC_EditorFrame:Hide() end
end)
