-- ============================================
-- Konfigurationsdatei Treppen-/Boden-Mechanismus
-- Alle Werte hier anpassen, treppe_boden.lua nicht veraendern
--
-- config_version wird vom Installer genutzt, um bei Updates neue
-- Einstellungsfelder automatisch zu ergaenzen, ohne bestehende
-- Werte zu ueberschreiben. Nicht manuell aendern.
-- ============================================

return {

    config_version = 4,

    -- Peripheral-Namensfragmente (peripheral.find sucht Teilstring)
    peripherals = {
        treppe1_ausfahren = "treppe1_ausfahren",
        treppe1_einfahren = "treppe1_einfahren",
        treppe2_ausfahren = "treppe2_ausfahren",
        treppe2_einfahren = "treppe2_einfahren",
        boden_ausfahren   = "boden_ausfahren",
        boden_einfahren   = "boden_einfahren",
    },

    -- Redstone Relais (CC:Tweaked): jedes Signal bekommt sein eigenes,
    -- dediziertes Relay. Die Seite am Relay ist egal (immer 'seite'),
    -- da pro Relay ohnehin nur ein Signal anliegt. Der Trigger ist der
    -- einzige Redstone-Input, der PHYSISCH am Computer selbst verkabelt
    -- ist (siehe redstone_trigger unten), alles andere laeuft ueber
    -- diese Relais-Peripherals.
    redstone_relais = {
        seite = "top",  -- gilt fuer ALLE Relais unten, Seite ist egal

        -- Ausgaenge (Ansteuerung der Bewegung)
        ausgaenge = {
            treppe1_z = "treppe1_z_relay",
            boden_z   = "boden_z_relay",
            boden_x   = "boden_x_relay",
        },

        -- Eingaenge (Positionskontakte, ersetzen den frueheren
        -- Redstone-Wire-Connector mit Farbkanaelen)
        eingaenge = {
            treppe1_x_eingefahren = "treppe1_ein_relay",
            treppe1_x_ausgefahren = "treppe1_aus_relay",   -- = Z eingefahren
            treppe2_x_eingefahren = "treppe2_ein_relay",
            treppe2_x_ausgefahren = "treppe2_aus_relay",
            boden_x_eingefahren   = "boden_ein_relay",
            boden_x_ausgefahren   = "boden_aus_relay",     -- = Z unten + X ausgefahren + gedreht
        },
    },

    -- Physischer Redstone-Input direkt am Computer (einziger, kein Relay)
    redstone_trigger = {
        seite = "left",
    },

    -- Bewegungsdistanzen in Bloecken
    distanzen = {
        treppe1 = 4,
        treppe2 = 4,
        boden   = 2,
    },

    -- Rotation Speed Controller (Create): Treppe1 = ein gemeinsamer
    -- Controller fuer beide Richtungen, Treppe2/Boden = je einer pro Richtung
    geschwindigkeiten = {
        peripherals = {
            treppe1           = "treppe1_speed",
            treppe2_ausfahren = "treppe2_ausfahren_speed",
            treppe2_einfahren = "treppe2_einfahren_speed",
            boden_ausfahren   = "boden_ausfahren_speed",
            boden_einfahren   = "boden_einfahren_speed",
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
            -- "Spielername1",
            -- "Spielername2",
        },
    },

    -- Sonstiges
    timeout_sekunden = 15,

}
