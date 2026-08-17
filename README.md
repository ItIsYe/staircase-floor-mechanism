# staircase-floor-mechanism

CC:Tweaked + Create Steuerung fuer eine verschwindende Treppe, die durch Bodenbloecke ersetzt wird.

## Installation

Auf dem CC:Tweaked-Computer eingeben:

```
wget run https://raw.githubusercontent.com/ItIsYe/staircase-floor-mechanism/main/installer.lua
```

Laedt `treppe_boden.lua`, `config.lua` (nur beim ersten Mal / bei fehlenden Feldern) und `startup.lua`. Danach `config.lua` mit den echten Peripheral-Namen, Relay-Namen, Distanzen und der Spieler-Whitelist befuellen.

**Update:** denselben Befehl (oder `installer`, falls schon vorhanden) erneut ausfuehren. `treppe_boden.lua` und `startup.lua` werden neu geladen, `config.lua` wird migriert (neue Felder ergaenzt, eigene Werte bleiben erhalten).

## Peripheral-Namen

Alle Peripheral-Namen in `config.lua` sind **exakte Namen**, keine Textfragmente. Die Blocke/Modems werden NICHT umbenannt -- stattdessen werden die automatisch von CC:Tweaked vergebenen Standardnamen (z.B. `Create_SequencedGearshift_2`, `redstone_relay_20`) direkt eingetragen.

So findet ihr heraus, welcher Standardname zu welcher Funktion gehoert:

1. Im Computer eingeben: `lua` dann `peripheral.getNames()` -- listet alle vorhandenen Peripherals
2. Jedes einzeln testen, z.B. `peripheral.wrap("Create_SequencedGearshift_2").move(1,1)` und beobachten, welcher Block sich bewegt
3. Zugeordnete Namen in `config.lua` eintragen

## Achsen

**Z** = hoch/runter, **X** = links/rechts, **Y** = vor/zurueck, **A** = Drehachse

## Module und Bewegungslogik

**Treppenmodul1** -- Y-Achse und Z-Achse:
- Z darf nur ausfahren, wenn Y am Endpunkt "ausgefahren" ist
- Y darf nur fahren, wenn Z am Endpunkt "unten" ist
- Z-Achse fährt nur, wenn die Y-Achse (bzw. das zugehoerige Ausgangs-Relay) ein Redstone-Signal bekommt
- Endpunkte: Y ausgefahren (Treppe) / Y eingefahren (Grundstellung), Z unten (Grundstellung) / Z oben (Treppe, kein Kontakt vorhanden)

**Treppenmodul2** -- nur Y-Achse:
- Kein Redstone-Signal noetig
- Endpunkte: Y ausgefahren (Treppe) / Y eingefahren (Grundstellung)

**Boden** -- X-Achse, Z-Achse, A-Achse (Drehung):
- Um Z zu fahren, braucht die X-Achse ein Redstone-Signal
- Um A zu fahren, brauchen X und Z beide ein Redstone-Signal
- Z darf nur fahren, wenn X am Endpunkt "rechts" ist und A in Position ist
- A darf nur fahren, wenn Z "unten" ist und X am linken Endpunkt ist
- A wird nur zwischen 0 Grad und 90 Grad verfahren
- Endpunkte: X links = eingefahren (Treppe) / X rechts = ausgefahren (Grundstellung), Z unten (Boden sichtbar) / Z oben (Grundstellung), A 0 Grad (Grundstellung) / A 90 Grad (Boden sichtbar)

## Positionskontakte (Relais-Eingaenge)

Nicht jede Achsen-Position hat einen eigenen Kontakt -- manche Kontakte bestaetigen bewusst mehrere Achsen gleichzeitig, weil sie physisch nur in genau dieser Kombination schalten koennen.

**Treppenmodul1** (3 Kontakte):
| Kontakt | Bestaetigt | Relay |
|---|---|---|
| Y ausgefahren | Y-Achse ausgefahren (Treppe) | `redstone_relay_20` |
| Y eingefahren | Y-Achse eingefahren (Grundstellung) | `redstone_relay_21` |
| Z unten | Z-Achse unten (Grundstellung) | `redstone_relay_24` |

"Treppe"-Zustand: Y-ausgefahren-Kontakt allein (kein Z-oben-Kontakt vorhanden). "Grundstellung"-Zustand (verschwunden): Y-eingefahren UND Z-unten zusammen.

