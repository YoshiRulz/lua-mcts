UNIT_ADDR = 0x28DC
UNIT_SIZE = 0xEC

UNIT_TYPES = {}
UNIT_TYPES[0] = "Dummy"

UNIT_TYPES[1] = "Onimaru"
UNIT_TYPES[2] = "Oboro"
UNIT_TYPES[3] = "Ageha"
UNIT_TYPES[4] = "Magoichi"
UNIT_TYPES[5] = "Kaidomaru"
UNIT_TYPES[6] = "Mitsuhide"
UNIT_TYPES[7] = "Kotaro"
UNIT_TYPES[8] = "Ekei"
UNIT_TYPES[9] = "Tsubame"
UNIT_TYPES[10] = "Hikoichi"
UNIT_TYPES[11] = "Bomaru"
UNIT_TYPES[12] = "Hanpeita"
UNIT_TYPES[13] = "Saizo"
UNIT_TYPES[14] = "Sandayu"
UNIT_TYPES[15] = "Okuni"
UNIT_TYPES[16] = "Yoichi"
UNIT_TYPES[17] = "Kabuki"
UNIT_TYPES[18] = "Kotetsu"
UNIT_TYPES[19] = "Sakura"
UNIT_TYPES[20] = "Shura"
UNIT_TYPES[21] = "Sanjuro"
UNIT_TYPES[22] = "Onikko"
UNIT_TYPES[23] = "Onimusha"
UNIT_TYPES[24] = "Soldier"
UNIT_TYPES[25] = "Soldier"
UNIT_TYPES[26] = "Soldier"
UNIT_TYPES[27] = "Oni-Oboro"
UNIT_TYPES[28] = "Hideyoshi"
UNIT_TYPES[29] = "Nobunaga"
UNIT_TYPES[30] = "Katsuyori"
UNIT_TYPES[98] = "Genma Pawn"
UNIT_TYPES[110] = "Jaid"
UNIT_TYPES[130] = "Dorogand"
UNIT_TYPES[131] = "Dorogand New"

SpriteDataPtr = mainmemory.read_s16_le(0x2538)
--print(string.format("%x",SpriteDataPtr))
DataPtr2 = mainmemory.read_s16_le(SpriteDataPtr + 0xC)
--print(string.format("%x",DataPtr2))

CursorY = mainmemory.readbyte(DataPtr2 + 0x62E)
CursorX = mainmemory.readbyte(DataPtr2 + 0x630)
print("Cursor pos: " .. CursorX .. ", " .. CursorY)

while false do
	i = 0
	UnitY = mainmemory.readbyte(DataPtr2 + 0xA8C + i)
	UnitX = mainmemory.readbyte(DataPtr2 + 0xA9C + i)
	print("Location of Unit #" .. i .. ": " .. UnitX .. ", " .. UnitY)
	print(string.format("%x",DataPtr2 + 0xA9C + i))
end

for i=0,15,1 do
	curUnit = UNIT_ADDR + UNIT_SIZE*i
	
	unitID = mainmemory.readbyte(curUnit)
	
	mainmemory.writebyte(curUnit, 0x83)
	unitLVL = mainmemory.readbyte(curUnit+40)
	--mainmemory.writebyte(curUnit+40, 99)
	unitHP = mainmemory.readbyte(curUnit+46)
	unitSP = mainmemory.readbyte(curUnit+50)
	unitMaxHP = mainmemory.readbyte(curUnit+168)
	unitMaxSP = mainmemory.readbyte(curUnit+170)
	unitEXP = mainmemory.readbyte(curUnit+180)
	
	unitATK = mainmemory.readbyte(curUnit+54)
	unitDEF = mainmemory.readbyte(curUnit+58)
	unitINT = mainmemory.readbyte(curUnit+60)
	unitAGL = mainmemory.readbyte(curUnit+62)
	
	unitx24 = mainmemory.readbyte(curUnit+0x24)
	--mainmemory.writebyte(curUnit+0x24, 99)
	unitx26 = mainmemory.readbyte(curUnit+0x26)
	--mainmemory.writebyte(curUnit+0x26, 99)
	unitx28 = mainmemory.readbyte(curUnit+0x28)
	--mainmemory.writebyte(curUnit+0x28, 99)
	unitx2A = mainmemory.readbyte(curUnit+0x2A)
	--mainmemory.writebyte(curUnit+0x2A, 99)
	unitx2C = mainmemory.readbyte(curUnit+0x2C)
	--mainmemory.writebyte(curUnit+0x2C, 99)
	
	unitx4A = mainmemory.readbyte(curUnit+0x4A)
	
	unit_unk63 = mainmemory.readbyte(curUnit+63)
	unit_unk63 = mainmemory.readbyte(curUnit+74)
	unit_unk82 = mainmemory.readbyte(curUnit+82)
	unit_unk164 = mainmemory.readbyte(curUnit+164)
	unit_unk192 = mainmemory.readbyte(curUnit+192)
	unit_unk208 = mainmemory.readbyte(curUnit+208)
	unit_unk232 = mainmemory.readbyte(curUnit+232)
	
	if unitID ~= 0 then
		print(string.format("%x",curUnit))
		print("Unit #" .. i .. ": " .. UNIT_TYPES[unitID])
		print("Lvl " .. unitLVL .. ": " .. unitEXP .. " EXP")
		print("HP: " .. unitHP .. "/" .. unitMaxHP)
		print("SP: " .. unitSP .. "/" .. unitMaxSP)
		print("4A: " .. unitx4A)
	end
end