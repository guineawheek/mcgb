OperatorsCB = {}

local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local bshr = bit.rshift
local bshl = bit.lshift

local function HL()
	return bor( bshl( H, 8 ), L )
end


--- BIT FUNCTIONS ---
local function SetBit(R1,N)
	local Bit = bshl(1, N)
	R1 = bor( R1, Bit )
	
	PC = PC + 2
	Cycle = 8
	return R1
end

function RstBit(R1,N)

	local Bit = bshl(1, N)
	R1 = band( R1, (255-Bit) )
	
	PC = PC + 2
	Cycle = 8
	return R1
end

function TstBit(R1,N)
	local Bit = bshl(1, N)
	local test = band(R1, Bit)
	
	Nf = false
	Hf = true
	Zf = test == 0
	
	PC = PC + 2
	Cycle = 8
end

function RotateLeftCarry(R1
)
	local Bit7 = band(R1, 128) == 128
	
	R1 = bor( band( bshl(R1, 1) , 0xFE) , (Bit7 and 1 or 0) )

	Cf = Bit7
	Zf = R1 == 0
	Nf = false
	Hf = false
	
	PC = PC + 2
	Cycle = 8
	
	return R1
end

function RotateRightCarry(R1)
	local Bit0 = band(R1, 1) == 1
	
	R1 = bor( band( bshr(R1, 1) , 0xFF) , (Bit0 and 128 or 0) )

	Cf = Bit0
	Zf = R1 == 0
	Nf = false
	Hf = false
	
	PC = PC + 2
	Cycle = 8
	
	return R1
end

function RotateLeft(R1)
	local Bit7 = band(R1, 128) == 128

	R1 = bor( band( bshl(R1, 1) , 0xFE) , (Cf and 1 or 0) )

	Cf = Bit7
	Zf = R1 == 0

	Nf = false
	Hf = false

	PC = PC + 2
	Cycle = 8

	return R1
	
end

function RotateRight(R1)
	local Bit0 = band(R1, 1) == 1
	
	R1 = bor( band( bshr(R1, 1) , 0xFF) , (Cf and 128 or 0) )
	
	Nf = false
	Hf = false
	
	Cf = Bit0
	Zf = R1 == 0
	
	PC = PC + 2
	Cycle = 8
	
	return R1
end

function ArithmaticShiftLeft(R1)

	local Bit7 = band( R1, 128 ) == 128

	R1 = band( bshl(R1, 1) , 0xFE ) --- 0xFE for a reason, this is arithmatic shift.

	Cf = Bit7
	Zf = R1 == 0
	Hf = false
	Nf = false

	PC = PC + 2
	Cycle = 8

	return R1
end

function ArithmaticShiftRight(R1)

	local Bit7 = band( R1, 128 ) == 128
	local Bit0 = band( R1, 1 )   == 1

	R1 = bor (band( bshr(R1, 1) , 0xFF ) , (Bit7 and 128 or 0))

	Cf = Bit0
	Zf = R1 == 0
	Hf = false
	Nf = false

	PC = PC + 2
	Cycle = 8

	return R1
end

function ShiftRight(R1)

	local Bit0 = band( R1, 1 ) == 1

	R1 = band( bshr(R1, 1) , 0xFF )

	Cf = Bit0
	Zf = R1 == 0
	Hf = false
	Nf = false

	Cycle = 8
	PC = PC + 2

	return R1
end

function Swap(R1)

	R1 = bshr( band(R1 , 0xF0) , 4) + bshl( band(R1 , 0x0F) , 4) 

	Zf = R1 == 0
	Cf = false
	Hf = false
	Nf = false

	Cycle = 8
	PC = PC + 2

	return R1
end



	


----------------------------------------------------------------------------------------------------------
-- CB CB CB -- CB CB CB -- CB CB CB -- CB CB CB -- CB CB CB -- CB CB CB -- CB CB CB -- CB CB CB --
 
--Operators[ 0xBE ] = function() ByteCmp( Read( HL() ) ); Cycle = 8 end


