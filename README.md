# staircase-floor-mechanism

CC:Tweaked + Create Steuerung fuer eine verschwindende Treppe, die durch Bodenbloecke ersetzt wird.

## Installation

Auf dem CC:Tweaked-Computer eingeben:

```
wget run https://raw.githubusercontent.com/ItIsYe/staircase-floor-mechanism/main/installer.lua
```

Laedt `treppe_boden.lua`, `config.lua` und `startup.lua`. Danach `config.lua` mit den echten Peripheral-Namen, Relay-Namen, Distanzen und der Spieler-Whitelist befuellen -- und diese Werte auch im Repo committen (siehe unten).

**Update:** denselben Befehl (oder `installer`, falls schon vorhanden) erneut ausfuehren. **Ersetzt ALLE Dateien vollstaendig** durch den aktuellen Repo-Stand -- keine Migration, kein Zusammenfuehren mit lokal geaenderten Werten. Eigene Kalibrierungswerte (Distanzen, Richtungen, Relay-Namen, Whitelist) muessen deshalb direkt im Repo (`config.lua`) gepflegt werden, damit sie bei einem Installer-Lauf nicht verloren gehen. Der Installer loescht dabei zusaetzlich `treppe_runtime.cfg` (lokal gespeicherte, live ueber die Menues geaenderte Werte) -- sonst wuerden darin gespeicherte alte Werte weiterhin neue `config.lua`-Werte ueberschreiben, ohne dass das erkennbar waere. Nach jedem Installer-Lauf ist `config.lua` also wieder die alleinige Quelle der Wahrheit.

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

**Treppenmodul1** (4 Kontakte):
| Kontakt | Bestaetigt | Relay |
|---|---|---|
| Y ausgefahren | Y-Achse ausgefahren (Treppe) | `redstone_relay_20` |
| Y eingefahren | Y-Achse eingefahren (Grundstellung) | `redstone_relay_21` |
| Z unten | Z-Achse unten -- nur lesbar, waehrend Y noch ausgefahren ist | `redstone_relay_24` |
| Z unten (bei Y eingefahren) | Z-Achse unten, bestaetigt WAEHREND Y bereits eingefahren ist (Ruheposition) | `redstone_relay_31` |

**Wichtig:** Der Z-unten-Kontakt (`redstone_relay_24`) schaltet nur, solange Y noch ausgefahren ist -- sobald Y einfaehrt, geht er aus, auch wenn Z physisch weiterhin unten steht. Er wird daher nur waehrend der Z-Bewegung selbst geprueft (in `treppe1Einfahren()`, Schritt 1, solange Y noch nicht zurueckgefahren ist). Fuer die dauerhafte Bestaetigung im Ruhezustand gibt es den zweiten, eigenstaendigen Kontakt `redstone_relay_31`, der genau in der Y-eingefahren-Position funktioniert.

"Treppe"-Zustand: Y-ausgefahren-Kontakt allein. "Grundstellung"-Zustand (verschwunden), dauerhaft: Y-eingefahren UND Z-unten-bei-Y-eingefahren zusammen.

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
| Z unten + A 90 Grad | Z unten UND A 90 Grad zusammen (Boden eingefahren, Treppe sichtbar) -- schaltet nur bei X links | `redstone_relay_28` |
| Z oben + A 0 Grad | Z oben UND A 0 Grad zusammen (Boden ausgefahren, Grundstellung) -- schaltet nur wenn A nicht gedreht | `redstone_relay_29` |

**Wichtig:** In der Grundstellung ist die Treppe NICHT sichtbar -- Grundstellung bedeutet Boden ausgefahren (X rechts + Z oben + A 0 Grad). "Treppe sichtbar" bedeutet Treppenmodul1+2 Y ausgefahren UND Boden eingefahren (X links + Z unten + A 90 Grad).

## Seiten-Unabhaengigkeit bei Relais

Die konkrete Blockseite ist an jedem Relay physisch egal, weil jedes Relay nur ein einziges Signal traegt -- die Peripheral-API verlangt aber trotzdem immer eine Seite als Parameter. Deshalb prueft der Code bei jedem Eingangs-Relay automatisch **alle 6 Seiten** (ODER-Verknuepfung: irgendeine Seite aktiv reicht) und setzt bei jedem Ausgangs-Relay **alle 6 Seiten gleichzeitig**. Das `seite`-Feld in `config.lua` wird dadurch nicht mehr verwendet -- egal wie die Relais im Spiel ausgerichtet sind, es wird trotzdem erkannt.

