
MRead = {}
MWrite = {}

local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local bshr = bit.rshift
local bshl = bit.lshift


------------------------
-- Main R/W Functions --
------------------------

function Read(Addr)

	if not MRead[Addr] then error( string.format( "%X", Addr) ) end

	return MRead[Addr]( Addr )
end

function Write(Addr,Data)

	if not MWrite[Addr] then error( string.format( "%X", Addr) ) end

	MWrite[Addr]( Addr, Data )
end
local function ReadBiosSpace( Addr ) return EnableBios and BIOS[ Addr ] or ROM[ Addr ] end
local function ReadRomZero( Addr )   return ROM[ Addr] end

local function ReadRomOne( Addr )
	if CartMode == 0 then return ROM[ Addr ] end
	if CartMode == 3 then return ROM[ Addr + 0x4000*(RomBank-1) ] end
end

local function ReadVideoRam( Addr ) return VRAM[ Addr ] end

local function ReadExternalRam( Addr )
	if CartMode == 3 then return ERAM[ Addr + 0x2000*RamBank ] end
end

local function ReadMainRam	( Addr ) return WRAM[Addr] end
local function ReadEchoRam	( Addr ) return WRAM[Addr - 0x2000] end
local function ReadSpriteRam( Addr ) return OAM[Addr] end
local function ReadHighRam	( Addr ) return HRAM[Addr] end

local function ReadIO ( Addr ) return IO[Addr] end

-------------------------
-- WRITE Memory Ranges --
-------------------------

local function RamTimerEnable( Addr, Data )
	if CartMode == 3 then
		if Data == 0x0A then CartRamTimerEnable = true end
		if Data == 0x00 then CartRamTimerEnable = false end
	end
end


local function RomBankNumber( Addr, Data )
	if CartMode == 3 then RomBank = band( Data > 0 and Data or 1, 127 ) end
end

local function RamBankNumber( Addr, Data )
	if CartMode == 3 and Data < 4 then RamBank = band(Data, 3) end
end

local function RomRamModeSelect( Addr, Data )
end

local function WriteVideoRam( Addr, Data ) VRAM[Addr] = Data end

local function WriteExternalRam( Addr, Data )
	if CartMode == 3 then ERAM[Addr + 0x2000*RamBank ] = Data end
end

local function WriteMainRam  ( Addr, Data ) WRAM[Addr] = Data end
local function WriteEchoRam  ( Addr, Data ) end
local function WriteSpriteRam( Addr, Data ) OAM[Addr] = Data end
local function WriteHighRam  ( Addr, Data ) HRAM[Addr] = Data end

local function WriteIO  ( Addr, Data ) IO[Addr] = Data end


local function WriteNothing ( Addr, Data ) end
local function ReadNothing ( Addr ) return 0 end

------------------------
-- READ Memory Ranges --
------------------------

-- Read
for n = 0x0000, 0x00FF 	do MRead[n] = ReadBiosSpace end
for n = 0x0100, 0x3FFF 	do MRead[n] = ReadRomZero end
for n = 0x4000, 0x7FFF 	do MRead[n] = ReadRomOne end

for n = 0x8000, 0x9FFF 	do MRead[n] = ReadVideoRam end
for n = 0xA000, 0xBFFF 	do MRead[n] = ReadExternalRam end
for n = 0xC000, 0xDFFF 	do MRead[n] = ReadMainRam end
for n = 0xE000, 0xFDFF  do MRead[n] = ReadEchoRam end
for n = 0xFE00, 0xFE9F 	do MRead[n] = ReadSpriteRam end
for n = 0xFEA0, 0xFEFF 	do MRead[n] = ReadNothing end --- empty space
for n = 0xFF00, 0xFF7F  do MRead[n] = ReadIO end
for n = 0xFF80, 0xFFFE 	do MRead[n] = ReadHighRam end

-- Write

for n = 0x0000, 0x1FFF  do MWrite[n] = RamTimerEnable end
for n = 0x2000, 0x3FFF 	do MWrite[n] = RomBankNumber end
for n = 0x4000, 0x5FFF 	do MWrite[n] = RamBankNumber end
for n = 0x6000, 0x7FFF  do MWrite[n] = RomRamModeSelect end

for n = 0x8000, 0x9FFF 	do MWrite[n] = WriteVideoRam end
for n = 0xA000, 0xBFFF 	do MWrite[n] = WriteExternalRam end
for n = 0xC000, 0xDFFF 	do MWrite[n] = WriteMainRam end
for n = 0xE000, 0xFDFF  do MWrite[n] = WriteEchoRam end
for n = 0xFE00, 0xFE9F 	do MWrite[n] = WriteSpriteRam end
for n = 0xFEA0, 0xFEFF 	do MWrite[n] = WriteNothing end --- empty space
for n = 0xFF00, 0xFF7F  do MWrite[n] = WriteIO end
for n = 0xFF80, 0xFFFE 	do MWrite[n] = WriteHighRam end




















------------------------
-- Hardware registers --
------------------------

--- DMA Transfer

MRead[ 0xFF46 ] = function(  Addr ) return 0 end

MWrite[ 0xFF46 ] = function(  Addr, Data )
	DMAddr = bshl(Data, 8)

	for n = 0, 0xA0 do
		OAM[ bor( 0xFE00 , n ) ] = Read( bor( DMAddr , n ) )
	end
end







-- Disable Bootrom
MRead[ 0xFF50 ] = function(  Addr ) return 0 end
MWrite[ 0xFF50 ] = function(  Addr ) EnableBios = false end










