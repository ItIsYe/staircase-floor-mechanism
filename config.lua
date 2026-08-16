-- ============================================
-- Konfigurationsdatei Treppen-/Boden-Mechanismus
-- Alle Werte hier anpassen, treppe_boden.lua nicht veraendern
--
-- config_version wird vom Installer genutzt, um bei Updates neue
-- Einstellungsfelder automatisch zu ergaenzen, ohne bestehende
-- Werte zu ueberschreiben. Nicht manuell aendern.
-- ============================================

return {

    config_version = 3,

    -- Peripheral-Namensfragmente (peripheral.find sucht Teilstring)
    peripherals = {
        treppe1_ausfahren = "treppe1_ausfahren",
        treppe1_einfahren = "treppe1_einfahren",
        treppe2_ausfahren = "treppe2_ausfahren",
        treppe2_einfahren = "treppe2_einfahren",
        boden_ausfahren   = "boden_ausfahren",
        boden_einfahren   = "boden_einfahren",
    },

    -- Redstone Relay (CC:Tweaked): einziger Redstone-Input am Computer
    -- selbst ist der Trigger. Alle anderen Redstone-Ausgaenge (Treppe1-Z,
    -- Boden-Z, Boden-X) laufen ueber diesen Relay-Peripheral, nicht ueber
    -- physische Computer-Seiten.
    redstone_relay = {
        peripheral = "redstone_relay",
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

    -- Redstone-Wire-Connector Farbkanaele (Immersive Engineering)
    farbkanaele = {
        treppe1_x_eingefahren = "white",
        treppe1_x_ausgefahren = "orange",     -- = Z eingefahren
        treppe2_x_eingefahren = "light_blue",
        treppe2_x_ausgefahren = "magenta",
        boden_x_eingefahren   = "yellow",
        boden_x_ausgefahren   = "lime",       -- = Z unten + X ausgefahren + gedreht
    },

    -- Redstone-Seiten: 'trigger' ist der einzige physisch am Computer
    -- verkabelte Redstone-Input. treppe1_z/boden_z/boden_x sind Seiten
    -- AM REDSTONE RELAY (siehe redstone_relay oben), nicht am Computer.
    redstone_seiten = {
        treppe1_z = "back",    -- Treppe1: Z-Achse, beide Richtungen (am Relay)
        boden_z   = "top",     -- Boden: Z-Achse (am Relay)
        boden_x   = "bottom",  -- Boden: X-Achse (am Relay, mit Z zusammen fuer Drehung)
        trigger   = "left",    -- physischer Redstone-Input direkt am Computer
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
