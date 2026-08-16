-- ============================================
-- Konfigurationsdatei Treppen-/Boden-Mechanismus
-- Alle Werte hier anpassen, treppe_boden.lua nicht veraendern
--
-- WICHTIG: Alle Peripheral-Namen unten sind EXAKTE Namen, keine
-- Textfragmente. Die Blocke/Modems werden NICHT umbenannt, sondern
-- die automatisch vergebenen Standardnamen (z.B. "Create_SequencedGearshift_2",
-- "redstone_relay_9") werden direkt eingetragen. Zum Ermitteln, welcher
-- Standardname zu welcher Funktion gehoert:
--   lua
--   peripheral.getNames()
-- listet alle vorhandenen Namen. Danach jedes Peripheral einzeln testen
-- (z.B. peripheral.wrap("Create_SequencedGearshift_2").move(1,1) und
-- schauen, welcher Block sich bewegt), um zuzuordnen.
--
-- config_version wird vom Installer genutzt, um bei Updates neue
-- Einstellungsfelder automatisch zu ergaenzen, ohne bestehende
-- Werte zu ueberschreiben. Nicht manuell aendern.
-- ============================================

return {

    config_version = 5,

    -- Exakte Peripheral-Namen der Sequenced Gearshifts
    peripherals = {
        treppe1_ausfahren = "Create_SequencedGearshift_1",
        treppe1_einfahren = "Create_SequencedGearshift_2",
        treppe2_ausfahren = "Create_SequencedGearshift_3",
        treppe2_einfahren = "Create_SequencedGearshift_4",
        boden_ausfahren   = "Create_SequencedGearshift_5",
        boden_einfahren   = "Create_SequencedGearshift_6",
    },

    -- Redstone Relais (CC:Tweaked): jedes Signal bekommt sein eigenes,
    -- dediziertes Relay. Die Seite am Relay ist egal (immer 'seite'),
    -- da pro Relay ohnehin nur ein Signal anliegt. Der Trigger ist der
    -- einzige Redstone-Input, der PHYSISCH am Computer selbst verkabelt
    -- ist (siehe redstone_trigger unten), alles andere laeuft ueber
    -- diese Relais-Peripherals (exakte Namen).
    redstone_relais = {
        seite = "top",  -- gilt fuer ALLE Relais unten, Seite ist egal

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
            treppe1_x_ausgefahren = "redstone_relay_7",   -- = Z eingefahren
            treppe2_x_eingefahren = "redstone_relay_8",
            treppe2_x_ausgefahren = "redstone_relay_9",
            boden_x_eingefahren   = "redstone_relay_10",
            boden_x_ausgefahren   = "redstone_relay_11",  -- = Z unten + X ausgefahren + gedreht
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
    -- Controller fuer beide Richtungen, Treppe2/Boden = je einer pro Richtung.
    -- Exakte Peripheral-Namen.
    geschwindigkeiten = {
        peripherals = {
            treppe1           = "Create_RotationSpeedController_1",
            treppe2_ausfahren = "Create_RotationSpeedController_2",
            treppe2_einfahren = "Create_RotationSpeedController_3",
            boden_ausfahren   = "Create_RotationSpeedController_4",
            boden_einfahren   = "Create_RotationSpeedController_5",
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
