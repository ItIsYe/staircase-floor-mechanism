-- ============================================
-- Konfigurationsdatei Treppen-/Boden-Mechanismus
-- Alle Werte hier anpassen, treppe_boden.lua nicht veraendern
--
-- WICHTIG: Alle Peripheral-Namen unten sind EXAKTE Namen, keine
-- Textfragmente (peripheral.wrap statt peripheral.find-Substring-Suche).
--
-- Achsen: Z = hoch/runter, X = links/rechts, Y = vor/zurueck, A = Drehachse
--
-- config_version wird vom Installer genutzt, um bei Updates neue
-- Einstellungsfelder automatisch zu ergaenzen, ohne bestehende
-- Werte zu ueberschreiben. Nicht manuell aendern.
-- ============================================

return {

    config_version = 27,

    -- Exakte Peripheral-Namen der Sequenced Gearshifts
    peripherals = {
        treppe1_ausfahren = "Create_SequencedGearshift_2",
        treppe1_einfahren = "Create_SequencedGearshift_1",
        treppe2_ausfahren = "Create_SequencedGearshift_4",
        treppe2_einfahren = "Create_SequencedGearshift_3",
        boden_ausfahren   = "Create_SequencedGearshift_6",
        boden_einfahren   = "Create_SequencedGearshift_5",
    },

    -- Exakter Peripheral-Name des Player Detectors (Advanced Peripherals)
    player_detector_name = "player_detector_0",

    -- Richtungsmodifier je Gearshift: 1 oder -1. Falls ein Gearshift beim
    -- Ausfahren tatsaechlich einfaehrt (oder umgekehrt), hier NUR das
    -- Vorzeichen umdrehen -- kein Code-Aendern noetig. Zum Testen: einzeln
    -- ueber die manuelle Fahrt (Menuepunkte 4/5/6) beobachten und anpassen.
    richtung = {
        -- Treppenmodul1 hat 2 Achsenbewegungen (Y, Z) ueber denselben
        -- Gearshift -- relay_treppe1_z waehlt aus, welche Achse gerade
        -- angetrieben wird (kein Signal = Y, Signal an = Z). Startwert
        -- uebernommen aus der bisherigen Kalibrierung, ggf. pro Achse
        -- separat nachjustieren.
        treppe1_y_ausfahren = -1,
        treppe1_y_einfahren = 1,
        treppe1_z_ausfahren = -1,
        treppe1_z_einfahren = 1,

        -- Treppenmodul2 hat nur eine Achse (Y) -- unveraendert
        treppe2_ausfahren = -1,
        treppe2_einfahren = 1,

        -- Boden hat 3 separate Achsenbewegungen pro Richtung (X, Z, A),
        -- da alle 3 ueber denselben Gearshift laufen und die Redstone-
        -- Signale nur auswaehlen, WELCHE Achse gerade angetrieben wird.
        -- Jede Achse braucht daher ihren eigenen Richtungsmodifier.
        boden_x_ausfahren = -1,
        boden_x_einfahren = 1,
        boden_z_ausfahren = 1,
        boden_z_einfahren = -1,
        boden_a_ausfahren = 1,   -- Drehung zurueck (90 -> 0 Grad)
        boden_a_einfahren = -1,   -- Drehung (0 -> 90 Grad)
    },

    -- Redstone Relais (CC:Tweaked): jedes Signal bekommt sein eigenes,
    -- dediziertes Relay. Die Seite am Relay ist egal (immer 'seite'),
    -- da pro Relay ohnehin nur ein Signal anliegt. Der Trigger ist der
    -- einzige Redstone-Input, der PHYSISCH am Computer selbst verkabelt
    -- ist (siehe redstone_trigger unten), alles andere laeuft ueber
    -- diese Relais-Peripherals (exakte Namen).
    redstone_relais = {
        seite = "left",  -- NICHT MEHR GENUTZT: Code prueft/setzt jetzt automatisch alle 6 Seiten

        -- Ausgaenge (Ansteuerung der Bewegung) -- UNVERAENDERT
        ausgaenge = {
            treppe1_z = "redstone_relay_3",  -- Treppe1: Z-Achse braucht Signal, wenn Y-Achse aktiviert wird
            boden_x   = "redstone_relay_4",  -- Boden: X-Achsen-Signal -- wenn AN, faehrt die Z-Achse
            boden_z   = "redstone_relay_5",  -- Boden: Z-Achsen-Signal -- wenn X UND Z beide AN, faehrt die A-Achse (Drehung)
        },

        -- Eingaenge (Positionskontakte) -- NEU DEFINIERT
        eingaenge = {
            -- Treppenmodul1: Y-Achse (beide Endpunkte) + Z-Achse (nur unten)
            treppe1_y_ausgefahren = "redstone_relay_20",  -- Y ausgefahren (Treppe)
            treppe1_y_eingefahren = "redstone_relay_21",  -- Y eingefahren (Grundstellung)
            treppe1_z_unten       = "redstone_relay_32",  -- Z unten (nur lesbar waehrend Y ausgefahren)
            treppe1_z_unten_bei_y_eingefahren = "redstone_relay_31",  -- Z unten, bestaetigt WAEHREND Y eingefahren ist (Ruheposition)

            -- Treppenmodul2: nur Y-Achse (beide Endpunkte)
            treppe2_y_ausgefahren = "redstone_relay_17",  -- Y ausgefahren (Treppe)
            treppe2_y_eingefahren = "redstone_relay_18",  -- Y eingefahren (Grundstellung)

            -- Boden: X-Achse (beide Endpunkte) + kombinierte Z/A-Kontakte
            boden_x_links     = "redstone_relay_25",  -- X eingefahren (Treppe)
            boden_x_rechts    = "redstone_relay_26",  -- X ausgefahren (Grundstellung)
            boden_z_unten_a90 = "redstone_relay_28",  -- Z unten UND A 90 Grad zusammen (Boden sichtbar) -- schaltet nur bei X links
            boden_z_oben_a0   = "redstone_relay_29",  -- Z oben UND A 0 Grad zusammen (Grundstellung) -- schaltet nur wenn A nicht gedreht
        },
    },

    -- Physischer Redstone-Input direkt am Computer (einziger, kein Relay)
    redstone_trigger = {
        seite = "right",
    },

    -- Bewegungsdistanzen in Bloecken
    distanzen = {
        -- treppe1_y, treppe2, boden_x sind auto-kalibriert (Kontakt an
        -- beiden Endpunkten vorhanden) -- keine feste Distanz noetig.
        treppe1_z = 5,  -- Treppe1 Z-Achse, nur Richtung "ausfahren" (kein Kontakt fuer "oben")
        boden_z = 5,   -- Boden Z-Achse Distanz
        boden_a = 90,  -- Boden Drehwinkel (immer 0/90 Grad, i.d.R. nicht aendern)
    },

    -- Rotation Speed Controller (Create): Treppe1 = ein gemeinsamer
    -- Controller fuer beide Richtungen, Treppe2/Boden = je einer pro Richtung.
    -- Exakte Peripheral-Namen. -- UNVERAENDERT
    geschwindigkeiten = {
        peripherals = {
            treppe1           = "Create_RotationSpeedController_4",
            treppe2_ausfahren = "Create_RotationSpeedController_3",
            treppe2_einfahren = "Create_RotationSpeedController_2",
            boden_ausfahren   = "Create_RotationSpeedController_5",
            boden_einfahren   = "Create_RotationSpeedController_6",
        },
        -- Ziel-RPM je Controller (-256 bis 256)
        rpm = {
            treppe1           = 32,
            treppe2_ausfahren = 32,
            treppe2_einfahren = 32,
            boden_ausfahren   = 16,
            boden_einfahren   = 16,
        },
    },

    -- Zugriffskontrolle Player Detector (Advanced Peripherals) -- UNVERAENDERT
    spieler = {
        reichweite = 15,
        erlaubte_spieler = {
            "NXRxKing",
            "timdax",
        },
    },

    -- Sonstiges
    -- Timeout fuer Bewegungen (isRunning-Polling) und Kontakt-Bestaetigungen.
    -- Muss laenger sein als die laengste tatsaechliche Bewegung -- Boden Z
    -- (5 Bloecke bei RPM 16) dauert real ca. 45s. 90s laesst deutlich Puffer.
    timeout_sekunden = 90,

    -- Auto-Kalibrierung: fuer Achsen mit Kontakt an BEIDEN Endpunkten
    -- (Treppe1-Y, Treppe2-Y, Boden-X, Treppe1-Z nur Richtung "unten")
    -- wird statt einer festen Distanz in kleinen Schritten gefahren, bis
    -- der Ziel-Kontakt schaltet. schrittgroesse = Bloecke pro Einzelschritt,
    -- max_schritte = Sicherheitsabbruch, falls der Kontakt nie kommt.
    auto_kalibrierung = {
        schrittgroesse = 1,
        max_schritte = 32,
    },

    -- Sicherheitspause NACH einer Kontakt-Bestaetigung, bevor der naechste
    -- Schritt beginnt (in Sekunden). Manche Kontakte schalten kurz bevor
    -- die Bewegung optisch/mechanisch wirklich ganz fertig ist -- diese
    -- Pause faengt das ab. 0 = keine Pause.
    sicherheitspause_sekunden = 0.5,

    -- Settle-Pause VOR der allerersten Kontaktpruefung, direkt nachdem ein
    -- Achsen-Signal umgeschaltet wurde. Faengt ab, dass der erste Check
    -- noch einen veralteten Redstone-Wert von VOR dem Umschalten liest.
    -- Falls "Kontakt erreicht nach 0 Schritten" trotzdem noch faelschlich
    -- auftritt, hier erhoehen (z.B. auf 1.0).
    settle_pause_sekunden = 0.25,

}











