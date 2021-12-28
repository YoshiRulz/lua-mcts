bag = {}


function print_registers(addr)
	event.onmemoryexecute(
	function()
		name = tostring(emu.getregister("R1")) .. "." .. tostring(emu.getregister("R2"))
		bag[name] = true
	end, addr)
end

print_registers(0x0806870C)

while true do
	emu.getregisters()
	emu.frameadvance()
	found = false 
	for k,v in pairs(bag) do
		print(k)
		found = true
	end
	if found then break end
end