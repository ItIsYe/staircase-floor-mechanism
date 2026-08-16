# staircase-floor-mechanism

CC:Tweaked + Create Steuerung fuer eine verschwindende Treppe, die durch Bodenbloecke ersetzt wird.

## Installation

Auf dem CC:Tweaked-Computer eingeben:

```
wget run https://raw.githubusercontent.com/ItIsYe/staircase-floor-mechanism/main/installer.lua
```

Laedt `treppe_boden.lua`, `config.lua` (nur beim ersten Mal / bei fehlenden Feldern) und `startup.lua`. Danach `config.lua` mit den echten Peripheral-Namen, Relay-Namen, Distanzen und der Spieler-Whitelist befuellen.

**Update:** denselben Befehl (oder `installer`, falls schon vorhanden) erneut ausfuehren. `treppe_boden.lua` und `startup.lua` werden neu geladen, `config.lua` wird migriert (neue Felder ergaenzt, eigene Werte bleiben erhalten).

## Aufbau

**Achsen:** Z = rauf/runter, X = vor/zurueck

**Grundposition (Treppe sichtbar):**
- Treppenmodul1: oben (Z eingefahren), am Ende des Gantrys (X ausgefahren)
- Treppenmodul2: X komplett ausgefahren, am Ende des Gantrys
- Boden: um 90 Grad gedreht, alles eingefahren

**Module:** Treppenmodul1, Treppenmodul2, Boden — je zwei Sequenced Gearshifts (Ausfahren + Einfahren).

## Redstone-Verkabelung

Am Computer selbst ist nur **ein** Redstone-Input physisch verkabelt: der Trigger (`redstone_trigger.seite` in `config.lua`).

Alles andere laeuft ueber **dedizierte Redstone-Relais** (`redstone_relais` in `config.lua`) — pro Signal ein eigenes Relay-Peripheral:

- **Ausgaenge** (Ansteuerung der Bewegung): Treppe1-Z, Boden-Z, Boden-X
- **Eingaenge** (Positionskontakte): je ein Relay fuer "eingefahren" und "ausgefahren" bei Treppe1, Treppe2 und Boden (6 Relais gesamt)

Da jedes Relay nur ein einziges Signal traegt, ist die genutzte Seite am jeweiligen Relay beliebig — `redstone_relais.seite` gilt einheitlich fuer alle. Es gibt keinen Redstone Wire Connector und keine Farbkanaele mehr.

## Ablauf (Treppe -> Boden)

1. Treppenmodul1 + Treppenmodul2 fahren gleichzeitig ein (Treppe1 braucht ein Signal am Treppe1-Z-Relay)
2. Erst wenn beide Treppenmodule per Relay-Kontakt bestaetigt in Endlage sind: Boden faehrt aus (inkl. Drehung, gesteuert ueber Boden-Z- und Boden-X-Relay gemeinsam)

Der umgekehrte Ablauf (`Boden -> Treppe`) laeuft spiegelverkehrt.

## Positionserkennung

Nicht jede Position hat einen eigenen Kontakt — z.B. bestaetigt das X-ausgefahren-Relay bei Treppenmodul1 gleichzeitig auch Z-eingefahren, weil beide Zustaende an der gleichen physischen Position zusammenfallen.

## Redstone-Signale (funktionsspezifisch)

- Treppenmodul1: ein Signal fuer Z-Achsen-Bewegung (beide Richtungen)
- Treppenmodul2: kein Redstone noetig
- Boden: ein Signal fuer Z-Achse, ein Signal fuer X-Achse — Drehung braucht beide gleichzeitig, erfolgt aber erst wenn Z unten und X ausgefahren ist (intern im Gearshift-Sequenzeditor programmiert)

## Geschwindigkeiten (Rotation Speed Controller)

Fahrgeschwindigkeit ist per Create-`Rotation Speed Controller` steuerbar, RPM-Bereich -256 bis 256:

- Treppenmodul1: ein gemeinsamer Controller fuer beide Richtungen
- Treppenmodul2: getrennter Controller fuer Ausfahren und Einfahren
- Boden: getrennter Controller fuer Ausfahren und Einfahren

Ziel-RPM werden in `config.lua` unter `geschwindigkeiten.rpm` vorbelegt, sind aber auch live im Programm unter Menuepunkt `g` abfragbar und aenderbar. Aenderungen werden in `treppe_runtime.cfg` gespeichert und bleiben bei einem Update/Installer-Lauf erhalten.

## Initialisierung

Beim Programmstart wird der aktuelle Zustand ueber die Relay-Kontakte ermittelt (Treppe sichtbar vs. Boden sichtbar). Ist der Zustand nicht eindeutig bestimmbar, faehrt das Programm einmalig automatisch in die Grundstellung (Treppe sichtbar), um einen bekannten Ausgangszustand herzustellen.

## Startup

Der Installer schreibt zusaetzlich eine `startup.lua`, die `treppe_boden.lua` bei jedem Boot des Computers automatisch startet. Bei einem Fehler im Hauptskript wird nach 5 Sekunden automatisch neu gestartet.

## Auslösung

- **Redstone-Trigger** (physischer Input am Computer): steigende Flanke togglet den Zustand, hat immer Vorrang vor der Geofence-Logik
- **Geofence / Player Detector** (Advanced Peripherals): solange mindestens ein Whitelist-Spieler (`spieler.erlaubte_spieler` in `config.lua`) im konfigurierten Bereich (`spieler.reichweite`) ist, wird die Treppe erzwungen; verlassen alle Whitelist-Spieler den Bereich, wird der Boden erzwungen (Treppe verschwindet)
- **Manuell** ueber die UI (Menuepunkte 4/5/6 fuer einzelne Module, 9 fuer den kompletten Toggle-Ablauf)

## Verriegelung

Bevor eine neue Bewegung startet — automatisch (Redstone/Geofence) oder manuell — prueft das Programm per Relay-Kontakt, ob das System vollstaendig in einer bekannten Endlage steht (alle Module bestaetigt aus- oder eingefahren, passend zum aktuell gespeicherten Zustand). Laeuft bereits eine Bewegung oder ist der Zustand nicht eindeutig, wird die neue Aktion verweigert, statt Bewegungen zu ueberlappen.

## Status

Konzept vollstaendig, Skript-Version mit Relais-Architektur vorhanden. Peripheral-Namen, Relay-Namen, Distanzen und Farbwerte sind Platzhalter und muessen an die tatsaechliche Verkabelung angepasst werden. Noch keine vollstaendigen In-Game-Tests durchgefuehrt.
