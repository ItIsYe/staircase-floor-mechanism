# staircase-floor-mechanism

CC:Tweaked + Create + Immersive Engineering Steuerung fuer eine verschwindende Treppe, die durch Bodenbloecke ersetzt wird.

## Aufbau

**Achsen:** Z = rauf/runter, X = vor/zurueck

**Grundposition (Treppe sichtbar):**
- Treppenmodul1: oben (Z eingefahren), am Ende des Gantrys (X ausgefahren)
- Treppenmodul2: X komplett ausgefahren, am Ende des Gantrys
- Boden: um 90 Grad gedreht, alles eingefahren

**Module:** Treppenmodul1, Treppenmodul2, Boden — je zwei Sequenced Gearshifts (Ausfahren + Einfahren).

## Ablauf (Treppe -> Boden)

1. Treppenmodul1 + Treppenmodul2 fahren gleichzeitig ein (Treppe1 braucht Redstone-Signal fuer Z-Achse)
2. Erst wenn beide Treppenmodule in Endlage sind: Boden faehrt aus (inkl. Drehung, gesteuert ueber Z- und X-Signal gemeinsam)

Der umgekehrte Ablauf laeuft spiegelverkehrt.

## Positionserkennung

Kein Redstone Integrator (Seiten-Limit), stattdessen Immersive-Engineering-**Redstone Wire Connector** mit Farbkanaelen. Ein zentraler Connector am Computer liest per `getRedstoneForChannel(color)` alle Endpositionen aus. Nicht jede Position hat einen Kontakt — z.B. bestaetigt der X-ausgefahren-Kontakt bei Treppenmodul1 gleichzeitig auch Z-eingefahren.

## Redstone-Signale (funktionsspezifisch)

- Treppenmodul1: ein Signal fuer Z-Achsen-Bewegung (beide Richtungen)
- Treppenmodul2: kein Redstone noetig
- Boden: ein Signal fuer Z-Achse, ein Signal fuer X-Achse — Drehung braucht beide gleichzeitig, erfolgt aber erst wenn Z unten und X ausgefahren ist (intern im Gearshift-Sequenzeditor programmiert)

## Auslösung

- Redstone-Seite (fest verkabelt)
- Player Detector (Advanced Peripherals) — nur erlaubte Spieler in `ERLAUBTE_SPIELER` loesen aus
- Beide Trigger togglen automatisch zwischen Verschwinden/Herstellen je nach aktuellem Zustand

## Status

Konzept vollstaendig, Skript-Erstversion vorhanden. Peripheral-Namen, Redstone-Seiten, Farbkanaele und Distanzen sind Platzhalter und muessen an die tatsaechliche Verkabelung angepasst werden. Noch keine In-Game-Tests durchgefuehrt.

## Geschwindigkeiten (Rotation Speed Controller)

Fahrgeschwindigkeit ist per Create-`Rotation Speed Controller` steuerbar, RPM-Bereich -256 bis 256:

- Treppenmodul1: ein gemeinsamer Controller fuer beide Richtungen
- Treppenmodul2: getrennter Controller fuer Ausfahren und Einfahren
- Boden: getrennter Controller fuer Ausfahren und Einfahren

Ziel-RPM werden in `config.lua` unter `geschwindigkeiten.rpm` vorbelegt, sind aber auch live im Programm unter Menuepunkt `g` abfragbar und aenderbar. Aenderungen werden in `treppe_runtime.cfg` gespeichert und bleiben bei einem Update/Installer-Lauf erhalten.

## Initialisierung

Beim Programmstart wird der aktuelle Zustand ueber die Redstone-Wire-Connector-Kontakte ermittelt (Treppe sichtbar vs. Boden sichtbar). Ist der Zustand nicht eindeutig bestimmbar, faehrt das Programm einmalig automatisch in die Grundstellung (Treppe sichtbar), um einen bekannten Ausgangszustand herzustellen.

## Startup

Der Installer schreibt zusaetzlich eine `startup.lua`, die `treppe_boden.lua` bei jedem Boot des Computers automatisch startet. Bei einem Fehler im Hauptskript wird nach 5 Sekunden automatisch neu gestartet.

## Zugriffskontrolle / Geofence

Statt eines reinen Ein-/Austrigger-Signals ueberwacht das Programm laufend, ob sich mindestens ein Whitelist-Spieler (siehe `spieler.erlaubte_spieler` in `config.lua`) im konfigurierten Bereich (`spieler.reichweite`, Bloecke um den Player Detector) befindet:

- Ist ein Whitelist-Spieler im Bereich: Treppe wird erzwungen (sichtbar)
- Verlassen alle Whitelist-Spieler den Bereich: Boden wird erzwungen (Treppe verschwindet)

Zusaetzlich bleibt ein manueller Redstone-Trigger (`redstone_seiten.trigger`) als Toggle-Override erhalten, z.B. fuer Tests oder Notfallsteuerung.

## Verriegelung

Bevor eine neue Bewegung startet -- automatisch (Redstone/Geofence) oder manuell -- prueft das Programm per Kontakt, ob das System vollstaendig in einer bekannten Endlage steht (alle Module bestaetigt aus- oder eingefahren, passend zum aktuell gespeicherten Zustand). Laeuft bereits eine Bewegung oder ist der Zustand nicht eindeutig, wird die neue Aktion verweigert, statt Bewegungen zu ueberlappen.