-- Rotate Left with Carry
OperatorsCB[ 0x00 ] = function() B = RotateLeftCarry( B ) end
OperatorsCB[ 0x01 ] = function() C = RotateLeftCarry( C ) end
OperatorsCB[ 0x02 ] = function() D = RotateLeftCarry( D ) end
OperatorsCB[ 0x03 ] = function() E = RotateLeftCarry( E ) end
OperatorsCB[ 0x04 ] = function() H = RotateLeftCarry( H ) end
OperatorsCB[ 0x05 ] = function() L = RotateLeftCarry( L ) end
OperatorsCB[ 0x06 ] = function() Write( HL() , RotateLeftCarry( Read( HL() ) ) ); Cycle = 16 end
OperatorsCB[ 0x07 ] = function() A = RotateLeftCarry( A ) end

-- Rotate Right with Carry
OperatorsCB[ 0x08 ] = function() B = RotateRightCarry( B ) end
OperatorsCB[ 0x09 ] = function() C = RotateRightCarry( C ) end
OperatorsCB[ 0x0A ] = function() D = RotateRightCarry( D ) end
OperatorsCB[ 0x0B ] = function() E = RotateRightCarry( E ) end
OperatorsCB[ 0x0C ] = function() H = RotateRightCarry( H ) end
OperatorsCB[ 0x0D ] = function() L = RotateRightCarry( L ) end
OperatorsCB[ 0x0E ] = function() Write( HL() , RotateRightCarry( Read( HL() ) ) ); Cycle = 16 end
OperatorsCB[ 0x0F ] = function() A = RotateRightCarry( A ) end

-- Rotate Left
OperatorsCB[ 0x10 ] = function() B = RotateLeft( B ) end
OperatorsCB[ 0x11 ] = function() C = RotateLeft( C ) end
OperatorsCB[ 0x12 ] = function() D = RotateLeft( D ) end
OperatorsCB[ 0x13 ] = function() E = RotateLeft( E ) end
OperatorsCB[ 0x14 ] = function() H = RotateLeft( H ) end
OperatorsCB[ 0x15 ] = function() L = RotateLeft( L ) end
OperatorsCB[ 0x16 ] = function() Write( HL() , RotateLeft( Read( HL() ) ) ); Cycle = 16 end
OperatorsCB[ 0x17 ] = function() A = RotateLeft( A ) end

-- Rotate Right
OperatorsCB[ 0x18 ] = function() B = RotateRight( B ) end
OperatorsCB[ 0x19 ] = function() C = RotateRight( C ) end
OperatorsCB[ 0x1A ] = function() D = RotateRight( D ) end
OperatorsCB[ 0x1B ] = function() E = RotateRight( E ) end
OperatorsCB[ 0x1C ] = function() H = RotateRight( H ) end
OperatorsCB[ 0x1D ] = function() L = RotateRight( L ) end
OperatorsCB[ 0x1E ] = function() Write( HL() , RotateRight( Read( HL() ) ) ); Cycle = 16 end
OperatorsCB[ 0x1F ] = function() A = RotateRight( A ) end

--Arithmatic Shift Left
OperatorsCB[ 0x20 ] = function() B = ArithmaticShiftLeft( B ) end
OperatorsCB[ 0x21 ] = function() C = ArithmaticShiftLeft( C ) end
OperatorsCB[ 0x22 ] = function() D = ArithmaticShiftLeft( D ) end
OperatorsCB[ 0x23 ] = function() E = ArithmaticShiftLeft( E ) end
OperatorsCB[ 0x24 ] = function() H = ArithmaticShiftLeft( H ) end
OperatorsCB[ 0x25 ] = function() L = ArithmaticShiftLeft( L ) end
OperatorsCB[ 0x26 ] = function() Write( HL() , ArithmaticShiftLeft( Read( HL() ) ) ); Cycle = 16 end
OperatorsCB[ 0x27 ] = function() A = ArithmaticShiftLeft( A ) end

