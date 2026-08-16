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

    rpm_treppe1            = cfg.geschwindigkeiten.rpm.treppe1,
    rpm_treppe2_ausfahren   = cfg.geschwindigkeiten.rpm.treppe2_ausfahren,
    rpm_treppe2_einfahren   = cfg.geschwindigkeiten.rpm.treppe2_einfahren,
    rpm_boden_ausfahren     = cfg.geschwindigkeiten.rpm.boden_ausfahren,
    rpm_boden_einfahren     = cfg.geschwindigkeiten.rpm.boden_einfahren,
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

local function findSpeedController(fragment)
    local p = peripheral.find("Create_RotationSpeedController", function(name)
        return string.find(name, fragment) ~= nil
    end)
    if not p then
        print("WARNUNG: Rotation Speed Controller '" .. fragment .. "' nicht gefunden")
    end
    return p
end

local treppe1_aus = findGearshift(cfg.peripherals.treppe1_ausfahren)
local treppe1_ein = findGearshift(cfg.peripherals.treppe1_einfahren)
local treppe2_aus = findGearshift(cfg.peripherals.treppe2_ausfahren)
local treppe2_ein = findGearshift(cfg.peripherals.treppe2_einfahren)
local boden_aus   = findGearshift(cfg.peripherals.boden_ausfahren)
local boden_ein   = findGearshift(cfg.peripherals.boden_einfahren)

local speed_treppe1           = findSpeedController(cfg.geschwindigkeiten.peripherals.treppe1)
local speed_treppe2_ausfahren = findSpeedController(cfg.geschwindigkeiten.peripherals.treppe2_ausfahren)
local speed_treppe2_einfahren = findSpeedController(cfg.geschwindigkeiten.peripherals.treppe2_einfahren)
local speed_boden_ausfahren   = findSpeedController(cfg.geschwindigkeiten.peripherals.boden_ausfahren)
local speed_boden_einfahren   = findSpeedController(cfg.geschwindigkeiten.peripherals.boden_einfahren)

local connector = peripheral.find("redstoneWireConnector")
if not connector then
    connector = peripheral.find("redstone_wire_connector")
end
if not connector then
    print("FEHLER: Redstone Wire Connector nicht gefunden.")
    print("Vorhandene Peripherals:")
    for _, name in ipairs(peripheral.getNames()) do
        print("  " .. name .. " (" .. tostring(peripheral.getType(name)) .. ")")
    end
    error("Bitte config.lua/Code mit dem richtigen Peripheral-Typnamen aktualisieren.")
end

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
local zustand = nil   -- wird bei der Initialisierung gesetzt: "treppe" oder "boden"
local verriegelt = false  -- true waehrend irgendeine Bewegung laeuft -- blockiert alles andere

local function kanalAn(kanal)
    return connector.getRedstoneForChannel(kanal) > 0
end

-- Prueft per Kontakt, ob ALLE Module tatsaechlich in der zu 'zustand' passenden
-- Endlage stehen. Nur wenn true, darf die naechste Aktion gestartet werden.
local function inEndlage()
    if zustand == "treppe" then
        return kanalAn(CH_T1_X_AUS) and kanalAn(CH_T2_X_AUS) and kanalAn(CH_B_X_EIN)
    elseif zustand == "boden" then
        return kanalAn(CH_T1_X_EIN) and kanalAn(CH_T2_X_EIN) and kanalAn(CH_B_X_AUS)
    end
    return false
end

-- Versucht die Verriegelung zu bekommen. Gibt false zurueck, wenn bereits
-- eine Bewegung laeuft oder das System nicht nachweislich in Endlage ist.
local function verriegelungAnfordern()
    if verriegelt then return false end
    if not inEndlage() then return false end
    verriegelt = true
    return true
end

local function verriegelungFreigeben()
    verriegelt = false
end

-- ============================================
-- Geschwindigkeiten anwenden/lesen
-- ============================================

local function geschwindigkeitSetzen(controller, rpm)
    if not controller then return false end
    controller.setTargetSpeed(rpm)
    return true
end

local function geschwindigkeitLesen(controller)
    if not controller then return nil end
    return controller.getTargetSpeed()
end

local function alleGeschwindigkeitenAnwenden()
    geschwindigkeitSetzen(speed_treppe1, runtime.rpm_treppe1)
    geschwindigkeitSetzen(speed_treppe2_ausfahren, runtime.rpm_treppe2_ausfahren)
    geschwindigkeitSetzen(speed_treppe2_einfahren, runtime.rpm_treppe2_einfahren)
    geschwindigkeitSetzen(speed_boden_ausfahren, runtime.rpm_boden_ausfahren)
    geschwindigkeitSetzen(speed_boden_einfahren, runtime.rpm_boden_einfahren)
