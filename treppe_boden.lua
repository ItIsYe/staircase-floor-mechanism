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
    treppe1_z = cfg.distanzen.treppe1_z,  -- nur Richtung "ausfahren", "einfahren" ist auto-kalibriert
    boden_z = cfg.distanzen.boden_z,
    boden_a = cfg.distanzen.boden_a,

    auto_schrittgroesse = cfg.auto_kalibrierung.schrittgroesse,
    auto_max_schritte   = cfg.auto_kalibrierung.max_schritte,

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

local RICHTUNG_T1_Y_AUS = cfg.richtung.treppe1_y_ausfahren
local RICHTUNG_T1_Y_EIN = cfg.richtung.treppe1_y_einfahren
local RICHTUNG_T1_Z_AUS = cfg.richtung.treppe1_z_ausfahren
local RICHTUNG_T1_Z_EIN = cfg.richtung.treppe1_z_einfahren
local RICHTUNG_T2_AUS = cfg.richtung.treppe2_ausfahren
local RICHTUNG_T2_EIN = cfg.richtung.treppe2_einfahren
local RICHTUNG_B_X_AUS = cfg.richtung.boden_x_ausfahren
local RICHTUNG_B_X_EIN = cfg.richtung.boden_x_einfahren
local RICHTUNG_B_Z_AUS = cfg.richtung.boden_z_ausfahren
local RICHTUNG_B_Z_EIN = cfg.richtung.boden_z_einfahren
local RICHTUNG_B_A_AUS = cfg.richtung.boden_a_ausfahren
local RICHTUNG_B_A_EIN = cfg.richtung.boden_a_einfahren

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

-- Wartet, bis der Gearshift seine aktuelle Bewegung beendet hat (Polling
-- ueber isRunning(), da es fuer Zwischenschritte keine Relay-Kontakte gibt).
local function wartenBisFertig(gearshift)
    local start = os.clock()
    while gearshift.isRunning() do
        if os.clock() - start > TIMEOUT_S then
            return false
        end
        sleep(0.25)
    end
    return true
end

-- Faehrt in kleinen Schritten, bis zielRelay schaltet, statt einer festen
-- Distanz zu vertrauen. Nur sinnvoll fuer Achsen, die am Zielpunkt einen
-- eigenen (auch kombinierten) Kontakt haben. Sicherheitsabbruch nach
-- runtime.auto_max_schritte Schritten, falls der Kontakt nie schaltet.
local function fahreBisKontakt(gearshift, richtung, zielRelay, beschreibung)
    print(beschreibung .. " (Auto bis Kontakt) ...")
    local schritte = 0
    while not relaisAn(zielRelay) and schritte < runtime.auto_max_schritte do
        gearshift.move(runtime.auto_schrittgroesse, richtung)
        wartenBisFertig(gearshift)
        schritte = schritte + 1
    end
    if relaisAn(zielRelay) then
        print(beschreibung .. ": Kontakt erreicht nach " .. schritte .. " Schritten.")
        return true
    else
        print("WARNUNG: " .. beschreibung .. " -- Kontakt nicht erreicht nach " .. runtime.auto_max_schritte .. " Schritten (Sicherheitsabbruch)")
        return false
    end
end

-- Treppenmodul1 hat 2 Achsenbewegungen (Y, Z) ueber denselben Gearshift.
-- relay_treppe1_z waehlt aus, welche Achse gerade angetrieben wird:
--   Y-Achse: kein Signal
--   Z-Achse: relay_treppe1_z an
-- Deshalb als 2 separate, nacheinander ausgefuehrte Schritte.

local function treppe1Y(gearshift, richtung, zielRelay, beschreibung)
    relaisSetzen(relay_treppe1_z, false)
    fahreBisKontakt(gearshift, richtung, zielRelay, "Treppe1 Y: " .. beschreibung)
end

-- zielRelay optional: nur beim Einfahren (Richtung "unten") vorhanden,
-- da "oben" keinen eigenen Kontakt hat -- dort bleibt es bei fester Distanz.
local function treppe1Z(gearshift, richtung, zielRelay, beschreibung)
    relaisSetzen(relay_treppe1_z, true)
    if zielRelay then
        fahreBisKontakt(gearshift, richtung, zielRelay, "Treppe1 Z: " .. beschreibung)
    else
        print("Treppe1 Z: " .. beschreibung .. " ...")
        gearshift.move(runtime.treppe1_z, richtung)
        wartenBisFertig(gearshift)
        print("Treppe1 Z: " .. beschreibung .. " fertig.")
    end
    relaisSetzen(relay_treppe1_z, false)
end

