function set_breakpoint(addr, breaktype, regdump, numRegs)
	print("Setting breakpoint: " .. string.format("%x", addr))
	numRegs = numRegs or 0
	if (breaktype == "r") then
		f = event.onmemoryread
	elseif (breaktype == "w") then
		f = event.onmemorywrite
	elseif (breaktype == "x") then
		f = event.onmemoryexecute
	else
		print("ERROR: invalid breaktype [" .. breaktype .. "]")
		return
	end

	return f(function()
		print("Breakpoint hit: " .. string.format("%x", addr))
		emu.setregister("R0", 5)
		emu.setregister("R1", 5)
		emu.setregister("R2", 5)
		if regdump then
			regs = emu.getregisters()
			for i = 0,numRegs-1,1 do
				str = "R" .. tostring(i)
				print(str .. ": " .. string.format("%x", regs[str]))
			end
		end
		client.pause()
	end, addr)
end

set_breakpoint(0x080b5b1c, "x", true, 3)

while true do
	emu.frameadvance()
end