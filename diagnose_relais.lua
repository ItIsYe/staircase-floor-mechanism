-- ============================================
-- Diagnose: prueft alle 6 Seiten jedes konfigurierten Relais
-- und schreibt das Ergebnis in relais_diagnose.txt
-- ============================================

if not fs.exists("config.lua") then
    error("config.lua nicht gefunden.")
end
local cfg = dofile("config.lua")

local SEITEN = { "top", "bottom", "left", "right", "front", "back" }

local relais = {
    -- Ausgaenge
    treppe1_z = cfg.redstone_relais.ausgaenge.treppe1_z,
    boden_z   = cfg.redstone_relais.ausgaenge.boden_z,
    boden_x   = cfg.redstone_relais.ausgaenge.boden_x,
    -- Eingaenge
    treppe1_y_ausgefahren = cfg.redstone_relais.eingaenge.treppe1_y_ausgefahren,
    treppe1_y_eingefahren = cfg.redstone_relais.eingaenge.treppe1_y_eingefahren,
    treppe1_z_unten       = cfg.redstone_relais.eingaenge.treppe1_z_unten,
    treppe2_y_ausgefahren = cfg.redstone_relais.eingaenge.treppe2_y_ausgefahren,
    treppe2_y_eingefahren = cfg.redstone_relais.eingaenge.treppe2_y_eingefahren,
    boden_x_links     = cfg.redstone_relais.eingaenge.boden_x_links,
    boden_x_rechts    = cfg.redstone_relais.eingaenge.boden_x_rechts,
    boden_z_unten_a90 = cfg.redstone_relais.eingaenge.boden_z_unten_a90,
    boden_z_oben_a0   = cfg.redstone_relais.eingaenge.boden_z_oben_a0,
}

local konfigurierteSeite = cfg.redstone_relais.seite

local f = fs.open("relais_diagnose.txt", "w")
f.write("Diagnose aller Relais -- konfigurierte Seite: " .. konfigurierteSeite .. "\n")
f.write("=========================================================\n\n")

for schluessel, name in pairs(relais) do
    local p = peripheral.wrap(name)
    if not p then
        f.write(schluessel .. " (" .. name .. "): NICHT GEFUNDEN\n\n")
    else
        f.write(schluessel .. " (" .. name .. "):\n")
        for _, seite in ipairs(SEITEN) do
            local ok, wert = pcall(p.getInput, seite)
            local markierung = ""
            if seite == konfigurierteSeite then
                markierung = "  <-- konfigurierte Seite"
            end
            if ok then
                f.write("  " .. seite .. " = " .. tostring(wert) .. markierung .. "\n")
            else
                f.write("  " .. seite .. " = FEHLER (" .. tostring(wert) .. ")" .. markierung .. "\n")
            end
        end
        f.write("\n")
    end
end

f.close()
print("Diagnose gespeichert in relais_diagnose.txt")
print("Ansehen mit: edit relais_diagnose.txt")
