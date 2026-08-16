-- Kleines Hilfsskript: schreibt alle Peripherals in eine Datei,
-- damit man sie in Ruhe durchblaettern kann (edit peripherals.txt)
-- statt sie auf dem Bildschirm wegscrollen zu sehen.

local f = fs.open("peripherals.txt", "w")

local namen = peripheral.getNames()
table.sort(namen)

f.write("Gefundene Peripherals (" .. #namen .. "):\n\n")
for _, name in ipairs(namen) do
    f.write(name .. "  (" .. tostring(peripheral.getType(name)) .. ")\n")
end

f.close()
print("Liste gespeichert in peripherals.txt")
print("Ansehen mit: edit peripherals.txt")
