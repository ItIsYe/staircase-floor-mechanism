-- ============================================
-- Relais-Test-Skript (eigenstaendig)
-- Zeigt den Live-Status aller in config.lua konfigurierten Relais und
-- erlaubt es, die Ausgangs-Relais manuell zu schalten -- unabhaengig
-- von Gearshifts/Speed Controllern, die noch nicht vorhanden sein muessen.
-- ============================================

if not fs.exists("config.lua") then
    error("config.lua nicht gefunden. Bitte zuerst den Installer ausfuehren.")
end
local cfg = dofile("config.lua")

local ALLE_SEITEN = { "top", "bottom", "left", "right", "front", "back" }

-- Findet ein Relay per exaktem Namen. Gibt nil zurueck (statt Fehler),
-- damit das Testskript auch funktioniert, wenn einzelne Relais noch
-- fehlen -- die fehlenden werden dann einfach als "NICHT GEFUNDEN" gelistet.
local function relayOderNil(name)
    local ok, p = pcall(peripheral.wrap, name)
    if ok and p then return p end
    return nil
end

local function relaisAn(relay)
    if not relay then return false end
    for _, seite in ipairs(ALLE_SEITEN) do
        if relay.getInput(seite) then return true end
    end
    return false
end

local function relaisSetzen(relay, an)
    if not relay then return end
    for _, seite in ipairs(ALLE_SEITEN) do
        relay.setOutput(seite, an)
    end
end

-- Liste aller konfigurierten Relais: Name, Peripheral-Name, Typ (E/A)
local function baueListe()
    local liste = {}

    local ausgaenge = {
        { label = "Ausgang Treppe1-Z", name = cfg.redstone_relais.ausgaenge.treppe1_z },
        { label = "Ausgang Boden-Z",   name = cfg.redstone_relais.ausgaenge.boden_z },
        { label = "Ausgang Boden-X",   name = cfg.redstone_relais.ausgaenge.boden_x },
    }
    for _, e in ipairs(ausgaenge) do
        table.insert(liste, { label = e.label, name = e.name, relay = relayOderNil(e.name), istEingang = false })
    end

    local eingaenge = {
        { label = "Treppe1 Y ausgefahren", name = cfg.redstone_relais.eingaenge.treppe1_y_ausgefahren },
        { label = "Treppe1 Y eingefahren", name = cfg.redstone_relais.eingaenge.treppe1_y_eingefahren },
        { label = "Treppe1 Z unten",       name = cfg.redstone_relais.eingaenge.treppe1_z_unten },
        { label = "Treppe1 Z unten (bei Y ein)", name = cfg.redstone_relais.eingaenge.treppe1_z_unten_bei_y_eingefahren },
        { label = "Treppe2 Y ausgefahren", name = cfg.redstone_relais.eingaenge.treppe2_y_ausgefahren },
        { label = "Treppe2 Y eingefahren", name = cfg.redstone_relais.eingaenge.treppe2_y_eingefahren },
        { label = "Boden X links",         name = cfg.redstone_relais.eingaenge.boden_x_links },
        { label = "Boden X rechts",        name = cfg.redstone_relais.eingaenge.boden_x_rechts },
        { label = "Boden Z-unten+A90",     name = cfg.redstone_relais.eingaenge.boden_z_unten_a90 },
        { label = "Boden Z-oben+A0",       name = cfg.redstone_relais.eingaenge.boden_z_oben_a0 },
    }
    for _, e in ipairs(eingaenge) do
        table.insert(liste, { label = e.label, name = e.name, relay = relayOderNil(e.name), istEingang = true })
    end

    return liste, ausgaenge
end

local liste, ausgaenge = baueListe()

local function zeichnen()
    term.clear()
    term.setCursorPos(1, 1)
    print("=== Relais-Test ===")
    print("")
    for i, k in ipairs(liste) do
        local typ = k.istEingang and "[E]" or "[A]"
        local status
        if not k.relay then
            status = "NICHT GEFUNDEN (" .. k.name .. ")"
        else
            status = relaisAn(k.relay) and "AN" or "aus"
        end
        print(i .. ") " .. typ .. " " .. k.label .. ": " .. status)
    end
    print("")
    print("Zahl = Ausgang toggeln (nur [A]-Eintraege), r = neu laden, 0 = beenden")
    write("> ")
end

while true do
    zeichnen()
    local eingabe = read()

    if eingabe == "0" then
        term.clear()
        term.setCursorPos(1, 1)
        break
    elseif eingabe == "r" then
        liste, ausgaenge = baueListe()
    else
        local idx = tonumber(eingabe)
        if idx and liste[idx] then
            local eintrag = liste[idx]
            if eintrag.istEingang then
                print("Eingaenge koennen nicht geschaltet werden, nur Ausgaenge [A].")
                sleep(1)
            elseif not eintrag.relay then
                print("Relay nicht gefunden, kann nicht geschaltet werden.")
                sleep(1)
            else
                local aktuell = relaisAn(eintrag.relay)
                relaisSetzen(eintrag.relay, not aktuell)
                print(eintrag.label .. " jetzt: " .. ((not aktuell) and "AN" or "aus"))
                sleep(0.5)
            end
        end
    end
end