## Auto-Kalibrierung (Achsen mit Kontakt an beiden Endpunkten)

Fuer Achsen, die an **beiden** Endpunkten einen eigenen Kontakt haben, wird statt einer festen Distanz in kleinen Schritten gefahren, bis der Ziel-Kontakt schaltet:

- **Treppe1-Y** (aus- und einfahren)
- **Treppe2-Y** (aus- und einfahren)
- **Boden-X** (links und rechts)
- **Treppe1-Z**, nur Richtung "unten" (einfahren) -- "oben" hat keinen Kontakt, bleibt daher bei fester Distanz

Nicht moeglich fuer **Boden-Z** und **Boden-A** (Drehung), da dort nur kombinierte Kontakte existieren, die waehrend des jeweiligen Einzelschritts noch nicht zuverlaessig auswertbar sind -- diese bleiben bei fester Distanz/festem Winkel (`config.lua`: `distanzen.boden_z`/`boden_a`).

Schrittgroesse und Sicherheitsabbruch (max. Schritte, falls der Kontakt nie kommt) sind in `config.lua` unter `auto_kalibrierung` einstellbar, auch live im Programm unter Menuepunkt `a`.

**Sicherheitspause:** Nach jeder Kontakt-Bestaetigung (Auto-Kalibrierung oder finale Relay-Pruefung) wartet das Skript zusaetzlich `sicherheitspause_sekunden` (Standard 0,5s, in `config.lua`), bevor der naechste Schritt startet. Manche Kontakte schalten kurz bevor die Bewegung mechanisch wirklich ganz fertig ist -- diese Pause faengt das ab. Auch live im Programm unter Menuepunkt `a` einstellbar.

**Settle-Pause vor der ersten Kontaktpruefung:** Direkt nach dem Umschalten eines Achsen-Signals wartet das Skript kurz (Standard 0,25s, `settle_pause_sekunden` in `config.lua`), bevor der Zielkontakt zum ersten Mal geprueft wird. Ohne diese Pause konnte der allererste Check noch einen veralteten Redstone-Wert von VOR dem Umschalten lesen und faelschlich "0 Schritte / Kontakt bereits erreicht" melden, obwohl die Achse noch gar nicht am Ziel war. Tritt das trotzdem noch auf, den Wert erhoehen (z.B. auf 1.0) -- tritt es auch dann noch auf, deutet das eher auf ein physisches Kontaktproblem als auf Timing hin.

## Gesamtablauf: Reihenfolge und Parallelitaet

Treppenmodul1 (Y, Z) und Boden (X, Z, A) laufen jeweils ueber einen einzigen Gearshift pro Richtung -- welche Achse gerade angetrieben wird, waehlen die Redstone-Ausgangs-Relais als Achsen-Selektor:

- **Treppe1:** Y-Achse kein Signal, Z-Achse `treppe1_z`-Relay an
- **Boden:** X-Achse kein Signal, Z-Achse `boden_z`-Relay an, A-Achse (Drehung) `boden_x`- UND `boden_z`-Relay an

Da die Gearshifts selbst keine interne Sequenz programmiert haben, steuert das Lua-Skript alle Achsen als separate Schritte, mit `isRunning()`-Polling zwischen den Schritten (da es fuer Zwischenzustaende keine Relay-Kontakte gibt). Einige Schritte laufen dabei **gleichzeitig** (echte Parallelitaet ueber `parallel.waitForAll`), andere nacheinander:

**Grundstellung -> Treppe** (`treppeHerstellen`):
1. Boden Z faehrt runter (oben -> unten)
2. Boden X faehrt nach links (rechts -> links)
3. **Gleichzeitig:** Boden dreht auf 90 Grad, Treppe1 Y faehrt aus, Treppe2 Y faehrt aus
4. Treppe1 Z faehrt hoch (unten -> oben)

**Treppe -> Grundstellung** (`treppeVerschwinden`):
1. Treppe1 Z faehrt runter (oben -> unten)
2. **Gleichzeitig:** Treppe1 Y faehrt ein, Treppe2 Y faehrt ein
3. Boden dreht auf 0 Grad (90 -> 0)
4. Boden X faehrt nach rechts (links -> rechts)
5. Boden Z faehrt hoch (unten -> oben)

Erst nach dem letzten Schritt wird fuer alle Module per Relay-Kontakt die finale Endlage bestaetigt.