--Arithmatic Shift Right
OperatorsCB[ 0x28 ] = function() B = ArithmaticShiftRight( B ) end
OperatorsCB[ 0x29 ] = function() C = ArithmaticShiftRight( C ) end
OperatorsCB[ 0x2A ] = function() D = ArithmaticShiftRight( D ) end
OperatorsCB[ 0x2B ] = function() E = ArithmaticShiftRight( E ) end
OperatorsCB[ 0x2C ] = function() H = ArithmaticShiftRight( H ) end
OperatorsCB[ 0x2D ] = function() L = ArithmaticShiftRight( L ) end
OperatorsCB[ 0x2E ] = function() Write( HL() , ArithmaticShiftRight( Read( HL() ) ) ); Cycle = 16 end
OperatorsCB[ 0x2F ] = function() A = ArithmaticShiftRight( A ) end

--Swap
OperatorsCB[ 0x30 ] = function() B = Swap( B ) end
OperatorsCB[ 0x31 ] = function() C = Swap( C ) end
OperatorsCB[ 0x32 ] = function() D = Swap( D ) end
OperatorsCB[ 0x33 ] = function() E = Swap( E ) end
OperatorsCB[ 0x34 ] = function() H = Swap( H ) end
OperatorsCB[ 0x35 ] = function() L = Swap( L ) end
OperatorsCB[ 0x36 ] = function() Write( HL() , Swap( Read( HL() ) ) ); Cycle = 16 end
OperatorsCB[ 0x37 ] = function() A = Swap( A ) end

--ShiftRight
OperatorsCB[ 0x38 ] = function() B = ShiftRight( B ) end
OperatorsCB[ 0x39 ] = function() C = ShiftRight( C ) end
OperatorsCB[ 0x3A ] = function() D = ShiftRight( D ) end
OperatorsCB[ 0x3B ] = function() E = ShiftRight( E ) end
OperatorsCB[ 0x3C ] = function() H = ShiftRight( H ) end
OperatorsCB[ 0x3D ] = function() L = ShiftRight( L ) end
OperatorsCB[ 0x3E ] = function() Write( HL() , ShiftRight( Read( HL() ) ) ); Cycle = 16 end
OperatorsCB[ 0x3F ] = function() A = ShiftRight( A ) end







-- TEST BIT aka BIT
OperatorsCB[ 0x40 ] = function() TstBit( B ,0 ) end
OperatorsCB[ 0x41 ] = function() TstBit( C ,0 ) end
OperatorsCB[ 0x42 ] = function() TstBit( D ,0 ) end
OperatorsCB[ 0x43 ] = function() TstBit( E ,0 ) end
OperatorsCB[ 0x44 ] = function() TstBit( H ,0 ) end
OperatorsCB[ 0x45 ] = function() TstBit( L ,0 ) end
OperatorsCB[ 0x46 ] = function() TstBit( Read( HL() ) ,0 ); Cycle = 16 end
OperatorsCB[ 0x47 ] = function() TstBit( A ,0 ) end

OperatorsCB[ 0x48 ] = function() TstBit( B ,1 ) end
OperatorsCB[ 0x49 ] = function() TstBit( C ,1 ) end
OperatorsCB[ 0x4A ] = function() TstBit( D ,1 ) end
OperatorsCB[ 0x4B ] = function() TstBit( E ,1 ) end
OperatorsCB[ 0x4C ] = function() TstBit( H ,1 ) end
OperatorsCB[ 0x4D ] = function() TstBit( L ,1 ) end
OperatorsCB[ 0x4E ] = function() TstBit( Read( HL() ) ,1 ); Cycle = 16 end
OperatorsCB[ 0x4F ] = function() TstBit( A ,1 ) end

OperatorsCB[ 0x50 ] = function() TstBit( B ,2 ) end
OperatorsCB[ 0x51 ] = function() TstBit( C ,2 ) end
OperatorsCB[ 0x52 ] = function() TstBit( D ,2 ) end
OperatorsCB[ 0x53 ] = function() TstBit( E ,2 ) end
OperatorsCB[ 0x54 ] = function() TstBit( H ,2 ) end
OperatorsCB[ 0x55 ] = function() TstBit( L ,2 ) end
OperatorsCB[ 0x56 ] = function() TstBit( Read( HL() ) ,2 ); Cycle = 16 end
OperatorsCB[ 0x57 ] = function() TstBit( A ,2 ) end

