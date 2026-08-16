-- ============================================
-- Installer / Updater fuer Treppen-/Boden-Mechanismus
-- Laedt treppe_boden.lua immer neu (Update), config.lua nur wenn noch nicht vorhanden
-- ============================================

local REPO_BASE = "https://raw.githubusercontent.com/ItIsYe/staircase-floor-mechanism/main/"

local DATEIEN = {
    { name = "treppe_boden.lua", immerUeberschreiben = true },
    { name = "config.lua",       immerUeberschreiben = false },
}

local function herunterladen(dateiname)
    local url = REPO_BASE .. dateiname
    local response = http.get(url)
    if not response then
        print("FEHLER: Konnte " .. dateiname .. " nicht laden (" .. url .. ")")
        return false
    end
    local inhalt = response.readAll()
    response.close()

    local f = fs.open(dateiname, "w")
    f.write(inhalt)
    f.close()
    return true
end

print("=== Installer: Treppen-/Boden-Mechanismus ===")
print("")

for _, datei in ipairs(DATEIEN) do
    if datei.immerUeberschreiben or not fs.exists(datei.name) then
        write("Lade " .. datei.name .. " ... ")
        if herunterladen(datei.name) then
            print("OK")
        else
            print("FEHLGESCHLAGEN")
        end
    else
        print(datei.name .. " existiert bereits, wird nicht ueberschrieben (eigene Einstellungen bleiben erhalten)")
    end
end

print("")
print("Fertig. Start mit: treppe_boden")
print("Erneutes Ausfuehren dieses Installers aktualisiert nur treppe_boden.lua,")
print("config.lua bleibt unberuehrt. Zum Zuruecksetzen der Config: 'rm config.lua'")
print("und den Installer erneut ausfuehren.")
