-- ============================================
-- Monitor-GUI fuer Treppen-/Boden-Mechanismus
--
-- Diese Datei enthaelt AUSSCHLIESSLICH Darstellung, Touch-Hit-Testing
-- und Navigation fuer den Advanced Monitor.
--
-- WICHTIG:
--   Keine Bewegungslogik, keine Gearshift-Steuerung und keine
--   Verriegelungslogik befinden sich hier. Alle Aktionen werden ueber
--   Callbacks an treppe_boden.lua zurueckgegeben.
-- ============================================

local M = {}

local FARBE = {
    hintergrund = colors.black,
    panel = colors.gray,
    text = colors.white,
    gedimmt = colors.lightGray,
    ok = colors.lime,
    warnung = colors.orange,
    fehler = colors.red,
    aktiv = colors.cyan,
    button = colors.blue,
    buttonSekundaer = colors.gray,
    buttonGefahr = colors.red,
    deaktiviert = colors.gray,
}

local function begrenzen(text, breite)
    text = tostring(text or "")
    if #text <= breite then return text end
    if breite <= 3 then return text:sub(1, breite) end
    return text:sub(1, breite - 3) .. "..."
end

function M.new(opt)
    assert(type(opt) == "table", "monitor_gui: Optionen fehlen")
    assert(opt.monitor, "monitor_gui: Monitor fehlt")
    assert(type(opt.getZustand) == "function", "monitor_gui: getZustand fehlt")
    assert(type(opt.istVerriegelt) == "function", "monitor_gui: istVerriegelt fehlt")
    assert(type(opt.automatik) == "function", "monitor_gui: automatik fehlt")
    assert(type(opt.manuell) == "function", "monitor_gui: manuell fehlt")
    assert(type(opt.kontakte) == "function", "monitor_gui: kontakte fehlt")

    local monitor = opt.monitor
    local buttons = {}
    local modus = "dashboard"

    local function groesse()
        return monitor.getSize()
    end

    local function reset()
        buttons = {}
        monitor.setBackgroundColor(FARBE.hintergrund)
        monitor.setTextColor(FARBE.text)
        monitor.clear()
    end

    local function text(x, y, wert, farbe, bg)
        local w = select(1, groesse())
        if x > w or y < 1 then return end
        monitor.setCursorPos(math.max(1, x), y)
        monitor.setTextColor(farbe or FARBE.text)
        monitor.setBackgroundColor(bg or FARBE.hintergrund)
        monitor.write(begrenzen(wert, math.max(0, w - x + 1)))
    end

    local function fill(x, y, breite, hoehe, bg)
        local w, h = groesse()
        local x1 = math.max(1, x)
        local y1 = math.max(1, y)
        local x2 = math.min(w, x + breite - 1)
        local y2 = math.min(h, y + hoehe - 1)
        if x1 > x2 or y1 > y2 then return end
        monitor.setBackgroundColor(bg)
        for yy = y1, y2 do
            monitor.setCursorPos(x1, yy)
            monitor.write(string.rep(" ", x2 - x1 + 1))
        end
        monitor.setBackgroundColor(FARBE.hintergrund)
    end

    local function button(x, y, breite, hoehe, label, bg, aktion, aktiv)
        local w, h = groesse()
        if x > w or y > h then return end
        aktiv = aktiv ~= false
        local farbe = aktiv and bg or FARBE.deaktiviert
        fill(x, y, breite, hoehe, farbe)

        local labelY = y + math.floor((hoehe - 1) / 2)
        local labelX = x + math.max(0, math.floor((breite - #label) / 2))
        text(labelX, labelY, label, FARBE.text, farbe)

        if aktiv and aktion then
            table.insert(buttons, {
                x1 = x,
                y1 = y,
                x2 = math.min(w, x + breite - 1),
                y2 = math.min(h, y + hoehe - 1),
                aktion = aktion,
            })
        end
    end

    local function statusPunkt(x, y, label, aktiv, farbeAktiv)
        text(x, y, aktiv and "*" or "o", aktiv and (farbeAktiv or FARBE.ok) or FARBE.gedimmt)
        text(x + 2, y, label, FARBE.text)
    end

    local function header(titel)
        local w = select(1, groesse())
        local verriegelt = opt.istVerriegelt()
        fill(1, 1, w, 2, FARBE.panel)
        text(2, 1, titel or "TREPPENSTEUERUNG", FARBE.text, FARBE.panel)
        local status = verriegelt and "BEWEGUNG" or "BEREIT"
        local farbe = verriegelt and FARBE.warnung or FARBE.ok
        local x = math.max(2, w - #status - 2)
        text(x, 1, "* " .. status, farbe, FARBE.panel)
    end

    local function footer()
        local w, h = groesse()
        if h < 4 then return end
        fill(1, h, w, 1, FARBE.panel)
        local spieler = false
        if type(opt.spielerImBereich) == "function" then
            local ok, wert = pcall(opt.spielerImBereich)
            spieler = ok and wert == true
        end
        local verriegelt = opt.istVerriegelt()
        text(2, h, "SPIELER " .. (spieler and "JA" or "NEIN"), spieler and FARBE.ok or FARBE.gedimmt, FARBE.panel)
        local lockText = "LOCK " .. (verriegelt and "AN" or "AUS")
        text(math.max(2, w - #lockText - 1), h, lockText, verriegelt and FARBE.warnung or FARBE.gedimmt, FARBE.panel)
    end

    local function zeichneDashboard()
        reset()
        header("TREPPENSTEUERUNG")
        local w, h = groesse()
        local zustand = opt.getZustand()
        local verriegelt = opt.istVerriegelt()

        text(2, 4, "AKTUELLER ZUSTAND", FARBE.gedimmt)

        local zustandsText
        local zustandsFarbe
        if zustand == "boden" then
            zustandsText = "BODEN SICHTBAR"
            zustandsFarbe = FARBE.ok
        elseif zustand == "treppe" then
            zustandsText = "TREPPE SICHTBAR"
            zustandsFarbe = FARBE.ok
        else
            zustandsText = "ZUSTAND UNBEKANNT"
            zustandsFarbe = FARBE.warnung
        end

        local boxBreite = math.min(math.max(22, #zustandsText + 6), math.max(10, w - 4))
        local boxX = math.max(2, math.floor((w - boxBreite) / 2) + 1)
        fill(boxX, 6, boxBreite, 3, FARBE.panel)
        text(boxX + math.max(1, math.floor((boxBreite - #zustandsText) / 2)), 7, zustandsText, zustandsFarbe, FARBE.panel)

        if zustand == "boden" then
            text(2, 10, "Treppe eingefahren", FARBE.gedimmt)
            text(2, 11, "Boden ausgefahren", FARBE.gedimmt)
        elseif zustand == "treppe" then
            text(2, 10, "Treppe ausgefahren", FARBE.gedimmt)
            text(2, 11, "Boden eingefahren", FARBE.gedimmt)
        else
            text(2, 10, "Endlage nicht eindeutig", FARBE.warnung)
        end

        local hauptLabel
        local darfAutomatik = not verriegelt and (zustand == "boden" or zustand == "treppe")
        if verriegelt then
            hauptLabel = "BEWEGUNG LAEUFT"
        elseif zustand == "boden" then
            hauptLabel = "TREPPE AUSFAHREN"
        elseif zustand == "treppe" then
            hauptLabel = "BODEN HERSTELLEN"
        else
            hauptLabel = "NICHT VERFUEGBAR"
        end

        local hauptBreite = math.min(30, math.max(18, w - 4))
        button(math.max(2, math.floor((w - hauptBreite) / 2) + 1), 13, hauptBreite, 3,
            hauptLabel, FARBE.button, "automatik", darfAutomatik)

        if h >= 20 then
            local gap = 2
            local rand = 2
            local bw = math.floor((w - rand * 2 - gap) / 2)
            button(rand, 17, bw, 2, "MANUELL", FARBE.buttonSekundaer, "manuell_oeffnen", not verriegelt)
            button(rand + bw + gap, 17, bw, 2, "DIAGNOSE", FARBE.buttonSekundaer, "diagnose", true)
        else
            button(2, 17, math.min(12, w - 2), 1, "MANUELL", FARBE.buttonSekundaer, "manuell_oeffnen", not verriegelt)
            button(math.min(w - 10, 15), 17, math.min(12, w - 15), 1, "DIAGNOSE", FARBE.buttonSekundaer, "diagnose", true)
        end

        footer()
    end

    local function zeichneManuellBestaetigung()
        reset()
        header("WARTUNGSMODUS")
        local w = select(1, groesse())
        text(2, 5, "ACHTUNG", FARBE.warnung)
        text(2, 7, "Manuelle Einzelbewegungen pruefen", FARBE.text)
        text(2, 8, "nur, ob bereits eine Bewegung laeuft.", FARBE.text)
        text(2, 10, "Nur fuer Wartung und Tests verwenden.", FARBE.warnung)
        local bw = math.min(16, math.floor((w - 6) / 2))
        button(2, 13, bw, 2, "ABBRECHEN", FARBE.buttonSekundaer, "dashboard", true)
        button(w - bw - 1, 13, bw, 2, "FORTFAHREN", FARBE.buttonGefahr, "manuell_bestaetigt", true)
        footer()
    end

    local function zeichneManuell()
        reset()
        header("MANUELLE STEUERUNG")
        local w = select(1, groesse())
        local verriegelt = opt.istVerriegelt()
        text(2, 4, "WARTUNGSBETRIEB", FARBE.warnung)
        text(2, 5, verriegelt and "Bedienung gesperrt: Bewegung laeuft" or "Einzelmodule direkt fahren", verriegelt and FARBE.warnung or FARBE.gedimmt)

        local rand = 2
        local gap = 2
        local bw = math.floor((w - rand * 2 - gap) / 2)
        local rows = {
            { y = 8, titel = "TREPPE 1", aus = "treppe1_aus", ein = "treppe1_ein" },
            { y = 12, titel = "TREPPE 2", aus = "treppe2_aus", ein = "treppe2_ein" },
            { y = 16, titel = "BODEN", aus = "boden_aus", ein = "boden_ein" },
        }
        for _, r in ipairs(rows) do
            text(2, r.y - 1, r.titel, FARBE.text)
            button(rand, r.y, bw, 2, "AUSFAHREN", FARBE.buttonSekundaer, r.aus, not verriegelt)
            button(rand + bw + gap, r.y, bw, 2, "EINFAHREN", FARBE.buttonSekundaer, r.ein, not verriegelt)
        end
        button(2, 20, math.min(14, w - 2), 2, "< ZURUECK", FARBE.buttonSekundaer, "dashboard", true)
        footer()
    end

    local function zeichneDiagnose()
        reset()
        header("DIAGNOSE")
        local w, h = groesse()
        local liste = opt.kontakte() or {}
        local y = 4
        local letzteGruppe = nil

        for _, k in ipairs(liste) do
            if y >= h - 2 then break end
            local gruppe = k.gruppe or "SONSTIGE"
            if gruppe ~= letzteGruppe then
                if letzteGruppe ~= nil then y = y + 1 end
                if y >= h - 2 then break end
                text(2, y, gruppe, FARBE.text)
                y = y + 1
                letzteGruppe = gruppe
            end
            if y >= h - 2 then break end
            local aktiv = k.aktiv == true
            text(3, y, aktiv and "*" or "o", aktiv and FARBE.ok or FARBE.gedimmt)
            text(5, y, begrenzen(k.name or "Kontakt", math.max(5, w - 15)), aktiv and FARBE.text or FARBE.gedimmt)
            local status = aktiv and "AN" or "AUS"
            text(math.max(5, w - #status - 1), y, status, aktiv and FARBE.ok or FARBE.gedimmt)
            y = y + 1
        end

        button(2, math.max(4, h - 2), math.min(14, w - 2), 1, "< ZURUECK", FARBE.buttonSekundaer, "dashboard", true)
    end

    local function zeichnen()
        if modus == "dashboard" then
            zeichneDashboard()
        elseif modus == "manuell_warnung" then
            zeichneManuellBestaetigung()
        elseif modus == "manuell" then
            zeichneManuell()
        elseif modus == "diagnose" then
            zeichneDiagnose()
        else
            modus = "dashboard"
            zeichneDashboard()
        end
    end

    local function aktionAusfuehren(aktion)
        if aktion == "dashboard" then
            modus = "dashboard"
            return
        elseif aktion == "manuell_oeffnen" then
            modus = "manuell_warnung"
            return
        elseif aktion == "manuell_bestaetigt" then
            modus = "manuell"
            return
        elseif aktion == "diagnose" then
            modus = "diagnose"
            return
        elseif aktion == "automatik" then
            opt.automatik()
            return
        end

        opt.manuell(aktion)
    end

    local function touch(x, y)
        for _, b in ipairs(buttons) do
            if x >= b.x1 and x <= b.x2 and y >= b.y1 and y <= b.y2 then
                aktionAusfuehren(b.aktion)
                return true
            end
        end
        return false
    end

    local function run()
        zeichnen()
        local refreshTimer = os.startTimer(1)
        local letzterZustand = opt.getZustand()
        local letzteVerriegelung = opt.istVerriegelt()

        while true do
            local event, p1, p2, p3 = os.pullEvent()
            if event == "monitor_touch" then
                if touch(p2, p3) then
                    zeichnen()
                end
            elseif event == "monitor_resize" then
                zeichnen()
            elseif event == "timer" and p1 == refreshTimer then
                local neuerZustand = opt.getZustand()
                local neueVerriegelung = opt.istVerriegelt()
                if modus == "diagnose"
                    or neuerZustand ~= letzterZustand
                    or neueVerriegelung ~= letzteVerriegelung then
                    zeichnen()
                end
                letzterZustand = neuerZustand
                letzteVerriegelung = neueVerriegelung
                refreshTimer = os.startTimer(1)
            end
        end
    end

    return {
        run = run,
        zeichnen = zeichnen,
        setModus = function(neu)
            modus = neu
            zeichnen()
        end,
    }
end

return M
