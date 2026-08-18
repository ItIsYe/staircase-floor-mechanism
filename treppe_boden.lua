-- ============================================
-- Treppen-/Boden-Mechanismus
-- CC:Tweaked + Create + Advanced Peripherals (Player Detector)
--
-- Alle Redstone-Signale (Ausgaenge UND Positionskontakte) laufen ueber
-- dedizierte Redstone-Relais -- ein Relay pro Signal, Seite am Relay egal.
-- Einzige Ausnahme: der Trigger ist der einzige physisch am Computer
-- verkabelte Redstone-Input.
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

local function findGearshift(exakterName)
    local p = peripheral.wrap(exakterName)
    if not p then
        local f = fs.open("relay_fehler.txt", "w")
        f.write("Gesuchter Gearshift-Name (nicht gefunden): " .. exakterName .. "\n\n")
        f.write("Vorhandene Peripherals:\n")
        local namen = peripheral.getNames()
        table.sort(namen)
        for _, name in ipairs(namen) do
            f.write("  " .. name .. " (" .. tostring(peripheral.getType(name)) .. ")\n")
        end
        f.close()
        print("FEHLER: Gearshift '" .. exakterName .. "' nicht gefunden.")
        print("Details in relay_fehler.txt gespeichert (edit relay_fehler.txt)")
        error("Bitte config.lua mit dem richtigen Peripheral-Namen aktualisieren.")
    end
    return p
end

local function findSpeedController(exakterName)
    local p = peripheral.wrap(exakterName)
    if not p then
        print("WARNUNG: Rotation Speed Controller '" .. exakterName .. "' nicht gefunden")
    end
    return p
end

local function findRelay(exakterName)
    local p = peripheral.wrap(exakterName)
    if not p then
        local f = fs.open("relay_fehler.txt", "w")
        f.write("Gesuchter Relay-Name (nicht gefunden): " .. exakterName .. "\n\n")
        f.write("Vorhandene Peripherals:\n")
        local namen = peripheral.getNames()
        table.sort(namen)
        for _, name in ipairs(namen) do
            f.write("  " .. name .. " (" .. tostring(peripheral.getType(name)) .. ")\n")
        end
        f.close()
        print("FEHLER: Redstone Relay '" .. exakterName .. "' nicht gefunden.")
        print("Details in relay_fehler.txt gespeichert (edit relay_fehler.txt)")
        error("Bitte config.lua mit dem richtigen Relay-Namen aktualisieren.")
    end
    return p
end

local treppe1_aus = findGearshift(cfg.peripherals.treppe1_ausfahren)
local treppe1_ein = findGearshift(cfg.peripherals.treppe1_einfahren)
local treppe2_aus = findGearshift(cfg.peripherals.treppe2_ausfahren)
local treppe2_ein = findGearshift(cfg.peripherals.treppe2_einfahren)
local boden_aus   = findGearshift(cfg.peripherals.boden_ausfahren)
local boden_ein   = findGearshift(cfg.peripherals.boden_einfahren)

local RICHTUNG_T1_AUS = cfg.richtung.treppe1_ausfahren
local RICHTUNG_T1_EIN = cfg.richtung.treppe1_einfahren
local RICHTUNG_T2_AUS = cfg.richtung.treppe2_ausfahren
local RICHTUNG_T2_EIN = cfg.richtung.treppe2_einfahren
local RICHTUNG_B_AUS  = cfg.richtung.boden_ausfahren
local RICHTUNG_B_EIN  = cfg.richtung.boden_einfahren

local speed_treppe1           = findSpeedController(cfg.geschwindigkeiten.peripherals.treppe1)
local speed_treppe2_ausfahren = findSpeedController(cfg.geschwindigkeiten.peripherals.treppe2_ausfahren)
local speed_treppe2_einfahren = findSpeedController(cfg.geschwindigkeiten.peripherals.treppe2_einfahren)
local speed_boden_ausfahren   = findSpeedController(cfg.geschwindigkeiten.peripherals.boden_ausfahren)
local speed_boden_einfahren   = findSpeedController(cfg.geschwindigkeiten.peripherals.boden_einfahren)

