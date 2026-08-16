-- ============================================
-- Treppen-/Boden-Mechanismus
-- CC:Tweaked + Create + Immersive Engineering (Redstone Wire Connector)
-- Advanced Peripherals (Player Detector)
--
-- Achsen: Z = rauf/runter, X = vor/zurueck
-- Grundposition (Treppe sichtbar):
--   Treppenmodul1: oben (Z eingefahren), am Ende des Gantrys (X ausgefahren)
--   Treppenmodul2: X komplett ausgefahren, am Ende des Gantrys
--   Boden: um 90 Grad gedreht, alles eingefahren
-- ============================================

local CONFIG_FILE = "treppe_config.cfg"

local config = {
    treppe1 = 4,
    treppe2 = 4,
    boden   = 2,
}

local function ladeConfig()
    if fs.exists(CONFIG_FILE) then
        local f = fs.open(CONFIG_FILE, "r")
        local data = textutils.unserialize(f.readAll())
        f.close()
        if data then
            for k, v in pairs(data) do config[k] = v end
        end
    end
end

local function speichereConfig()
    local f = fs.open(CONFIG_FILE, "w")
    f.write(textutils.serialize(config))
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

local treppe1_aus = findGearshift("treppe1_ausfahren")
local treppe1_ein = findGearshift("treppe1_einfahren")
local treppe2_aus = findGearshift("treppe2_ausfahren")
local treppe2_ein = findGearshift("treppe2_einfahren")
local boden_aus   = findGearshift("boden_ausfahren")
local boden_ein   = findGearshift("boden_einfahren")

local connector = peripheral.find("redstoneWireConnector")
local playerDetector = peripheral.find("playerDetector")

-- Farbkanaele je Kontaktpunkt (nicht jede Position hat einen Kontakt)
local CH_T1_X_EIN  = "white"
local CH_T1_X_AUS  = "orange"      -- = Z eingefahren
local CH_T2_X_EIN  = "light_blue"
local CH_T2_X_AUS  = "magenta"
local CH_B_X_EIN   = "yellow"
local CH_B_X_AUS   = "lime"        -- = Z unten + X ausgefahren + gedreht

-- Redstone-Seiten, funktionsspezifisch
local RS_TREPPE1_Z_SIDE = "back"   -- Treppe1: Z-Achse, beide Richtungen
local RS_BODEN_Z_SIDE   = "top"    -- Boden: Z-Achse
local RS_BODEN_X_SIDE   = "bottom" -- Boden: X-Achse (zusammen mit Z fuer Drehung noetig)
local RS_TRIGGER_SIDE   = "left"   -- externer Redstone-Trigger fuer Gesamtablauf

-- Zugriffskontrolle Player Detector
local PLAYER_RANGE = 5
local ERLAUBTE_SPIELER = {
    -- "Spielername1",
    -- "Spielername2",
}

local TIMEOUT_S = 15
local zustand = "treppe"  -- "treppe" = Grundposition, "boden" = Boden sichtbar
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
    -- Treppe1 + Treppe2 gleichzeitig einfahren
    redstone.setOutput(RS_TREPPE1_Z_SIDE, true)
    treppe1_ein.move(config.treppe1, 1)
    treppe2_ein.move(config.treppe2, 1)

    warteAufKanal(CH_T1_X_EIN, true)
    warteAufKanal(CH_T2_X_EIN, true)
    redstone.setOutput(RS_TREPPE1_Z_SIDE, false)

    -- Erst danach: Boden ausfahren (inkl. Drehung in der Gearshift-Sequenz)
    bodenBewegen(boden_aus, config.boden, CH_B_X_AUS)

    zustand = "boden"
end

local function treppeHerstellen()
    -- Boden einfahren (inkl. Ruecksdrehung in der Gearshift-Sequenz)
    bodenBewegen(boden_ein, config.boden, CH_B_X_EIN)

    -- Treppe1 + Treppe2 gleichzeitig ausfahren
    redstone.setOutput(RS_TREPPE1_Z_SIDE, true)
    treppe1_aus.move(config.treppe1, 1)
    treppe2_aus.move(config.treppe2, 1)

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
-- Trigger-Ueberwachung (Redstone + Player Detector parallel)
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
    print("1) Treppe1: " .. config.treppe1)
    print("2) Treppe2: " .. config.treppe2)
    print("3) Boden:   " .. config.boden)
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
    if r == "a" then treppe1_aus.move(config.treppe1, 1)
    elseif r == "e" then treppe1_ein.move(config.treppe1, 1) end
    redstone.setOutput(RS_TREPPE1_Z_SIDE, false)
end

local function treppe2Manuell()
    print("")
    print("Treppe2: a=ausfahren, e=einfahren")
    write("> ")
    local r = read()
    if r == "a" then treppe2_aus.move(config.treppe2, 1)
    elseif r == "e" then treppe2_ein.move(config.treppe2, 1) end
end

local function bodenManuell()
    print("")
    print("Boden: a=ausfahren, e=einfahren")
    write("> ")
    local r = read()
    if r == "a" then bodenBewegen(boden_aus, config.boden, CH_B_X_AUS)
    elseif r == "e" then bodenBewegen(boden_ein, config.boden, CH_B_X_EIN) end
end

local function uiSchleife()
    while true do
        zeichneUI()
        local auswahl = read()

        if auswahl == "1" then
            config.treppe1 = zahlEingabe("Neue Distanz Treppe1", config.treppe1)
            speichereConfig()
        elseif auswahl == "2" then
            config.treppe2 = zahlEingabe("Neue Distanz Treppe2", config.treppe2)
            speichereConfig()
        elseif auswahl == "3" then
            config.boden = zahlEingabe("Neue Distanz Boden", config.boden)
            speichereConfig()

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

ladeConfig()
parallel.waitForAny(uiSchleife, triggerUeberwachung)