OperatorsCB[ 0x58 ] = function() TstBit( B ,3 ) end
OperatorsCB[ 0x59 ] = function() TstBit( C ,3 ) end
OperatorsCB[ 0x5A ] = function() TstBit( D ,3 ) end
OperatorsCB[ 0x5B ] = function() TstBit( E ,3 ) end
OperatorsCB[ 0x5C ] = function() TstBit( H ,3 ) end
OperatorsCB[ 0x5D ] = function() TstBit( L ,3 ) end
OperatorsCB[ 0x5E ] = function() TstBit( Read( HL() ) ,3 ); Cycle = 16 end
OperatorsCB[ 0x5F ] = function() TstBit( A ,3 ) end

OperatorsCB[ 0x60 ] = function() TstBit( B ,4 ) end
OperatorsCB[ 0x61 ] = function() TstBit( C ,4 ) end
OperatorsCB[ 0x62 ] = function() TstBit( D ,4 ) end
OperatorsCB[ 0x63 ] = function() TstBit( E ,4 ) end
OperatorsCB[ 0x64 ] = function() TstBit( H ,4 ) end
OperatorsCB[ 0x65 ] = function() TstBit( L ,4 ) end
OperatorsCB[ 0x66 ] = function() TstBit( Read( HL() ) ,4 ); Cycle = 16 end
OperatorsCB[ 0x67 ] = function() TstBit( A ,4 ) end

OperatorsCB[ 0x68 ] = function() TstBit( B ,5 ) end
OperatorsCB[ 0x69 ] = function() TstBit( C ,5 ) end
OperatorsCB[ 0x6A ] = function() TstBit( D ,5 ) end
OperatorsCB[ 0x6B ] = function() TstBit( E ,5 ) end
OperatorsCB[ 0x6C ] = function() TstBit( H ,5 ) end
OperatorsCB[ 0x6D ] = function() TstBit( L ,5 ) end
OperatorsCB[ 0x6E ] = function() TstBit( Read( HL() ) ,5 ); Cycle = 16 end
OperatorsCB[ 0x6F ] = function() TstBit( A ,5 ) end

OperatorsCB[ 0x70 ] = function() TstBit( B ,6 ) end
OperatorsCB[ 0x71 ] = function() TstBit( C ,6 ) end
OperatorsCB[ 0x72 ] = function() TstBit( D ,6 ) end
OperatorsCB[ 0x73 ] = function() TstBit( E ,6 ) end
OperatorsCB[ 0x74 ] = function() TstBit( H ,6 ) end
OperatorsCB[ 0x75 ] = function() TstBit( L ,6 ) end
OperatorsCB[ 0x76 ] = function() TstBit( Read( HL() ) ,6 ); Cycle = 16 end
OperatorsCB[ 0x77 ] = function() TstBit( A ,6 ) end

OperatorsCB[ 0x78 ] = function() TstBit( B ,7 ) end
OperatorsCB[ 0x79 ] = function() TstBit( C ,7 ) end
OperatorsCB[ 0x7A ] = function() TstBit( D ,7 ) end
OperatorsCB[ 0x7B ] = function() TstBit( E ,7 ) end
OperatorsCB[ 0x7C ] = function() TstBit( H ,7 ) end
OperatorsCB[ 0x7D ] = function() TstBit( L ,7 ) end
OperatorsCB[ 0x7E ] = function() TstBit( Read( HL() ) ,7 ); Cycle = 16 end
OperatorsCB[ 0x7F ] = function() TstBit( A ,7 ) end


------ RESET

