-- ============================================
-- Installer / Updater fuer Treppen-/Boden-Mechanismus
--
-- Ersetzt bei JEDEM Lauf ALLE Dateien vollstaendig durch den aktuellen
-- Stand aus dem Repo (treppe_boden.lua, config.lua, startup.lua) --
-- keine Migration, kein Zusammenfuehren. Eigene Kalibrierungswerte
-- (Distanzen, Richtungen, Relay-Namen usw.) muessen daher direkt im
-- Repo (config.lua) gepflegt werden, nicht nur lokal auf dem Computer.
-- ============================================

local REPO_BASE = "https://raw.githubusercontent.com/ItIsYe/staircase-floor-mechanism/main/"

local DATEIEN = {
    "treppe_boden.lua",
    "config.lua",
}

local function herunterladenAlsText(dateiname)
    local url = REPO_BASE .. dateiname
    local response = http.get(url)
    if not response then
        return nil
    end
    local inhalt = response.readAll()
    response.close()
    return inhalt
end

local function dateiSchreiben(dateiname, inhalt)
    local f = fs.open(dateiname, "w")
    f.write(inhalt)
    f.close()
end

print("=== Installer: Treppen-/Boden-Mechanismus ===")
print("Ersetzt ALLE Dateien vollstaendig durch den aktuellen Repo-Stand.")
print("")

local alleOk = true

for _, dateiname in ipairs(DATEIEN) do
    write("Lade " .. dateiname .. " ... ")
    local inhalt = herunterladenAlsText(dateiname)
    if inhalt then
        dateiSchreiben(dateiname, inhalt)
        print("OK")
    else
        print("FEHLGESCHLAGEN")
        alleOk = false
    end
end

-- startup.lua: startet treppe_boden.lua automatisch bei jedem PC-Boot.
-- Wird bei jedem Installer-Lauf neu geschrieben.
write("Schreibe startup.lua ... ")
local startupInhalt = [[
-- Automatisch vom Installer erzeugt. Startet den Treppen-/Boden-Mechanismus
-- bei jedem Boot des Computers. Nicht manuell bearbeiten -- Aenderungen
-- gehoeren in treppe_boden.lua bzw. config.lua.

while true do
    local ok, fehler = pcall(function()
        shell.run("treppe_boden.lua")
    end)
    if not ok then
        print("Fehler in treppe_boden.lua: " .. tostring(fehler))
        print("Neustart in 5 Sekunden ...")
        sleep(5)
    else
        -- Normales Beenden ueber Menuepunkt 0 -- Startup-Schleife verlassen
        break
    end
end
]]
dateiSchreiben("startup.lua", startupInhalt)
print("OK")

print("")
if alleOk then
    print("Fertig. Alle Dateien wurden vollstaendig ersetzt.")
    print("Der Mechanismus startet ab jetzt automatisch bei jedem PC-Neustart.")
    print("Manueller Start jederzeit moeglich mit: treppe_boden")
else
    print("WARNUNG: Mindestens eine Datei konnte nicht geladen werden.")
    print("Bitte Internetverbindung/Netzwerkfreigabe pruefen und erneut versuchen.")
end
print("Erneutes Ausfuehren dieses Installers ersetzt ALLE Dateien wieder komplett.")
