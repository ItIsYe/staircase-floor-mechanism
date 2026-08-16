-- ============================================
-- Installer / Updater fuer Treppen-/Boden-Mechanismus
--
-- treppe_boden.lua wird bei jedem Lauf komplett aktualisiert.
-- config.lua wird bei Bedarf MIGRIERT statt ueberschrieben:
--   - neue Felder aus der Vorlage werden ergaenzt
--   - bereits gesetzte eigene Werte bleiben erhalten
--   - entfallene Felder werden entfernt
-- ============================================

local REPO_BASE = "https://raw.githubusercontent.com/ItIsYe/staircase-floor-mechanism/main/"
local CONFIG_NAME = "config.lua"
local CONFIG_TEMPLATE_TMP = ".config_template.lua"

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

-- ============================================
-- Config-Migration
-- ============================================

-- Rekursives Mergen: Werte aus 'alt' haben Vorrang, Struktur/neue Felder aus 'neu'
local function mergeConfig(alt, neu)
    if type(neu) ~= "table" then
        return alt ~= nil and alt or neu
    end
    if type(alt) ~= "table" then
        return neu
    end

    local ergebnis = {}
    for schluessel, neuerWert in pairs(neu) do
        local alterWert = alt[schluessel]
        if type(neuerWert) == "table" then
            ergebnis[schluessel] = mergeConfig(alterWert, neuerWert)
        else
            if alterWert ~= nil then
                ergebnis[schluessel] = alterWert
            else
                ergebnis[schluessel] = neuerWert
            end
        end
    end
    return ergebnis
end

local function tabelleSerialisieren(t, einrueckung)
    einrueckung = einrueckung or ""
    local naechsteEinrueckung = einrueckung .. "    "
    local zeilen = { "{" }

    -- Numerische Liste (z.B. erlaubte_spieler) getrennt behandeln
    local istListe = true
    local n = 0
    for k, _ in pairs(t) do
        n = n + 1
        if type(k) ~= "number" then istListe = false end
    end

    if istListe and n > 0 then
        for _, v in ipairs(t) do
            if type(v) == "table" then
                table.insert(zeilen, naechsteEinrueckung .. tabelleSerialisieren(v, naechsteEinrueckung) .. ",")
            elseif type(v) == "string" then
                table.insert(zeilen, naechsteEinrueckung .. string.format("%q", v) .. ",")
            else
                table.insert(zeilen, naechsteEinrueckung .. tostring(v) .. ",")
            end
        end
    else
        for k, v in pairs(t) do
            local schluesselStr
            if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                schluesselStr = k
            else
                schluesselStr = "[" .. string.format("%q", tostring(k)) .. "]"
            end

            if type(v) == "table" then
                table.insert(zeilen, naechsteEinrueckung .. schluesselStr .. " = " .. tabelleSerialisieren(v, naechsteEinrueckung) .. ",")
            elseif type(v) == "string" then
                table.insert(zeilen, naechsteEinrueckung .. schluesselStr .. " = " .. string.format("%q", v) .. ",")
            elseif type(v) == "boolean" or type(v) == "number" then
                table.insert(zeilen, naechsteEinrueckung .. schluesselStr .. " = " .. tostring(v) .. ",")
            end
        end
    end

    table.insert(zeilen, einrueckung .. "}")
    return table.concat(zeilen, "\n")
end

local function configMigrieren()
    print("Pruefe config.lua auf Updates ...")

    local templateText = herunterladenAlsText(CONFIG_NAME)
    if not templateText then
        print("FEHLER: Konnte neue config.lua-Vorlage nicht laden")
        return false
    end
    dateiSchreiben(CONFIG_TEMPLATE_TMP, templateText)

    local ok, neueVorlage = pcall(dofile, CONFIG_TEMPLATE_TMP)
    if not ok or type(neueVorlage) ~= "table" then
        print("FEHLER: Neue config.lua-Vorlage ist ungueltig")
        fs.delete(CONFIG_TEMPLATE_TMP)
        return false
    end

    if not fs.exists(CONFIG_NAME) then
        fs.delete(CONFIG_TEMPLATE_TMP)
        dateiSchreiben(CONFIG_NAME, templateText)
        print("config.lua neu angelegt (Erstinstallation)")
        return true
    end

    local okAlt, alteConfig = pcall(dofile, CONFIG_NAME)
    fs.delete(CONFIG_TEMPLATE_TMP)

    if not okAlt or type(alteConfig) ~= "table" then
        print("WARNUNG: Bestehende config.lua ist beschaedigt, wird durch Vorlage ersetzt")
        dateiSchreiben(CONFIG_NAME, templateText)
        return true
    end

    local alteVersion = alteConfig.config_version or 0
    local neueVersion = neueVorlage.config_version or 0

    if alteVersion >= neueVersion then
        print("config.lua ist aktuell (Version " .. alteVersion .. "), keine Migration noetig")
        return true
    end

    print("Migriere config.lua von Version " .. alteVersion .. " auf " .. neueVersion .. " ...")

    local gemergt = mergeConfig(alteConfig, neueVorlage)
    gemergt.config_version = neueVersion

    local inhalt = "-- Automatisch migriert vom Installer -- eigene Werte wurden uebernommen\nreturn " .. tabelleSerialisieren(gemergt) .. "\n"
    dateiSchreiben(CONFIG_NAME, inhalt)

    print("config.lua migriert. Eigene Einstellungen wurden beibehalten,")
    print("neue Felder mit Standardwerten ergaenzt.")
    return true
end

-- ============================================
-- Ablauf
-- ============================================

print("=== Installer: Treppen-/Boden-Mechanismus ===")
print("")

write("Lade treppe_boden.lua ... ")
local skriptText = herunterladenAlsText("treppe_boden.lua")
if skriptText then
    dateiSchreiben("treppe_boden.lua", skriptText)
    print("OK")
else
    print("FEHLGESCHLAGEN")
end

configMigrieren()

print("")
print("Fertig. Start mit: treppe_boden")
print("Erneutes Ausfuehren dieses Installers aktualisiert treppe_boden.lua")
print("und migriert config.lua automatisch (eigene Werte bleiben erhalten).")
