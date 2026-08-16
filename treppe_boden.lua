-- ============================================
-- Treppen-/Boden-Mechanismus
-- CC:Tweaked + Create + Immersive Engineering (Redstone Wire Connector)
-- Advanced Peripherals (Player Detector)
--
-- Alle Einstellungen kommen aus config.lua -- diese Datei nicht bearbeiten,
-- stattdessen config.lua anpassen.
--
-- Achsen: Z = rauf/runter, X = vor/zurueck
-- Grundposition (Treppe sichtbar):
--   Treppenmodul1: oben (Z eingefahren), am Ende des Gantrys (X ausgefahren)
--   Treppenmodul2: X komplett ausgefahren, am Ende des Gantrys
--   Boden: um 90 Grad gedreht, alles eingefahren
-- ============================================

if not fs.exists("config.lua") then
    error("config.lua nicht gefunden. Bitte zuerst den Installer ausfuehren.")
end
local cfg = dofile("config.lua")

local RUNTIME_FILE = "treppe_runtime.cfg"

local runtime = {
    treppe1 = cfg.distanzen.treppe1,
    treppe2 = cfg.distanzen.treppe2,
    boden   = cfg.distanzen.boden,
}

local function ladeRuntime()
    if fs.exists(RUNTIME_FILE) then
        local f = fs.open(RUNTIME_FILE, "r")
        local data = textutils.unserialize(f.readAll())
        f.close()
        if data then
            for k, v in pairs(data) do runtime[k] = v end
        end
    end
end

local function speichereRuntime()
    local f = fs.open(RUNTIME_FILE, "w")
    f.write(textutils.serialize(runtime))
    f.close()
end

-- ============================================
-- Peripherals
-- ============================================

local function findGearshift(fragment)
    local p = peripheral.find("Create_SequencedGearshift", function(name)
        return string.find(name, fragment) ~= nil
    end)
    if not p then
        error("Gearshift '" .. fragment .. "' nicht gefunden")
    end
    return p
end

local treppe1_aus = findGearshift(cfg.peripherals.treppe1_ausfahren)
local treppe1_ein = findGearshift(cfg.peripherals.treppe1_einfahren)
local treppe2_aus = findGearshift(cfg.peripherals.treppe2_ausfahren)
local treppe2_ein = findGearshift(cfg.peripherals.treppe2_einfahren)
local boden_aus   = findGearshift(cfg.peripherals.boden_ausfahren)
local boden_ein   = findGearshift(cfg.peripherals.boden_einfahren)

local connector = peripheral.find("redstoneWireConnector")
local playerDetector = peripheral.find("playerDetector")

local CH_T1_X_EIN = cfg.farbkanaele.treppe1_x_eingefahren
local CH_T1_X_AUS = cfg.farbkanaele.treppe1_x_ausgefahren
local CH_T2_X_EIN = cfg.farbkanaele.treppe2_x_eingefahren
local CH_T2_X_AUS = cfg.farbkanaele.treppe2_x_ausgefahren
local CH_B_X_EIN  = cfg.farbkanaele.boden_x_eingefahren
local CH_B_X_AUS  = cfg.farbkanaele.boden_x_ausgefahren

local RS_TREPPE1_Z_SIDE = cfg.redstone_seiten.treppe1_z
local RS_BODEN_Z_SIDE   = cfg.redstone_seiten.boden_z
local RS_BODEN_X_SIDE   = cfg.redstone_seiten.boden_x
local RS_TRIGGER_SIDE   = cfg.redstone_seiten.trigger

local PLAYER_RANGE = cfg.spieler.reichweite
local ERLAUBTE_SPIELER = cfg.spieler.erlaubte_spieler

local TIMEOUT_S = cfg.timeout_sekunden
local zustand = "treppe"
local ablaufLaeuft = false

-- ============================================
-- Hilfsfunktionen
-- ============================================

local function warteAufKanal(kanal, zielZustand)
    local start = os.clock()
    while connector.getRedstoneForChannel(kanal) > 0 ~= zielZustand do
        if os.clock() - start > TIMEOUT_S then
            return false
        end
        sleep(0.25)
    end
    return true
end

local function bodenBewegen(gearshift, distanz, zielKanal)
    redstone.setOutput(RS_BODEN_Z_SIDE, true)
    redstone.setOutput(RS_BODEN_X_SIDE, true)
    gearshift.move(distanz, 1)
    warteAufKanal(zielKanal, true)
    redstone.setOutput(RS_BODEN_Z_SIDE, false)
    redstone.setOutput(RS_BODEN_X_SIDE, false)
end

-- ============================================
-- Automatikablauf
-- ============================================

local function treppeVerschwinden()
    redstone.setOutput(RS_TREPPE1_Z_SIDE, true)
    treppe1_ein.move(runtime.treppe1, 1)
    treppe2_ein.move(runtime.treppe2, 1)

    warteAufKanal(CH_T1_X_EIN, true)
    warteAufKanal(CH_T2_X_EIN, true)
    redstone.setOutput(RS_TREPPE1_Z_SIDE, false)

    bodenBewegen(boden_aus, runtime.boden, CH_B_X_AUS)

    zustand = "boden"
