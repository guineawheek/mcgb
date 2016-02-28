local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local bshr = bit.rshift
local bshl = bit.lshift

---------------
-- Interupts --
---------------

function RestartInterupts()

	-- Interupt Hardware Registers
	IE = 0 -- Interupt Enable Register: Bit0 = VBlank, Bit1 = LCD, Bit2 = Timer, Bit4 = Joypad
	IF = 0 -- Interupt Request Register

end

-- Interupt Enable
MRead[ 0xFFFF ] = function(  Addr ) return IE end
MWrite[ 0xFFFF ] = function(  Addr, Data ) IE = band(Data , 0x1F) end

-- Interupt Request
MRead[ 0xFF0F ] = function(  Addr )  return IF end
MWrite[ 0xFF0F ] = function(  Addr, Data ) IF = band(Data , 0x1F) end


function UpdateInterupts()

	if IME and IE > 0 and IF > 0 then
		if ( band( IE, 1 ) == 1) and ( band( IF, 1 ) == 1) then --VBlank interrupt
			
			IME = false
			Halt = false

			IF = band( IF, (255 - 1) )

			SP = SP - 2
			Write(SP + 1, bshr( band( PC , 0xFF00 ), 8 ) )
			Write(SP    , band( PC , 0xFF )       )

			PC = 0x40

		elseif ( band( IE, 2 ) == 2) and ( band( IF, 2 ) == 2) then -- LCD Interrupt

			IME = false
			Halt = false

			IF = band( IF, (255 - 2) )

			SP = SP - 2
			Write(SP + 1, bshr( band( PC , 0xFF00), 8 ) )
			Write(SP    , band( PC , 0xFF )       )

			PC = 0x48

		elseif ( band( IE, 4 ) == 4) and ( band( IF, 4 ) == 4) then -- TImer Interrupt

			IME = false
			Halt = false

			IF = band( IF, (255 - 4) )

			SP = SP - 2
			Write(SP + 1, bshr( band( PC , 0xFF00), 8 ) )
			Write(SP    , band( PC , 0xFF )       )

			PC = 0x50

		elseif ( band( IE, 8 ) == 8) and ( band( IF, 8 ) == 8) then

			IME = false
			Halt = false

			IF = band( IF, (255 - 8) )

			SP = SP - 2
			Write(SP + 1, bshr( band( PC , 0xFF00), 8 ) )
			Write(SP    , band( PC , 0xFF )       )

			PC = 0x58

		elseif ( band( IE, 16 ) == 16) and ( band( IF, 16 ) == 16) then -- Joy Interrupt

			IME = false
			Halt = false

			IF = band( IF, (255 - 16) )

			SP = SP - 2
			Write(SP + 1, bshr( band( PC , 0xFF00), 8 ) )
			Write(SP    , band( PC , 0xFF )       )

			PC = 0x60

		end
	end

end