-- Treppe1 ausfahren (Grundstellung -> Treppe sichtbar): Y zuerst, dann Z
-- (Z darf erst ausfahren, wenn Y bereits ausgefahren ist)
local function treppe1Ausfahren()
    treppe1Y(treppe1_aus, RICHTUNG_T1_Y_AUS, relay_t1_y_ausgefahren, "faehrt aus")
    treppe1Z(treppe1_aus, RICHTUNG_T1_Z_AUS, nil, "faehrt hoch")  -- kein Kontakt fuer "oben"
end

-- Treppe1 einfahren (Treppe -> Grundstellung): Z zuerst, dann Y
-- (Y darf erst fahren, wenn Z bereits unten ist)
local function treppe1Einfahren()
    treppe1Z(treppe1_ein, RICHTUNG_T1_Z_EIN, relay_t1_z_unten, "faehrt runter")
    treppe1Y(treppe1_ein, RICHTUNG_T1_Y_EIN, relay_t1_y_eingefahren, "faehrt ein")
end

-- Treppe2 hat nur eine Achse (Y), beide Endpunkte haben einen Kontakt --
-- Auto-Kalibrierung wie bei Treppe1-Y/Boden-X.
local function treppe2Y(gearshift, richtung, zielRelay, beschreibung)
    fahreBisKontakt(gearshift, richtung, zielRelay, "Treppe2 Y: " .. beschreibung)
end

-- Boden hat nur 2 Gearshifts (aus/ein), aber ALLE 3 Achsen (X, Z, A)
-- laufen ueber denselben Gearshift. Welche Achse gerade angetrieben wird,
-- waehlen die Redstone-Signale (relay_boden_x, relay_boden_z) aus:
--   X-Achse:  kein Signal
--   Z-Achse:  relay_boden_x an
--   A-Achse:  relay_boden_x UND relay_boden_z an
-- Deshalb muessen die 3 Achsen als separate, nacheinander ausgefuehrte
-- Schritte gesteuert werden.

local function bodenX(gearshift, richtung, zielRelay, beschreibung)
    relaisSetzen(relay_boden_z, false)
    relaisSetzen(relay_boden_x, false)
    fahreBisKontakt(gearshift, richtung, zielRelay, "Boden X: " .. beschreibung)
end

local function bodenZ(gearshift, richtung, beschreibung)
    print("Boden Z: " .. beschreibung .. " ...")
    relaisSetzen(relay_boden_x, true)
    gearshift.move(runtime.boden_z, richtung)
    wartenBisFertig(gearshift)
    relaisSetzen(relay_boden_x, false)
    print("Boden Z: " .. beschreibung .. " fertig.")
end

local function bodenA(gearshift, richtung, beschreibung)
    print("Boden A: " .. beschreibung .. " ...")
    relaisSetzen(relay_boden_x, true)
    relaisSetzen(relay_boden_z, true)
    gearshift.rotate(runtime.boden_a, richtung)
    wartenBisFertig(gearshift)
    relaisSetzen(relay_boden_x, false)
    relaisSetzen(relay_boden_z, false)
    print("Boden A: " .. beschreibung .. " fertig.")
end

-- Kompletter Boden-Ablauf einfahren: Z -> X -> A (Reihenfolge bestaetigt)
local function bodenEinfahren()
    bodenZ(boden_ein, RICHTUNG_B_Z_EIN, "faehrt runter")
    bodenX(boden_ein, RICHTUNG_B_X_EIN, relay_b_x_links, "faehrt nach links")
    bodenA(boden_ein, RICHTUNG_B_A_EIN, "dreht auf 90 Grad")
    warteAufRelay(relay_boden_eingefahren_bestaetigt, true)
end

-- Kompletter Boden-Ablauf ausfahren: A -> X -> Z (umgekehrte Reihenfolge)
local function bodenAusfahren()
    bodenA(boden_aus, RICHTUNG_B_A_AUS, "dreht auf 0 Grad")
    bodenX(boden_aus, RICHTUNG_B_X_AUS, relay_b_x_rechts, "faehrt nach rechts")
    bodenZ(boden_aus, RICHTUNG_B_Z_AUS, "faehrt hoch")
    warteAufRelay(relay_boden_ausgefahren_bestaetigt, true)
end

-- ============================================
-- Automatikablauf
-- ============================================