end

local function treppeHerstellen()
    bodenBewegen(boden_ein, runtime.boden, CH_B_X_EIN)

    redstone.setOutput(RS_TREPPE1_Z_SIDE, true)
    treppe1_aus.move(runtime.treppe1, 1)
    treppe2_aus.move(runtime.treppe2, 1)

    warteAufKanal(CH_T1_X_AUS, true)
    warteAufKanal(CH_T2_X_AUS, true)
    redstone.setOutput(RS_TREPPE1_Z_SIDE, false)

    zustand = "treppe"
end

local function ausloesen()
    if ablaufLaeuft then return end
    ablaufLaeuft = true
    if zustand == "treppe" then
        treppeVerschwinden()
    else
        treppeHerstellen()
    end
    ablaufLaeuft = false
end

-- ============================================
-- Zugriffskontrolle
-- ============================================

local function erlaubterSpielerInReichweite()
    if not playerDetector then return false end
    for _, name in ipairs(ERLAUBTE_SPIELER) do
        if playerDetector.isPlayerInRange(PLAYER_RANGE, name) then
            return true
        end
    end
    return false
end

-- ============================================
-- Trigger-Ueberwachung
-- ============================================

local function triggerUeberwachung()
    local letzterRSZustand = redstone.getInput(RS_TRIGGER_SIDE)

    while true do
        local aktuellerRS = redstone.getInput(RS_TRIGGER_SIDE)
        if aktuellerRS and not letzterRSZustand then
            ausloesen()
        end
        letzterRSZustand = aktuellerRS

        if erlaubterSpielerInReichweite() then
            ausloesen()
        end

        sleep(0.5)
    end
end

-- ============================================
-- UI
-- ============================================

local function zeichneUI()
    term.clear()
    term.setCursorPos(1, 1)
    print("=== Treppen-/Boden-Steuerung ===")
    print("Status: " .. zustand)
    print("")
    print("-- Distanzen (Blocke) --")
    print("1) Treppe1: " .. runtime.treppe1)
    print("2) Treppe2: " .. runtime.treppe2)
    print("3) Boden:   " .. runtime.boden)
    print("")
    print("-- Manuelle Fahrt --")
    print("4) Treppe1 manuell")
    print("5) Treppe2 manuell")
    print("6) Boden manuell")
    print("")
    print("9) Automatik: Verschwinden/Herstellen")
    print("0) Beenden")
    print("")
    write("Auswahl: ")
end

local function zahlEingabe(prompt, alt)
    write(prompt .. " (" .. alt .. "): ")
    local eingabe = read()
    local n = tonumber(eingabe)
    return n or alt
end

local function treppe1Manuell()
    print("")
    print("Treppe1: a=ausfahren, e=einfahren")
    write("> ")
    local r = read()
    redstone.setOutput(RS_TREPPE1_Z_SIDE, true)
    if r == "a" then treppe1_aus.move(runtime.treppe1, 1)
    elseif r == "e" then treppe1_ein.move(runtime.treppe1, 1) end
    redstone.setOutput(RS_TREPPE1_Z_SIDE, false)
end

local function treppe2Manuell()
    print("")
    print("Treppe2: a=ausfahren, e=einfahren")
    write("> ")
    local r = read()
    if r == "a" then treppe2_aus.move(runtime.treppe2, 1)
    elseif r == "e" then treppe2_ein.move(runtime.treppe2, 1) end
end

local function bodenManuell()
    print("")
    print("Boden: a=ausfahren, e=einfahren")
    write("> ")
    local r = read()
    if r == "a" then bodenBewegen(boden_aus, runtime.boden, CH_B_X_AUS)
    elseif r == "e" then bodenBewegen(boden_ein, runtime.boden, CH_B_X_EIN) end
end

local function uiSchleife()
    while true do
        zeichneUI()
        local auswahl = read()

        if auswahl == "1" then
            runtime.treppe1 = zahlEingabe("Neue Distanz Treppe1", runtime.treppe1)
            speichereRuntime()
        elseif auswahl == "2" then
            runtime.treppe2 = zahlEingabe("Neue Distanz Treppe2", runtime.treppe2)
            speichereRuntime()
        elseif auswahl == "3" then
            runtime.boden = zahlEingabe("Neue Distanz Boden", runtime.boden)
            speichereRuntime()

        elseif auswahl == "4" then treppe1Manuell()
        elseif auswahl == "5" then treppe2Manuell()
        elseif auswahl == "6" then bodenManuell()

        elseif auswahl == "9" then
            ausloesen()

        elseif auswahl == "0" then
            term.clear()
            term.setCursorPos(1, 1)
            return
        end
    end
end

-- ============================================
-- Start
-- ============================================

ladeRuntime()
parallel.waitForAny(uiSchleife, triggerUeberwachung)
