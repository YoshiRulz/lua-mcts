SystemDataPtr = mainmemory.read_s16_le(0x2538)
GameDataPtr = mainmemory.read_s16_le(SystemDataPtr + 0xC)

CursorX = mainmemory.readbyte(GameDataPtr + 0x62E)
CursorY = mainmemory.readbyte(GameDataPtr + 0x630)

UnitXPosArr = GameDataPtr + 0xA8C
UnitYPosArr = GameDataPtr + 0xA9C

UNIT_ADDR = 0x28DC
UNIT_SIZE = 0xEC
		
gameMode = mainmemory.readbyte(0x38A0)
		
for i=0,15,1 do
	curUnit = UNIT_ADDR + i*UNIT_SIZE
	unitID = mainmemory.readbyte(curUnit)
	unitFlags = mainmemory.readbyte(curUnit+0xB8)
	unitStatus = mainmemory.readbyte(curUnit+0x4A)
				
	if (unitID > 0 and unitID <= 16)
		and bit.band(unitFlags,1) == 0 
		and bit.band(unitStatus,1) == 1
		then
		print("Unit ID: " .. unitID)
		unitXpos = mainmemory.readbyte(UnitXPosArr + i)
		unitYpos = mainmemory.readbyte(UnitYPosArr + i)
		print("Pos: " .. unitXpos .. ", " .. unitYpos)
	end
end