OperatorsCB[ 0x80 ] = function() B = RstBit( B ,0 ) end
OperatorsCB[ 0x81 ] = function() C = RstBit( C ,0 ) end
OperatorsCB[ 0x82 ] = function() D = RstBit( D ,0 ) end
OperatorsCB[ 0x83 ] = function() E = RstBit( E ,0 ) end
OperatorsCB[ 0x84 ] = function() H = RstBit( H ,0 ) end
OperatorsCB[ 0x85 ] = function() L = RstBit( L ,0 ) end
OperatorsCB[ 0x86 ] = function() Write( HL() , RstBit( Read( HL() )  ,0 )); Cycle = 16 end
OperatorsCB[ 0x87 ] = function() A = RstBit( A ,0 ) end

OperatorsCB[ 0x88 ] = function() B = RstBit( B ,1 ) end
OperatorsCB[ 0x89 ] = function() C = RstBit( C ,1 ) end
OperatorsCB[ 0x8A ] = function() D = RstBit( D ,1 ) end
OperatorsCB[ 0x8B ] = function() E = RstBit( E ,1 ) end
OperatorsCB[ 0x8C ] = function() H = RstBit( H ,1 ) end
OperatorsCB[ 0x8D ] = function() L = RstBit( L ,1 ) end
OperatorsCB[ 0x8E ] = function() Write( HL() , RstBit( Read( HL() ) ,1 )); Cycle = 16 end
OperatorsCB[ 0x8F ] = function() A = RstBit( A ,1 ) end

OperatorsCB[ 0x90 ] = function() B = RstBit( B ,2 ) end
OperatorsCB[ 0x91 ] = function() C = RstBit( C ,2 ) end
OperatorsCB[ 0x92 ] = function() D = RstBit( D ,2 ) end
OperatorsCB[ 0x93 ] = function() E = RstBit( E ,2 ) end
OperatorsCB[ 0x94 ] = function() H = RstBit( H ,2 ) end
OperatorsCB[ 0x95 ] = function() L = RstBit( L ,2 ) end
OperatorsCB[ 0x96 ] = function() Write( HL() , RstBit( Read( HL() ) ,2 )); Cycle = 16 end
OperatorsCB[ 0x97 ] = function() A = RstBit( A ,2 ) end

OperatorsCB[ 0x98 ] = function() B = RstBit( B ,3 ) end
OperatorsCB[ 0x99 ] = function() C = RstBit( C ,3 ) end
OperatorsCB[ 0x9A ] = function() D = RstBit( D ,3 ) end
OperatorsCB[ 0x9B ] = function() E = RstBit( E ,3 ) end
OperatorsCB[ 0x9C ] = function() H = RstBit( H ,3 ) end
OperatorsCB[ 0x9D ] = function() L = RstBit( L ,3 ) end
OperatorsCB[ 0x9E ] = function() Write( HL() , RstBit( Read( HL() ) ,3 )); Cycle = 16 end
OperatorsCB[ 0x9F ] = function() A = RstBit( A ,3 ) end

OperatorsCB[ 0xA0 ] = function() B = RstBit( B ,4 ) end
OperatorsCB[ 0xA1 ] = function() C = RstBit( C ,4 ) end
OperatorsCB[ 0xA2 ] = function() D = RstBit( D ,4 ) end
OperatorsCB[ 0xA3 ] = function() E = RstBit( E ,4 ) end
OperatorsCB[ 0xA4 ] = function() H = RstBit( H ,4 ) end
OperatorsCB[ 0xA5 ] = function() L = RstBit( L ,4 ) end
OperatorsCB[ 0xA6 ] = function() Write( HL() , RstBit( Read( HL() ) ,4 )); Cycle = 16 end
OperatorsCB[ 0xA7 ] = function() A = RstBit( A ,4 ) end

OperatorsCB[ 0xA8 ] = function() B = RstBit( B ,5 ) end
OperatorsCB[ 0xA9 ] = function() C = RstBit( C ,5 ) end
OperatorsCB[ 0xAA ] = function() D = RstBit( D ,5 ) end
OperatorsCB[ 0xAB ] = function() E = RstBit( E ,5 ) end
OperatorsCB[ 0xAC ] = function() H = RstBit( H ,5 ) end
OperatorsCB[ 0xAD ] = function() L = RstBit( L ,5 ) end
OperatorsCB[ 0xAE ] = function() Write( HL() , RstBit( Read( HL() ) ,5 )); Cycle = 16 end
OperatorsCB[ 0xAF ] = function() A = RstBit( A ,5 ) end

