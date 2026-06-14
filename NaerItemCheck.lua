NaerItemCheck = {}
NaerItemCheckDB = NaerItemCheckDB or {}

local function InitializeDB()
    if not NaerItemCheckDB.Items then
        NaerItemCheckDB.Items = {}
        -- Copiar los datos iniciales de NaerItemsDB a la variable persistente
        for raid, difficulties in pairs(NaerItemsDB) do
            NaerItemCheckDB.Items[raid] = {}
            for diff, bosses in pairs(difficulties) do
                NaerItemCheckDB.Items[raid][diff] = {}
                for bossIdx, bossData in ipairs(bosses) do
                    NaerItemCheckDB.Items[raid][diff][bossIdx] = {
                        boss = bossData.boss,
                        items = {}
                    }
                    for itemIdx, itemData in ipairs(bossData.items) do
                        NaerItemCheckDB.Items[raid][diff][bossIdx].items[itemIdx] = {
                            id = itemData.id
                        }
                    end
                end
            end
        end
        print("|cff00ff00[NaerItemCheck]|r Base de datos inicializada por primera vez.")
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "NaerItemCheck" then
        InitializeDB()
        print("|cff00ff00[NaerItemCheck]|r Core cargado y base de datos lista.")
    end
end)

SLASH_NAERITEMCHECK1 = "/nic"
SlashCmdList["NAERITEMCHECK"] = function()
    if NIC_Frame then
        if NIC_Frame:IsShown() then
            NIC_Frame:Hide()
        else
            NIC_Frame:Show()
        end
    end
end