Distanzen fuer die nicht auto-kalibrierten Achsen sind in `config.lua` unter `distanzen.treppe1_z`/`boden_z`/`boden_a` einstellbar (auch live im Programm, Menuepunkte 8 und 7). Jede Achse hat zudem einen eigenen Richtungsmodifier unter `richtung`.

## Externer Monitor mit Touch-Steuerung

Wird ein (Advanced) Monitor per Modem am Computer angeschlossen erkannt, zeigt das Skript dort automatisch eine zweite Bedienoberflaeche mit Touch-Buttons:

- **Status** (Treppe/Boden sichtbar, farblich unterschieden) und ob gerade eine Bewegung laeuft
- **Automatik-Button:** togglet zwischen Treppe und Grundstellung (gleiche Verriegelung wie der Redstone-Trigger)
- **Manuelle Buttons** fuer Treppe1, Treppe2 und Boden, je Aus- und Einfahren (gleiche lockere Verriegelung wie die Terminal-Menuepunkte 4/5/6 -- nur Busy-Check, kein Gesamtzustand noetig)
- **Whitelist-Anzeige:** ob gerade ein berechtigter Spieler im Geofence-Bereich ist

Der Monitor aktualisiert sich automatisch bei Zustandsaenderungen (auch wenn die Aenderung durch Redstone-Trigger oder Geofence im Hintergrund ausgeloest wurde), nicht nur bei eigenen Touch-Eingaben. Ohne angeschlossenen Monitor laeuft alles unveraendert nur ueber das Terminal -- die Monitor-Funktion bleibt dann automatisch inaktiv.

## Log-Datei

Jede Status-, Bewegungs-, Abbruch- und Sperr-Meldung landet zusaetzlich mit Zeitstempel (Millisekunden-genau) in `treppe_log.txt` -- nichts geht mehr durch Wegscrollen oder ein zu schnell verschwindendes Terminal verloren. Auch jede Aenderung eines Ausgangs-Relais (Treppe1-Z, Boden-X, Boden-Z: AN/aus) wird protokolliert.

- **Terminal:** Menuepunkt `l` -- oeffnet die Datei im eingebauten Editor (Scrollen/Suchen) oder leert sie
- Die Datei waechst automatisch bis 100 KB, danach wird die aeltere Haelfte automatisch verworfen (kein unbegrenztes Wachstum)

Besonders nuetzlich bei Fehlern, die im Terminal live schwer zu erwischen sind (z.B. schnelle Bewegungsablaeufe) -- einfach danach `treppe_log.txt` durchsehen, um genau zu sehen, was wann passiert ist.

## Kontakte-Status

Alle 12 Relais (3 Ausgaenge + 9 Eingaenge) lassen sich live einsehen, jeweils AN/aus:

- **Terminal:** Menuepunkt `k` -- aktualisiert sich automatisch jede Sekunde, mit beliebiger Taste zurueck zum Hauptmenue
- **Monitor:** Button "Kontakte" auf der Hauptseite -- eigene Ansicht mit "Zurueck"-Button, aktualisiert sich ebenfalls automatisch

Nuetzlich zur Fehlersuche, z.B. um zu pruefen, ob ein Kontakt schon zu frueh oder gar nicht schaltet.

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

Beim Programmstart wird der aktuelle Zustand ueber die Relay-Kontakte ermittelt. Ist der Zustand nicht eindeutig bestimmbar, faehrt das Programm automatisch in einen bekannten Zustand: zuerst wird Boden-X explizit auf "rechts" gebracht (X hat keine Vorbedingung, funktioniert daher sicher aus jeder Ausgangsposition), erst danach startet der normale Ablauf zur Treppe. Das ist noetig, weil Boden-Z's Vorbedingung ("X rechts") bei unbekanntem Zustand sonst nie sicher erfuellt waere und der Ablauf sofort abbrechen wuerde.

## Startup

Der Installer schreibt zusaetzlich eine `startup.lua`, die `treppe_boden.lua` bei jedem Boot des Computers automatisch startet. Bei einem Fehler im Hauptskript wird nach 5 Sekunden automatisch neu gestartet.

## Ausloesung (Geofence, unveraendert)

- **Redstone-Trigger** (physischer Input am Computer): steigende Flanke togglet den Zustand, hat immer Vorrang vor der Geofence-Logik
- **Geofence / Player Detector**: solange mindestens ein Whitelist-Spieler (`spieler.erlaubte_spieler` in `config.lua`) im konfigurierten Bereich ist, wird die Treppe erzwungen; verlassen alle Whitelist-Spieler den Bereich, wird der Boden erzwungen
- **Manuell** ueber die UI (Menuepunkte 4/5/6 fuer einzelne Module, 9 fuer den kompletten Toggle-Ablauf)

