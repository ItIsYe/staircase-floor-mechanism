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

    config_version = 13,

    -- Exakte Peripheral-Namen der Sequenced Gearshifts
    peripherals = {
        treppe1_ausfahren = "Create_SequencedGearshift_2",
        treppe1_einfahren = "Create_SequencedGearshift_1",
        treppe2_ausfahren = "Create_SequencedGearshift_4",
        treppe2_einfahren = "Create_SequencedGearshift_3",
        boden_ausfahren   = "Create_SequencedGearshift_6",
        boden_einfahren   = "Create_SequencedGearshift_5",
    },

    -- Richtungsmodifier je Gearshift: 1 oder -1. Falls ein Gearshift beim
    -- Ausfahren tatsaechlich einfaehrt (oder umgekehrt), hier NUR das
    -- Vorzeichen umdrehen -- kein Code-Aendern noetig. Zum Testen: einzeln
    -- ueber die manuelle Fahrt (Menuepunkte 4/5/6) beobachten und anpassen.
    richtung = {
        treppe1_ausfahren = -1,
        treppe1_einfahren = 1,
        treppe2_ausfahren = -1,
        treppe2_einfahren = 1,
        boden_ausfahren   = -1,
        boden_einfahren   = 1,
    },

    -- Redstone Relais (CC:Tweaked): jedes Signal bekommt sein eigenes,
    -- dediziertes Relay. Die Seite am Relay ist egal (immer 'seite'),
    -- da pro Relay ohnehin nur ein Signal anliegt. Der Trigger ist der
    -- einzige Redstone-Input, der PHYSISCH am Computer selbst verkabelt
    -- ist (siehe redstone_trigger unten), alles andere laeuft ueber
    -- diese Relais-Peripherals (exakte Namen).
    redstone_relais = {
        seite = "left",  -- gilt fuer ALLE Relais unten, Seite ist egal

        -- Ausgaenge (Ansteuerung der Bewegung) -- UNVERAENDERT
        ausgaenge = {
            treppe1_z = "redstone_relay_3",  -- Treppe1: Z-Achse braucht Signal, wenn Y-Achse aktiviert wird
            boden_z   = "redstone_relay_4",  -- Boden: Z-Achse braucht X-Signal
            boden_x   = "redstone_relay_5",  -- Boden: A-Achse braucht X- UND Z-Signal zusammen
        },

        -- Eingaenge (Positionskontakte) -- NEU DEFINIERT
        eingaenge = {
            -- Treppenmodul1: Y-Achse (beide Endpunkte) + Z-Achse (nur unten)
            treppe1_y_ausgefahren = "redstone_relay_20",  -- Y ausgefahren (Treppe)
            treppe1_y_eingefahren = "redstone_relay_21",  -- Y eingefahren (Grundstellung)
            treppe1_z_unten       = "redstone_relay_24",  -- Z unten (Grundstellung)

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
        treppe1 = 4,
        treppe2 = 4,
        boden   = 2,
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
        reichweite = 5,
        erlaubte_spieler = {
            "NXRxKing",
            "timdax",
        },
    },

    -- Sonstiges
    timeout_sekunden = 15,

}