-- Ausgangs-Relais (Ansteuerung)
local relay_treppe1_z = findRelay(cfg.redstone_relais.ausgaenge.treppe1_z)
local relay_boden_z   = findRelay(cfg.redstone_relais.ausgaenge.boden_z)
local relay_boden_x   = findRelay(cfg.redstone_relais.ausgaenge.boden_x)

-- Eingangs-Relais (Positionskontakte) -- NEU DEFINIERT

-- Treppenmodul1: Y-Achse (beide Endpunkte) + Z-Achse (nur unten)
local relay_t1_y_ausgefahren = findRelay(cfg.redstone_relais.eingaenge.treppe1_y_ausgefahren)
local relay_t1_y_eingefahren = findRelay(cfg.redstone_relais.eingaenge.treppe1_y_eingefahren)
local relay_t1_z_unten       = findRelay(cfg.redstone_relais.eingaenge.treppe1_z_unten)

-- Treppe1 "Treppe"-Zustand: Y ausgefahren allein (kein Z-oben-Kontakt vorhanden)
-- Treppe1 "Grundstellung"-Zustand (verschwunden): Y eingefahren UND Z unten zusammen
local relay_t1_treppe_bestaetigt = relay_t1_y_ausgefahren
local relay_t1_grund_bestaetigt = {
    getInput = function(side)
        return relay_t1_y_eingefahren.getInput(side) and relay_t1_z_unten.getInput(side)
    end
}

-- Treppenmodul2: nur Y-Achse (beide Endpunkte, je ein eigener Kontakt)
local relay_t2_y_ausgefahren = findRelay(cfg.redstone_relais.eingaenge.treppe2_y_ausgefahren)
local relay_t2_y_eingefahren = findRelay(cfg.redstone_relais.eingaenge.treppe2_y_eingefahren)

-- Boden: X-Achse (beide Endpunkte) + kombinierte Z/A-Kontakte
local relay_b_x_links  = findRelay(cfg.redstone_relais.eingaenge.boden_x_links)
local relay_b_x_rechts = findRelay(cfg.redstone_relais.eingaenge.boden_x_rechts)
local relay_b_z_unten_a90 = findRelay(cfg.redstone_relais.eingaenge.boden_z_unten_a90)
local relay_b_z_oben_a0   = findRelay(cfg.redstone_relais.eingaenge.boden_z_oben_a0)

-- Boden "Grundstellung" (X rechts + Z oben + A 0Grad) bedeutet: Boden ist
-- AUSGEFAHREN/sichtbar -- das gehoert zum Gesamtzustand "boden" (Treppe
-- NICHT sichtbar), nicht zu "treppe".
local relay_boden_ausgefahren_bestaetigt = {
    getInput = function(side)
        return relay_b_x_rechts.getInput(side) and relay_b_z_oben_a0.getInput(side)
    end
}

-- Boden "eingefahren" (X links + Z unten + A 90Grad) bedeutet: Boden ist
-- zurueckgezogen -- das gehoert zum Gesamtzustand "treppe" (Treppe sichtbar).
local relay_boden_eingefahren_bestaetigt = {
    getInput = function(side)
        return relay_b_x_links.getInput(side) and relay_b_z_unten_a90.getInput(side)
    end
}

local playerDetector = peripheral.find("playerDetector")

local RS_TRIGGER_SIDE = cfg.redstone_trigger.seite

local PLAYER_RANGE = cfg.spieler.reichweite
local ERLAUBTE_SPIELER = cfg.spieler.erlaubte_spieler

local TIMEOUT_S = cfg.timeout_sekunden
local zustand = nil
local verriegelt = false

-- ============================================
-- Relais-Hilfsfunktionen
-- ============================================