end

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
    if not verriegelungAnfordern() then return false end
    if zustand == "treppe" then
        treppeVerschwinden()
    else
        treppeHerstellen()
    end
    verriegelungFreigeben()
    return true
end

-- Erzwingt einen bestimmten Zielzustand (fuer Geofence-Logik, kein Toggle)
local function zielzustandErzwingen(ziel)
    if zustand == ziel then return end
    if not verriegelungAnfordern() then return end
    if ziel == "treppe" then
        treppeHerstellen()
    else
        treppeVerschwinden()
    end
    verriegelungFreigeben()
end

-- ============================================
-- Initialisierung: Zustand beim Start ermitteln
-- ============================================

local function zustandInitialisieren()
    print("Initialisiere Zustand ueber Kontakte ...")

    local treppeErkannt = kanalAn(CH_T1_X_AUS) and kanalAn(CH_T2_X_AUS) and kanalAn(CH_B_X_EIN)
    local bodenErkannt  = kanalAn(CH_T1_X_EIN) and kanalAn(CH_T2_X_EIN) and kanalAn(CH_B_X_AUS)

    if treppeErkannt and not bodenErkannt then
        zustand = "treppe"
        print("Zustand erkannt: Treppe sichtbar")
    elseif bodenErkannt and not treppeErkannt then
        zustand = "boden"
        print("Zustand erkannt: Boden sichtbar")
    else
        print("Zustand nicht eindeutig -- fahre einmalig in Grundstellung (Treppe)")
        zustand = "boden"  -- erzwingt treppeHerstellen() unten
        redstone.setOutput(RS_TREPPE1_Z_SIDE, false)
        redstone.setOutput(RS_BODEN_Z_SIDE, false)
        redstone.setOutput(RS_BODEN_X_SIDE, false)
        treppeHerstellen()
    end
end

-- ============================================
-- Zugriffskontrolle / Geofence
-- ============================================

local function erlaubterSpielerImBereich()
    if not playerDetector then return false end
    for _, name in ipairs(ERLAUBTE_SPIELER) do
        if playerDetector.isPlayerInRange(PLAYER_RANGE, name) then
            return true
        end
    end
    return false
end

-- Solange mind. ein Whitelist-Spieler im Bereich ist: Treppe erzwingen.
-- Verlassen alle Whitelist-Spieler den Bereich: Boden erzwingen (Treppe weg).
-- Redstone-Trigger hat immer Vorrang: waehrend RS_TRIGGER_SIDE aktiv ist,
-- greift die Geofence-Logik nicht ein.
local function geofenceUeberwachung()
    while true do
        if redstone.getInput(RS_TRIGGER_SIDE) then
            -- Redstone hat Vorrang, Geofence pausiert diesen Zyklus
        elseif erlaubterSpielerImBereich() then
            zielzustandErzwingen("treppe")
        else
            zielzustandErzwingen("boden")
        end
        sleep(0.5)
    end
end

-- Manueller Redstone-Trigger bleibt als Override erhalten (Toggle)
local function redstoneTriggerUeberwachung()
    local letzterRSZustand = redstone.getInput(RS_TRIGGER_SIDE)
    while true do
        local aktuellerRS = redstone.getInput(RS_TRIGGER_SIDE)
        if aktuellerRS and not letzterRSZustand then
            ausloesen()
        end
        letzterRSZustand = aktuellerRS
        sleep(0.25)
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
    print("-- Geschwindigkeiten (RPM) --")
    print("g) Geschwindigkeiten anzeigen/aendern")
    print("")
    print("-- Manuelle Fahrt --")
    print("4) Treppe1 manuell")
    print("5) Treppe2 manuell")
    print("6) Boden manuell")
    print("")
    print("9) Automatik: Verschwinden/Herstellen (Toggle)")
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

local function rpmEingabe(prompt, alt)
    write(prompt .. " RPM, -256 bis 256 (" .. alt .. "): ")
    local eingabe = read()
    local n = tonumber(eingabe)
    if n then
        if n > 256 then n = 256 end
        if n < -256 then n = -256 end
        return n
    end
    return alt
end