local function treppeVerschwinden()
    print("")
    print("=== Ablauf: Treppe -> Grundstellung ===")

    -- Schritt 1: Treppe1 Z faehrt runter
    treppe1Z(treppe1_ein, RICHTUNG_T1_Z_EIN, relay_t1_z_unten, "faehrt runter")

    -- Schritt 2: Treppe1 Y und Treppe2 Y GLEICHZEITIG
    parallel.waitForAll(
        function() treppe1Y(treppe1_ein, RICHTUNG_T1_Y_EIN, relay_t1_y_eingefahren, "faehrt ein") end,
        function() treppe2Y(treppe2_ein, RICHTUNG_T2_EIN, relay_t2_y_eingefahren, "faehrt ein") end
    )

    -- Schritt 3: Boden Drehung
    bodenA(boden_aus, RICHTUNG_B_A_AUS, "dreht auf 0 Grad")

    -- Schritt 4: Boden X
    bodenX(boden_aus, RICHTUNG_B_X_AUS, relay_b_x_rechts, "faehrt nach rechts")

    -- Schritt 5: Boden Z
    bodenZ(boden_aus, RICHTUNG_B_Z_AUS, "faehrt hoch")

    warteAufRelay(relay_t1_grund_bestaetigt, true)
    warteAufRelay(relay_t2_y_eingefahren, true)
    warteAufRelay(relay_boden_ausgefahren_bestaetigt, true)
    print("Alle Module bestaetigt.")

    zustand = "boden"
    print("=== Ablauf fertig: Grundstellung (Boden sichtbar) ===")
    print("")
end

local function treppeHerstellen()
    print("")
    print("=== Ablauf: Grundstellung -> Treppe ===")

    -- Schritt 1: Boden Z faehrt runter
    bodenZ(boden_ein, RICHTUNG_B_Z_EIN, "faehrt runter")

    -- Schritt 2: Boden X
    bodenX(boden_ein, RICHTUNG_B_X_EIN, relay_b_x_links, "faehrt nach links")

    -- Schritt 3: Boden Drehung, Treppe1 Y und Treppe2 Y GLEICHZEITIG
    parallel.waitForAll(
        function() bodenA(boden_ein, RICHTUNG_B_A_EIN, "dreht auf 90 Grad") end,
        function() treppe1Y(treppe1_aus, RICHTUNG_T1_Y_AUS, relay_t1_y_ausgefahren, "faehrt aus") end,
        function() treppe2Y(treppe2_aus, RICHTUNG_T2_AUS, relay_t2_y_ausgefahren, "faehrt aus") end
    )

    -- Schritt 4: Treppe1 Z faehrt hoch
    treppe1Z(treppe1_aus, RICHTUNG_T1_Z_AUS, nil, "faehrt hoch")

    warteAufRelay(relay_t1_treppe_bestaetigt, true)
    warteAufRelay(relay_t2_y_ausgefahren, true)
    warteAufRelay(relay_boden_eingefahren_bestaetigt, true)
    print("Alle Module bestaetigt.")

    zustand = "treppe"
    print("=== Ablauf fertig: Treppe sichtbar ===")
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
        print("Zustand nicht eindeutig -- Annahme: Grundstellung. Fahre einmalig zur Treppe.")
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
    print("1) Treppe1 Y: auto-kalibriert")
    print("8) Treppe1 Z (ausfahren): " .. runtime.treppe1_z)
    print("2) Treppe2: auto-kalibriert")
    print("3) Boden X: auto-kalibriert")
    print("7) Boden Z: " .. runtime.boden_z)
    print("")
    print("-- Auto-Kalibrierung --")
    print("a) Schrittgroesse: " .. runtime.auto_schrittgroesse .. "  Max. Schritte: " .. runtime.auto_max_schritte)
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
    if r == "a" then treppe1Ausfahren()
    elseif r == "e" then treppe1Einfahren() end
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
    if r == "a" then treppe2Y(treppe2_aus, RICHTUNG_T2_AUS, relay_t2_y_ausgefahren, "faehrt aus")
    elseif r == "e" then treppe2Y(treppe2_ein, RICHTUNG_T2_EIN, relay_t2_y_eingefahren, "faehrt ein") end
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
    if r == "a" then bodenAusfahren()
    elseif r == "e" then bodenEinfahren() end
    verriegelungFreigeben()
end

local function uiSchleife()
    while true do
        zeichneUI()
        local auswahl = read()

        if auswahl == "8" then
            runtime.treppe1_z = zahlEingabe("Neue Distanz Treppe1 Z (ausfahren)", runtime.treppe1_z)
            speichereRuntime()
        elseif auswahl == "7" then
            runtime.boden_z = zahlEingabe("Neue Distanz Boden Z", runtime.boden_z)
            speichereRuntime()
        elseif auswahl == "a" then
            runtime.auto_schrittgroesse = zahlEingabe("Auto-Schrittgroesse", runtime.auto_schrittgroesse)
            runtime.auto_max_schritte = zahlEingabe("Auto max. Schritte", runtime.auto_max_schritte)
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
