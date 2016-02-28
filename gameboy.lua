function Restart()

	-- Memory
	BIOS = {}		-- Bios
	ROM = {} 		-- Used for external Cart ROM, each bank is offset by 0x4000

	ERAM = {}		-- Used for external Cart RAM, each bank is 8KB
	VRAM = {}		-- 2 Banks in CB mode, 1 in DMG
	WRAM = {} 		-- Main ram, 8 banks in CGB mode, 2 in DMG
	HRAM = {}		-- High Ram, 127B

	OAM = {}		-- Sprite Attribute  
	IO = {}

	for i = 0, 0x1FFFF do
		ERAM[i] = 0
		VRAM[i] = 0
		WRAM[i] = 0
		HRAM[i] = 0
		OAM[i] = 0
		IO[i] = 0
	end

	BIOS = { [0] = 0x31, 0xFE, 0xFF, 0xAF, 0x21, 0xFF, 0x9F, 0x32, 0xCB, 0x7C, 0x20, 0xFB, 0x21, 0x26, 0xFF, 0x0E, 0x11, 0x3E, 0x80, 0x32, 0xE2, 0x0C, 0x3E, 0xF3, 0xE2, 0x32, 0x3E, 0x77, 0x77, 0x3E, 0xFC, 0xE0, 0x47, 0x11, 0x04, 0x01, 0x21, 0x10, 0x80, 0x1A, 0xCD, 0x95, 0x00, 0xCD, 0x96, 0x00, 0x13, 0x7B, 0xFE, 0x34, 0x20, 0xF3, 0x11, 0xD8, 0x00, 0x06, 0x08, 0x1A, 0x13, 0x22, 0x23, 0x05, 0x20, 0xF9, 0x3E, 0x19, 0xEA, 0x10, 0x99, 0x21, 0x2F, 0x99, 0x0E, 0x0C, 0x3D, 0x28, 0x08, 0x32, 0x0D, 0x20, 0xF9, 0x2E, 0x0F, 0x18, 0xF3, 0x67, 0x3E, 0x64, 0x57, 0xE0, 0x42, 0x3E, 0x91, 0xE0, 0x40, 0x04, 0x1E, 0x02, 0x0E, 0x0C, 0xF0, 0x44, 0xFE, 0x90, 0x20, 0xFA, 0x0D, 0x20, 0xF7, 0x1D, 0x20, 0xF2, 0x0E, 0x13, 0x24, 0x7C, 0x1E, 0x83, 0xFE, 0x62, 0x28, 0x06, 0x1E, 0xC1, 0xFE, 0x64, 0x20, 0x06, 0x7B, 0xE2, 0x0C, 0x3E, 0x87, 0xE2, 0xF0, 0x42, 0x90, 0xE0, 0x42, 0x15, 0x20, 0xD2, 0x05, 0x20, 0x4F, 0x16, 0x20, 0x18, 0xCB, 0x4F, 0x06, 0x04, 0xC5, 0xCB, 0x11, 0x17, 0xC1, 0xCB, 0x11, 0x17, 0x05, 0x20, 0xF5, 0x22, 0x23, 0x22, 0x23, 0xC9, 0xCE, 0xED, 0x66, 0x66, 0xCC, 0x0D, 0x00, 0x0B, 0x03, 0x73, 0x00, 0x83, 0x00, 0x0C, 0x00, 0x0D, 0x00, 0x08, 0x11, 0x1F, 0x88, 0x89, 0x00, 0x0E, 0xDC, 0xCC, 0x6E, 0xE6, 0xDD, 0xDD, 0xD9, 0x99, 0xBB, 0xBB, 0x67, 0x63, 0x6E, 0x0E, 0xEC, 0xCC, 0xDD, 0xDC, 0x99, 0x9F, 0xBB, 0xB9, 0x33, 0x3E, 0x3C, 0x42, 0xB9, 0xA5, 0xB9, 0xA5, 0x42, 0x3C, 0x21, 0x04, 0x01, 0x11, 0xA8, 0x00, 0x1A, 0x13, 0xBE, 0x20, 0xFE, 0x23, 0x7D, 0xFE, 0x34, 0x20, 0xF5, 0x06, 0x19, 0x78, 0x86, 0x23, 0x05, 0x20, 0xFB, 0x86, 0x20, 0xFE, 0x3E, 0x01, 0xE0, 0x50 }

	
	-- Memory & Cart Flags
	EnableBios = true 	-- Enables the Bios, disabled after the bios is used
	CartMode = 3	-- 0 for ROM mode, 1 for MBC1, 2 for MBC2, 3 for MBC3
	RomBank = 1 		-- The current ROM bank stored in 0x4000 to 0x7FFF
	RamBank = 0		-- The current RAM bank
	
	-- Registers
	A = 0
	B = 0
	C = 0	
	D = 0
	E = 0
	H = 0
	L = 0x20

	PC = 0x0
	SP = 0x0
	
	-- Internal Flags
	Cf = false -- Carry
	Hf = false -- Half Carry
	Zf = false -- Zero 
	Nf = false -- Subtract
	
	-- Virtual Flags
	IME = true		-- Interupt Master Enable
	Halt = false 		-- is halt engaged (do nothing until an interupt)



	-- Cycles and other timing
	TotalCycles = 0
	Cycle = 0


	RestartGPU()
	RestartInterupts()
	RestartTimers()
	RestartJoypad()
	RestartSound()



