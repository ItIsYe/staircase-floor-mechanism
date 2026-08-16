-- ============================================
-- Konfigurationsdatei Treppen-/Boden-Mechanismus
-- Alle Werte hier anpassen, treppe_boden.lua nicht veraendern
--
-- WICHTIG: Alle Peripheral-Namen unten sind EXAKTE Namen, keine
-- Textfragmente (peripheral.wrap statt peripheral.find-Substring-Suche).
--
-- config_version wird vom Installer genutzt, um bei Updates neue
-- Einstellungsfelder automatisch zu ergaenzen, ohne bestehende
-- Werte zu ueberschreiben. Nicht manuell aendern.
-- ============================================

return {

    config_version = 12,

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
        treppe1_ausfahren = 1,
        treppe1_einfahren = 1,
        treppe2_ausfahren = 1,
        treppe2_einfahren = 1,
        boden_ausfahren   = 1,
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

        -- Ausgaenge (Ansteuerung der Bewegung)
        ausgaenge = {
            treppe1_z = "redstone_relay_3",
            boden_z   = "redstone_relay_4",
            boden_x   = "redstone_relay_5",
        },

        -- Eingaenge (Positionskontakte, ersetzen den frueheren
        -- Redstone-Wire-Connector mit Farbkanaelen)
        eingaenge = {
            treppe1_x_eingefahren = "redstone_relay_6",
            treppe1_x_eingefahren_z_kontrolle = "redstone_relay_11",  -- Z-Achse Endpunkt "unten" bei X eingefahren
            treppe1_x_ausgefahren = "redstone_relay_7",   -- = Z eingefahren
            treppe2_x_eingefahren = "redstone_relay_1",
            treppe2_x_ausgefahren = "redstone_relay_2",

            -- Boden Grundstellung (Treppe sichtbar): X eingefahren + Z eingefahren
            -- HINWEIS: laut Vorgabe (Excel-Tabelle) existiert noch KEIN Relay fuer
            -- die Drehungsbestaetigung der Grundstellung -- wird daher NICHT geprueft.
            -- HINWEIS: boden_x_grund_kontakt nutzt DENSELBEN Relay wie boden_x_eingefahren
            -- unten (redstone_relay_10) -- so von Nutzer explizit bestaetigt/vorgegeben.
            boden_x_grund_kontakt = "redstone_relay_10",  -- Grundstellung: X eingefahren
            boden_z_eingefahren   = "redstone_relay_9",   -- Grundstellung: Z eingefahren

            -- Boden sichtbar (Treppe weg): X eingefahren (2-fach bestaetigt) + gedreht
            -- HINWEIS: laut Vorgabe existiert kein Relay fuer Z ausgefahren -- entfaellt.
            boden_x_eingefahren        = "redstone_relay_10",
            boden_x_eingefahren_zusatz = "redstone_relay_8",   -- zusaetzliche Bestaetigung X eingefahren
            boden_gedreht              = "redstone_relay_14",  -- Boden sichtbar: gedreht bestaetigt
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
    -- Exakte Peripheral-Namen.
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

    -- Zugriffskontrolle Player Detector (Advanced Peripherals)
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