local function geschwindigkeitenMenu()
    while true do
        term.clear()
        term.setCursorPos(1, 1)
        print("=== Geschwindigkeiten (RPM) ===")
        print("")
        print("1) Treppe1 (gemeinsam):   Soll " .. runtime.rpm_treppe1 ..
              "  Ist " .. tostring(geschwindigkeitLesen(speed_treppe1)))
        print("2) Treppe2 ausfahren:     Soll " .. runtime.rpm_treppe2_ausfahren ..
              "  Ist " .. tostring(geschwindigkeitLesen(speed_treppe2_ausfahren)))
        print("3) Treppe2 einfahren:     Soll " .. runtime.rpm_treppe2_einfahren ..
              "  Ist " .. tostring(geschwindigkeitLesen(speed_treppe2_einfahren)))
        print("4) Boden ausfahren:       Soll " .. runtime.rpm_boden_ausfahren ..
              "  Ist " .. tostring(geschwindigkeitLesen(speed_boden_ausfahren)))
        print("5) Boden einfahren:       Soll " .. runtime.rpm_boden_einfahren ..
              "  Ist " .. tostring(geschwindigkeitLesen(speed_boden_einfahren)))
        print("")
        print("0) Zurueck")
        print("")
        write("Auswahl: ")
        local auswahl = read()

        if auswahl == "1" then
            runtime.rpm_treppe1 = rpmEingabe("Treppe1", runtime.rpm_treppe1)
            geschwindigkeitSetzen(speed_treppe1, runtime.rpm_treppe1)
            speichereRuntime()
        elseif auswahl == "2" then
            runtime.rpm_treppe2_ausfahren = rpmEingabe("Treppe2 ausfahren", runtime.rpm_treppe2_ausfahren)
            geschwindigkeitSetzen(speed_treppe2_ausfahren, runtime.rpm_treppe2_ausfahren)
            speichereRuntime()
        elseif auswahl == "3" then
            runtime.rpm_treppe2_einfahren = rpmEingabe("Treppe2 einfahren", runtime.rpm_treppe2_einfahren)
            geschwindigkeitSetzen(speed_treppe2_einfahren, runtime.rpm_treppe2_einfahren)
            speichereRuntime()
        elseif auswahl == "4" then
            runtime.rpm_boden_ausfahren = rpmEingabe("Boden ausfahren", runtime.rpm_boden_ausfahren)
            geschwindigkeitSetzen(speed_boden_ausfahren, runtime.rpm_boden_ausfahren)
            speichereRuntime()
        elseif auswahl == "5" then
            runtime.rpm_boden_einfahren = rpmEingabe("Boden einfahren", runtime.rpm_boden_einfahren)
            geschwindigkeitSetzen(speed_boden_einfahren, runtime.rpm_boden_einfahren)
            speichereRuntime()
        elseif auswahl == "0" then
            return
        end
    end
end

local function treppe1Manuell()
    print("")
    if not verriegelungAnfordern() then
        print("Gesperrt: System nicht in Endlage oder Bewegung laeuft bereits")
        return
    end
    print("Treppe1: a=ausfahren, e=einfahren")
    write("> ")
    local r = read()
    redstone.setOutput(RS_TREPPE1_Z_SIDE, true)
    if r == "a" then treppe1_aus.move(runtime.treppe1, 1)
    elseif r == "e" then treppe1_ein.move(runtime.treppe1, 1) end
    redstone.setOutput(RS_TREPPE1_Z_SIDE, false)
    verriegelungFreigeben()
end

local function treppe2Manuell()
    print("")
    if not verriegelungAnfordern() then
        print("Gesperrt: System nicht in Endlage oder Bewegung laeuft bereits")
        return
    end
    print("Treppe2: a=ausfahren, e=einfahren")
    write("> ")
    local r = read()
    if r == "a" then treppe2_aus.move(runtime.treppe2, 1)
    elseif r == "e" then treppe2_ein.move(runtime.treppe2, 1) end
    verriegelungFreigeben()
end

local function bodenManuell()
    print("")
    if not verriegelungAnfordern() then
        print("Gesperrt: System nicht in Endlage oder Bewegung laeuft bereits")
        return
    end
    print("Boden: a=ausfahren, e=einfahren")
    write("> ")
    local r = read()
    if r == "a" then bodenBewegen(boden_aus, runtime.boden, CH_B_X_AUS)
    elseif r == "e" then bodenBewegen(boden_ein, runtime.boden, CH_B_X_EIN) end
    verriegelungFreigeben()
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

        elseif auswahl == "g" then
            geschwindigkeitenMenu()

        elseif auswahl == "4" then treppe1Manuell()
        elseif auswahl == "5" then treppe2Manuell()
        elseif auswahl == "6" then bodenManuell()

        elseif auswahl == "9" then
            if not ausloesen() then
                print("")
                print("Gesperrt: System nicht in Endlage oder Bewegung laeuft bereits")
                print("Weiter mit beliebiger Taste ...")
                read()
            end

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
alleGeschwindigkeitenAnwenden()
zustandInitialisieren()
parallel.waitForAny(uiSchleife, redstoneTriggerUeberwachung, geofenceUeberwachung)
