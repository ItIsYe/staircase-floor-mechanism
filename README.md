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