OperatorsCB[ 0xB0 ] = function() B = RstBit( B ,6 ) end
OperatorsCB[ 0xB1 ] = function() C = RstBit( C ,6 ) end
OperatorsCB[ 0xB2 ] = function() D = RstBit( D ,6 ) end
OperatorsCB[ 0xB3 ] = function() E = RstBit( E ,6 ) end
OperatorsCB[ 0xB4 ] = function() H = RstBit( H ,6 ) end
OperatorsCB[ 0xB5 ] = function() L = RstBit( L ,6 ) end
OperatorsCB[ 0xB6 ] = function() Write( HL() , RstBit( Read( HL() ) ,6 )); Cycle = 16 end
OperatorsCB[ 0xB7 ] = function() A = RstBit( A ,6 ) end

OperatorsCB[ 0xB8 ] = function() B = RstBit( B ,7 ) end
OperatorsCB[ 0xB9 ] = function() C = RstBit( C ,7 ) end
OperatorsCB[ 0xBA ] = function() D = RstBit( D ,7 ) end
OperatorsCB[ 0xBB ] = function() E = RstBit( E ,7 ) end
OperatorsCB[ 0xBC ] = function() H = RstBit( H ,7 ) end
OperatorsCB[ 0xBD ] = function() L = RstBit( L ,7 ) end
OperatorsCB[ 0xBE ] = function() Write( HL() , RstBit( Read( HL() ) ,7 )); Cycle = 16 end
OperatorsCB[ 0xBF ] = function() A = RstBit( A ,7 ) end


--- SET BIT



OperatorsCB[ 0xC0 ] = function() B = SetBit( B ,0 ) end
OperatorsCB[ 0xC1 ] = function() C = SetBit( C ,0 ) end
OperatorsCB[ 0xC2 ] = function() D = SetBit( D ,0 ) end
OperatorsCB[ 0xC3 ] = function() E = SetBit( E ,0 ) end
OperatorsCB[ 0xC4 ] = function() H = SetBit( H ,0 ) end
OperatorsCB[ 0xC5 ] = function() L = SetBit( L ,0 ) end
OperatorsCB[ 0xC6 ] = function() Write( HL() , SetBit( Read( HL() ) ,0 )); Cycle = 16 end
OperatorsCB[ 0xC7 ] = function() A = SetBit( A ,0 ) end

OperatorsCB[ 0xC8 ] = function() B = SetBit( B ,1 ) end
OperatorsCB[ 0xC9 ] = function() C = SetBit( C ,1 ) end
OperatorsCB[ 0xCA ] = function() D = SetBit( D ,1 ) end
OperatorsCB[ 0xCB ] = function() E = SetBit( E ,1 ) end
OperatorsCB[ 0xCC ] = function() H = SetBit( H ,1 ) end
OperatorsCB[ 0xCD ] = function() L = SetBit( L ,1 ) end
OperatorsCB[ 0xCE ] = function() Write( HL() , SetBit( Read( HL() ) ,1 )); Cycle = 16 end
OperatorsCB[ 0xCF ] = function() A = SetBit( A ,1 ) end

OperatorsCB[ 0xD0 ] = function() B = SetBit( B ,2 ) end
OperatorsCB[ 0xD1 ] = function() C = SetBit( C ,2 ) end
OperatorsCB[ 0xD2 ] = function() D = SetBit( D ,2 ) end
OperatorsCB[ 0xD3 ] = function() E = SetBit( E ,2 ) end
OperatorsCB[ 0xD4 ] = function() H = SetBit( H ,2 ) end
OperatorsCB[ 0xD5 ] = function() L = SetBit( L ,2 ) end
OperatorsCB[ 0xD6 ] = function() Write( HL() , SetBit( Read( HL() ) ,2 )); Cycle = 16 end
OperatorsCB[ 0xD7 ] = function() A = SetBit( A ,2 ) end