-- Die konkrete Seite ist am Relay physisch egal (jedes Relay traegt nur
-- ein Signal) -- die Peripheral-API verlangt aber immer eine Seite als
-- Parameter. Deshalb: bei Eingaengen alle 6 Seiten pruefen (ODER-
-- Verknuepfung), bei Ausgaengen alle 6 Seiten gleichzeitig setzen.
local ALLE_SEITEN = { "top", "bottom", "left", "right", "front", "back" }

local function relaisAn(inputRelay)
    for _, seite in ipairs(ALLE_SEITEN) do
        if inputRelay.getInput(seite) then
            return true
        end
    end
    return false
end

local function relaisSetzen(outputRelay, an)
    for _, seite in ipairs(ALLE_SEITEN) do
        outputRelay.setOutput(seite, an)
    end
end

local function inEndlage()
    if zustand == "treppe" then
        return relaisAn(relay_t1_treppe_bestaetigt) and relaisAn(relay_t2_y_ausgefahren) and relaisAn(relay_boden_eingefahren_bestaetigt)
    elseif zustand == "boden" then
        return relaisAn(relay_t1_grund_bestaetigt) and relaisAn(relay_t2_y_eingefahren) and relaisAn(relay_boden_ausgefahren_bestaetigt)
    end
    return false
end

local function verriegelungAnfordern()
    if verriegelt then return false end
    if not inEndlage() then return false end
    verriegelt = true
    return true
end

-- Fuer manuelle Einzeltests (Menuepunkte 4/5/6): prueft NUR, ob gerade
-- schon eine andere Bewegung laeuft -- NICHT, ob das gesamte System
-- (alle 3 Module) in Endlage ist. So lassen sich Module einzeln testen,
-- auch wenn andere Module noch nicht vollstaendig verkabelt/bestaetigt sind.
local function verriegelungAnfordernManuell()
    if verriegelt then return false end
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

local function warteAufRelay(inputRelay, zielZustand)
    local start = os.clock()
    while relaisAn(inputRelay) ~= zielZustand do
        if os.clock() - start > TIMEOUT_S then
            return false
        end
        sleep(0.25)
    end
    return true
end

local function bodenBewegen(gearshift, distanz, richtung, zielRelay, beschreibung)
    print("Boden: " .. beschreibung .. " ...")
    relaisSetzen(relay_boden_z, true)
    relaisSetzen(relay_boden_x, true)
    gearshift.move(distanz, richtung)
    warteAufRelay(zielRelay, true)
    relaisSetzen(relay_boden_z, false)
    relaisSetzen(relay_boden_x, false)
    print("Boden: " .. beschreibung .. " fertig.")
end

-- ============================================
-- Automatikablauf
-- ============================================

local function treppeVerschwinden()
    print("")
    print("=== Ablauf: Treppe -> Boden ===")

    print("Treppe1 + Treppe2: fahre ein ...")
    relaisSetzen(relay_treppe1_z, true)
    treppe1_ein.move(runtime.treppe1, RICHTUNG_T1_EIN)
    treppe2_ein.move(runtime.treppe2, RICHTUNG_T2_EIN)

    warteAufRelay(relay_t1_grund_bestaetigt, true)
    warteAufRelay(relay_t2_y_eingefahren, true)
    relaisSetzen(relay_treppe1_z, false)
    print("Treppe1 + Treppe2: eingefahren, bestaetigt.")

    bodenBewegen(boden_aus, runtime.boden, RICHTUNG_B_AUS, relay_boden_ausgefahren_bestaetigt, "fahre aus (X/Z/Drehung)")

    zustand = "boden"
    print("=== Ablauf fertig: Boden sichtbar ===")
    print("")
end