## Wichtiger Timing-Fix: echte Wanduhrzeit statt os.clock()

Alle Timeouts (`warteAufRelay`, `wartenBisFertig`) nutzten urspruenglich `os.clock()` zur Zeitmessung. In CC:Tweaked misst `os.clock()` waehrend `sleep()`-lastiger Warteschleifen aber **keine** verlaessliche Realzeit -- ein konfigurierter 15-Sekunden-Timeout (`timeout_sekunden`) konnte dadurch in Wirklichkeit weit ueber eine Minute REAL dauern, bevor er tatsaechlich griff (im Log stand dann faelschlich "nach 15.5s", obwohl real ueber 90 Sekunden vergangen waren). Alle Zeitmessungen laufen jetzt ueber `os.epoch("utc")` (echte Wanduhrzeit in Millisekunden) -- die geloggten Zeiten stimmen dadurch jetzt mit der tatsaechlich vergangenen Zeit ueberein.

## Fehlerbehandlung bei fehlgeschlagenen Schritten

Jeder Achsen-Teilschritt (Auto-Kalibrierung wie feste Distanz) meldet zurueck, ob er wirklich erfolgreich war (Kontakt erreicht bzw. Bewegung abgeschlossen). Schlaegt ein Schritt fehl (z.B. Auto-Kalibrierung erreicht den Kontakt nicht innerhalb von `auto_max_schritte`), bricht der **gesamte** Ablauf sofort ab -- der Zustand wird NICHT gewechselt, und es folgen keine weiteren Schritte, die auf einer nicht erreichten Position aufbauen wuerden. Eine `ABBRUCH:`-Meldung zeigt, welcher Schritt gescheitert ist. Zur Fehlersuche danach Menuepunkt `k` (Kontakte-Status) oder `l` (Log) nutzen.

## Explizite Vorbedingungspruefung vor jeder Bewegung

Bevor eine Achse ueberhaupt startet, prueft der Code **per Kontakt**, ob die noetige Vorbedingung wirklich erfuellt ist -- nicht nur implizit durch die Aufrufreihenfolge angenommen:

- **Treppe1 Y** faehrt nur, wenn Z per Kontakt als "unten" bestaetigt ist
- **Treppe1 Z ausfahren** (hoch) faehrt nur, wenn Y per Kontakt als "ausgefahren" bestaetigt ist
- **Boden Z** faehrt nur, wenn X per Kontakt als "rechts" bestaetigt ist
- **Boden A** (Drehung) faehrt nur, wenn X per Kontakt als "links" bestaetigt ist

Ist die Vorbedingung nicht erfuellt, wird die Bewegung mit einer `ABBRUCH:`-Meldung verweigert, statt blind loszufahren. Ist das Fahrziel eines Schritts bereits erreicht (Auto-Kalibrierung), wird die Bewegung automatisch uebersprungen -- `fahreBisKontakt` prueft das sicher per Kontakt, bevor der erste Fahrschritt ausgefuehrt wird.

**Einschraenkung:** Fuer Boden-A's zweite Teil-Vorbedingung ("Z unten") existiert kein isolierter, unabhaengig pruefbarer Kontakt bei Boden (nur der kombinierte Z+A90-Kontakt, der zirkulaer waere) -- hier verlaesst sich der Code auf die feste Aufrufreihenfolge (Boden-Z laeuft immer vor Boden-A).

## Verriegelung

Bevor eine neue Bewegung startet, prueft das Programm per Relay-Kontakt, ob das System vollstaendig in einer bekannten Endlage steht. Laeuft bereits eine Bewegung oder ist der Zustand nicht eindeutig, wird die neue Aktion verweigert.

**Automatik** (Redstone-Trigger, Geofence, Menuepunkt 9) prueft dabei den **gesamten** Systemzustand -- alle 3 Module muessen gemeinsam bestaetigt sein.

**Manuelle Einzeltests** (Menuepunkte 4/5/6) pruefen nur, ob gerade schon eine andere Bewegung laeuft -- NICHT den Zustand der anderen Module. So laesst sich jedes Modul einzeln kalibrieren/testen, auch wenn andere Module noch nicht vollstaendig verkabelt sind.

## Status

Positions-/Kontaktarchitektur wurde komplett neu definiert und mit finaler Relay-Zuordnung umgesetzt. Noch keine vollstaendigen In-Game-Tests durchgefuehrt.