OperatorsCB[ 0xD8 ] = function() B = SetBit( B ,3 ) end
OperatorsCB[ 0xD9 ] = function() C = SetBit( C ,3 ) end
OperatorsCB[ 0xDA ] = function() D = SetBit( D ,3 ) end
OperatorsCB[ 0xDB ] = function() E = SetBit( E ,3 ) end
OperatorsCB[ 0xDC ] = function() H = SetBit( H ,3 ) end
OperatorsCB[ 0xDD ] = function() L = SetBit( L ,3 ) end
OperatorsCB[ 0xDE ] = function() Write( HL() , SetBit( Read( HL() ) ,3 )); Cycle = 16 end
OperatorsCB[ 0xDF ] = function() A = SetBit( A ,3 ) end

OperatorsCB[ 0xE0 ] = function() B = SetBit( B ,4 ) end
OperatorsCB[ 0xE1 ] = function() C = SetBit( C ,4 ) end
OperatorsCB[ 0xE2 ] = function() D = SetBit( D ,4 ) end
OperatorsCB[ 0xE3 ] = function() E = SetBit( E ,4 ) end
OperatorsCB[ 0xE4 ] = function() H = SetBit( H ,4 ) end
OperatorsCB[ 0xE5 ] = function() L = SetBit( L ,4 ) end
OperatorsCB[ 0xE6 ] = function() Write( HL() , SetBit( Read( HL() ) ,4 )); Cycle = 16 end
OperatorsCB[ 0xE7 ] = function() A = SetBit( A ,4 ) end

OperatorsCB[ 0xE8 ] = function() B = SetBit( B ,5 ) end
OperatorsCB[ 0xE9 ] = function() C = SetBit( C ,5 ) end
OperatorsCB[ 0xEA ] = function() D = SetBit( D ,5 ) end
OperatorsCB[ 0xEB ] = function() E = SetBit( E ,5 ) end
OperatorsCB[ 0xEC ] = function() H = SetBit( H ,5 ) end
OperatorsCB[ 0xED ] = function() L = SetBit( L ,5 ) end
OperatorsCB[ 0xEE ] = function() Write( HL() , SetBit( Read( HL() ) ,5 )); Cycle = 16 end
OperatorsCB[ 0xEF ] = function() A = SetBit( A ,5 ) end

OperatorsCB[ 0xF0 ] = function() B = SetBit( B ,6 ) end
OperatorsCB[ 0xF1 ] = function() C = SetBit( C ,6 ) end
OperatorsCB[ 0xF2 ] = function() D = SetBit( D ,6 ) end
OperatorsCB[ 0xF3 ] = function() E = SetBit( E ,6 ) end
OperatorsCB[ 0xF4 ] = function() H = SetBit( H ,6 ) end
OperatorsCB[ 0xF5 ] = function() L = SetBit( L ,6 ) end
OperatorsCB[ 0xF6 ] = function() Write( HL() , SetBit( Read( HL() ) ,6 )); Cycle = 16 end
OperatorsCB[ 0xF7 ] = function() A = SetBit( A ,6 ) end

OperatorsCB[ 0xF8 ] = function() B = SetBit( B ,7 ) end
OperatorsCB[ 0xF9 ] = function() C = SetBit( C ,7 ) end
OperatorsCB[ 0xFA ] = function() D = SetBit( D ,7 ) end
OperatorsCB[ 0xFB ] = function() E = SetBit( E ,7 ) end
OperatorsCB[ 0xFC ] = function() H = SetBit( H ,7 ) end
OperatorsCB[ 0xFD ] = function() L = SetBit( L ,7 ) end
OperatorsCB[ 0xFE ] = function() Write( HL() , SetBit( Read( HL() ) ,7 )); Cycle = 16 end
OperatorsCB[ 0xFF ] = function() A = SetBit( A ,7 ) end






