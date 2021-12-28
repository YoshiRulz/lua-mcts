require "dug-tas-lib"

set_breakpoint(0x080b1c54, "x", true)

while true do
	emu.frameadvance()
end