local function treppeHerstellen()
    print("")
    print("=== Ablauf: Boden -> Treppe (Grundstellung) ===")

    bodenBewegen(boden_ein, runtime.boden, RICHTUNG_B_EIN, relay_boden_eingefahren_bestaetigt, "fahre ein (X/Z/Drehung)")

    print("Treppe1 + Treppe2: fahre aus ...")
    relaisSetzen(relay_treppe1_z, true)
    treppe1_aus.move(runtime.treppe1, RICHTUNG_T1_AUS)
    treppe2_aus.move(runtime.treppe2, RICHTUNG_T2_AUS)

    warteAufRelay(relay_t1_treppe_bestaetigt, true)
    warteAufRelay(relay_t2_y_ausgefahren, true)
    relaisSetzen(relay_treppe1_z, false)
    print("Treppe1 + Treppe2: ausgefahren, bestaetigt.")

    zustand = "treppe"
    print("=== Ablauf fertig: Grundstellung (Treppe sichtbar) ===")
    print("")
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
-- Initialisierung
-- ============================================

local function zustandInitialisieren()
    print("Initialisiere Zustand ueber Relais-Kontakte ...")

    local treppeErkannt = relaisAn(relay_t1_treppe_bestaetigt) and relaisAn(relay_t2_y_ausgefahren) and relaisAn(relay_boden_eingefahren_bestaetigt)
    local bodenErkannt  = relaisAn(relay_t1_grund_bestaetigt) and relaisAn(relay_t2_y_eingefahren) and relaisAn(relay_boden_ausgefahren_bestaetigt)

    if treppeErkannt and not bodenErkannt then
        zustand = "treppe"
        print("Zustand erkannt: Treppe sichtbar")
    elseif bodenErkannt and not treppeErkannt then
        zustand = "boden"
        print("Zustand erkannt: Boden sichtbar")
    else
        print("Zustand nicht eindeutig -- fahre einmalig in Grundstellung (Treppe)")
        zustand = "boden"
        relaisSetzen(relay_treppe1_z, false)
        relaisSetzen(relay_boden_z, false)
        relaisSetzen(relay_boden_x, false)
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

local function geofenceUeberwachung()
    while true do
        if redstone.getInput(RS_TRIGGER_SIDE) then
            -- Redstone hat Vorrang
        elseif erlaubterSpielerImBereich() then
            zielzustandErzwingen("treppe")
        else
            zielzustandErzwingen("boden")
        end
        sleep(0.5)
    end
end

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
    if not verriegelungAnfordernManuell() then
        print("Gesperrt: System nicht in Endlage oder Bewegung laeuft bereits")
        print("Weiter mit beliebiger Taste ...")
        read()
        return
    end
    print("Treppe1: a=ausfahren, e=einfahren")
    write("> ")
    local r = read()
    relaisSetzen(relay_treppe1_z, true)
    if r == "a" then treppe1_aus.move(runtime.treppe1, RICHTUNG_T1_AUS)
    elseif r == "e" then treppe1_ein.move(runtime.treppe1, RICHTUNG_T1_EIN) end
    relaisSetzen(relay_treppe1_z, false)
    verriegelungFreigeben()
end

local function treppe2Manuell()
    print("")
    if not verriegelungAnfordernManuell() then
        print("Gesperrt: System nicht in Endlage oder Bewegung laeuft bereits")
        print("Weiter mit beliebiger Taste ...")
        read()
        return
    end
    print("Treppe2: a=ausfahren, e=einfahren")
    write("> ")
    local r = read()
    if r == "a" then treppe2_aus.move(runtime.treppe2, RICHTUNG_T2_AUS)
    elseif r == "e" then treppe2_ein.move(runtime.treppe2, RICHTUNG_T2_EIN) end
    verriegelungFreigeben()
end

local function bodenManuell()
    print("")
    if not verriegelungAnfordernManuell() then
        print("Gesperrt: System nicht in Endlage oder Bewegung laeuft bereits")
        print("Weiter mit beliebiger Taste ...")
        read()
        return
    end
    print("Boden: a=ausfahren, e=einfahren")
    write("> ")
    local r = read()
    if r == "a" then bodenBewegen(boden_aus, runtime.boden, RICHTUNG_B_AUS, relay_boden_ausgefahren_bestaetigt, "fahre aus (manuell)")
    elseif r == "e" then bodenBewegen(boden_ein, runtime.boden, RICHTUNG_B_EIN, relay_boden_eingefahren_bestaetigt, "fahre ein (manuell)") end
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