**Treppenmodul2** (2 Kontakte):
| Kontakt | Bestaetigt | Relay |
|---|---|---|
| Y ausgefahren | Y-Achse ausgefahren (Treppe) | `redstone_relay_17` |
| Y eingefahren | Y-Achse eingefahren (Grundstellung) | `redstone_relay_18` |

**Boden** (4 Kontakte):
| Kontakt | Bestaetigt | Relay |
|---|---|---|
| X links | X eingefahren (Treppe) | `redstone_relay_25` |
| X rechts | X ausgefahren (Grundstellung) | `redstone_relay_26` |
| Z unten + A 90 Grad | Z unten UND A 90 Grad zusammen (Boden sichtbar) -- schaltet nur bei X links | `redstone_relay_28` |
| Z oben + A 0 Grad | Z oben UND A 0 Grad zusammen (Grundstellung) -- schaltet nur wenn A nicht gedreht | `redstone_relay_29` |

"Grundstellung": X-rechts UND Z-oben+A0-Kontakt zusammen -- bestaetigt alle 3 Achsen. "Boden sichtbar": X-links UND Z-unten+A90-Kontakt zusammen -- bestaetigt ebenfalls alle 3 Achsen.

## Redstone-Ausgaenge (Ansteuerung, unveraendert)

| Signal | Relay |
|---|---|
| Treppe1 Z-Achse | `redstone_relay_3` |
| Boden Z-Achse | `redstone_relay_4` |
| Boden X-Achse (mit Z zusammen fuer A-Drehung) | `redstone_relay_5` |

Physischer Redstone-Input direkt am Computer (kein Relay): Trigger, Seite `right`.

## Richtungskalibrierung

`move()` bewegt einen Gearshift in eine Richtung, die vom Vorzeichen des zweiten Parameters abhaengt (1 oder -1). Jeder der 6 Gearshifts hat einen eigenen Richtungsmodifier unter `richtung` in `config.lua` (Standard: `1`). Ueber die manuelle Fahrt (Menuepunkte 4/5/6) testen und bei Bedarf auf `-1` umstellen -- kein Code-Aendern noetig.

## Geschwindigkeiten (Rotation Speed Controller, unveraendert)

Fahrgeschwindigkeit ist per Create-`Rotation Speed Controller` steuerbar, RPM-Bereich -256 bis 256. Treppenmodul1: ein gemeinsamer Controller fuer beide Richtungen. Treppenmodul2/Boden: getrennter Controller fuer Ausfahren und Einfahren. Ziel-RPM in `config.lua` unter `geschwindigkeiten.rpm`, auch live im Programm unter Menuepunkt `g` aenderbar.

## Initialisierung

Beim Programmstart wird der aktuelle Zustand ueber die Relay-Kontakte ermittelt. Ist der Zustand nicht eindeutig bestimmbar, faehrt das Programm einmalig automatisch in die Grundstellung (Treppe sichtbar).

## Startup

Der Installer schreibt zusaetzlich eine `startup.lua`, die `treppe_boden.lua` bei jedem Boot des Computers automatisch startet. Bei einem Fehler im Hauptskript wird nach 5 Sekunden automatisch neu gestartet.

## Ausloesung (Geofence, unveraendert)

- **Redstone-Trigger** (physischer Input am Computer): steigende Flanke togglet den Zustand, hat immer Vorrang vor der Geofence-Logik
- **Geofence / Player Detector**: solange mindestens ein Whitelist-Spieler (`spieler.erlaubte_spieler` in `config.lua`) im konfigurierten Bereich ist, wird die Treppe erzwungen; verlassen alle Whitelist-Spieler den Bereich, wird der Boden erzwungen
- **Manuell** ueber die UI (Menuepunkte 4/5/6 fuer einzelne Module, 9 fuer den kompletten Toggle-Ablauf)

## Verriegelung

Bevor eine neue Bewegung startet, prueft das Programm per Relay-Kontakt, ob das System vollstaendig in einer bekannten Endlage steht. Laeuft bereits eine Bewegung oder ist der Zustand nicht eindeutig, wird die neue Aktion verweigert.

## Status

Positions-/Kontaktarchitektur wurde komplett neu definiert und mit finaler Relay-Zuordnung umgesetzt. Noch keine vollstaendigen In-Game-Tests durchgefuehrt.