end







function Think()

	TotalCycles = 0

	while TotalCycles < 70224 do
		Step()
	end
        os.sleep(1/20) -- prevent crashing due to not yielding

end




----------------
--Step function excutes a single operation at a time. 
----------------
function Step()

	for i = 1,1 do -- Silly JIT optomisation :C, Thanks Snoopy1611!
		if not Halt then
			Operators[Read(PC)]()
		else
			Cycle = 4
		end

		TotalCycles = TotalCycles + Cycle

		UpdateTimers()
		UpdateScreen()
		UpdateInterupts()
		UpdateSound()
	end

end

function LoadRom(RomFile)
        print(RomFile)
        handle = fs.open(RomFile, "rb")
        N = 0
        b = handle.read()
	while b ~= nil do
		ROM[N] = b
                b = handle.read()
                N = N + 1
	end

        handle.close()
end





--[[
	0000-3FFF   16KB ROM Bank 00     (in cartridge, fixed at bank 00)
	4000-7FFF   16KB ROM Bank 01..NN (in cartridge, switchable bank number)
	8000-9FFF   8KB Video RAM (VRAM) (switchable bank 0-1 in CGB Mode)
	A000-BFFF   8KB External RAM     (in cartridge, switchable bank, if any)
	C000-CFFF   4KB Work RAM Bank 0 (WRAM)
	D000-DFFF   4KB Work RAM Bank 1 (WRAM)  (switchable bank 1-7 in CGB Mode)
	E000-FDFF   Same as C000-DDFF (ECHO)    (typically not used)
	FE00-FE9F   Sprite Attribute Table (OAM)
	FEA0-FEFF   Not Usable
	FF00-FF7F   I/O Ports
	FF80-FFFE   High RAM (HRAM)
	FFFF        Interrupt Enable Register




	FF00		Joypad (R/W)
	FF01		Serial transfer data (R/W)
	FF02		Serial Transfer Control (R/W)

	FF04 		Divider Register (R/W)
	FF05		Timer counter (R/W)
	FF06		Timer Modulo (R/W)
	FF07 		Timer Control (R/W)

	FF0F 		Interrupt Flag (R/W)

	FF10		Channel 1 Sweep
	FF11		Channel 1 Sound length/Wave pattern duty (R/W)
	FF12		Channel 1 Volume Envelope (R/W)
	FF13		Channel 1 Frequency lo (Write Only)
	FF14		Channel 1 Frequency hi (R/W)

	FF16		Channel 2 Sound Length/Wave Pattern Duty (R/W)
	FF17		Channel 2 Volume Envelope (R/W)
	FF18		Channel 2 Frequency lo data (W)
	FF19		Channel 2 Frequency hi data (R/W)

	FF1A		Channel 3 Sound on/off (R/W)
	FF1B		Channel 3 Sound Length
	FF1C		Channel 3 Select output level (R/W)
	FF1D		Channel 3 Frequency's lower data (W)
	FF1E		Channel 3 Frequency's higher data (R/W)

	FF20		Channel 4 Sound Length (R/W)
	FF21		Channel 4 Volume Envelope (R/W)
	FF22		Channel 4 Polynomial Counter (R/W)
	FF23		Channel 4 Counter/consecutive; Inital (R/W)

	FF24		Channel control / ON-OFF / Volume (R/W)
	FF25		Selection of Sound output terminal (R/W)
	FF26		Sound on/off



	FF30-FF3F - Wave Pattern RAM

	FF40		LCD Control Register
	FF41		LCD Status Register
	FF42 		Scroll Y
	FF43		Scroll X
	FF44		Current Scanline Y
	FF45		LY Compare

	FF46		DMA Transfer

	FF47		Background Palette
	FF48		Sprite Palette 0
	FF49		Sprite Palette 1

	FF4A		WindowY
	FF4B		WindowX

	FF4F		Colour VRam Bank

	FF51		HDMA1 - CGB Mode Only - New DMA Source, High
	FF52		HDMA2 - CGB Mode Only - New DMA Source, Low
	FF53		HDMA3 - CGB Mode Only - New DMA Destination, High
	FF54		HDMA4 - CGB Mode Only - New DMA Destination, Low
	FF55 		HDMA5 - CGB Mode Only - New DMA Length/Mode/Start

	FF68		Colour Background Palette Index
	FF69		Colour Background Palette Data
	FF6A		Colour Sprite Palette Index
	FF6B		Colour Sprite Data



]]--





