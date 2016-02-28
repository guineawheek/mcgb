Operators = {}

local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local bshr = bit.rshift
local bshl = bit.lshift

local function HL()
	return bor( bshl( H, 8 ), L )
end




--- 16 bit arithmatic/logic functions ---
local function WordInc(R1, R2)
	R1 = band( (R1+1) , 0xFF )
	if R1 == 0 then R2 = band( (R2+1) , 0xFF ) end
	
	PC = PC + 1
	Cycle = 8 
	
	return R1, R2
end

local function WordDec(R1, R2)
	R1 = band( (R1-1 ), 0xFF )
	if R1 == 0xFF then R2 = band( (R2-1) , 0xFF ) end
	
	PC = PC + 1
	Cycle = 8
	
	return R1, R2
end

local function WordAdd(R1, R2)

	Hf = (   band( H , 0xF ) + band( R1 , 0xF ) + (((L + R2) > 0xFF) and 1 or 0)) > 0xF

	H = H + R1
	L = L + R2

	if L > 0xFF then
		H = H + 1
		L = band( L , 0xFF )
	end
	
	if H > 0xFF then
		H = band( H , 0xFF )
		Cf = true
	else
		Cf = false
	end
	
	Nf = false

	PC = PC + 1
	Cycle = 8
end

--- Jumps/Calls, general Flow control--

local function JumpSign(Val)
	if Val then
		local D8 = Read(PC+1)
		
		PC = PC + ( band(D8, 127) -  band(D8, 128)) + 2

		PC = band( PC , 0xFFFF )

		Cycle = 12
	else
		PC = PC + 2
		Cycle = 8
	end
end

local function Jump(Val)
	if Val then
		local A16 = bor( bshl(Read(PC+2),8) , Read(PC+1) )
		
		PC = A16
		Cycle = 16
	else
		PC = PC + 3
		Cycle = 12
	end
end

local function Call(Val)
	if Val then
		local A16 = bor( bshl(Read(PC+2),8) , Read(PC+1) )
		
		SP = SP - 2
		Write(SP + 1, bshr( band((PC+3), 0xFF00) , 8 ) )
		Write(SP    , band( (PC+3) , 0xFF )      )

		PC = A16
		Cycle = 24
	else
		PC = PC + 3
		Cycle = 12
	end
end

local function Return(Val)
	if Val then

		PC = bor( bshl(Read( SP + 1 ),8) , Read( SP ) )
		SP = SP + 2
		
		Cycle = 20
	else
		PC = PC + 1
		Cycle = 8
	end
end
		
local function ResetPC(Addr)
	SP = SP - 2
	Write(SP + 1, bshr( band((PC+1), 0xFF00) , 8 ) )
	Write(SP    , band( (PC+1) , 0xFF )      )
	
	PC = Addr
	Cycle = 16
end


--- Stack Operations --- 

local function StackPush( R1, R2 )
	SP = SP - 2
	Write( SP  + 1, R1 )
	Write( SP, R2 )
	
	PC = PC + 1
	Cycle = 16
end

local function StackPop()	
	local R1 = Read( SP + 1 )
	local R2 = Read( SP )
	SP = SP + 2
	
	PC = PC + 1
	Cycle = 12
	return R1, R2
end

-- ARITHMATIC AND LOGIC

local function ByteAdd(R1)
	
	Hf = ( band(A , 0xF) + band(R1 , 0xF)) > 0xF
	
	A = A + R1
	Cf = A > 0xFF
	
	A = band(A , 0xFF)
	
	Nf = false
	Zf = A == 0
	
	PC = PC + 1
	Cycle = 4
end

local function ByteAdc(R1)

	Hf = ( band(A , 0xF) + band(R1 , 0x0F) + (Cf and 1 or 0)) > 0xF
	
	A = A + R1 + (Cf and 1 or 0)
	Cf = A > 0xFF
	
	A = band(A , 0xFF)
	
	Nf = false
	Zf = A == 0
	
	PC = PC + 1
	Cycle = 4
end

local function ByteSub(R1)
	Hf = band(R1 , 0xF) > band(A , 0xF) 
	Cf = R1 > A
	
	A = band( ( A - R1 ) , 0xFF )
	
	Zf = A == 0
	Nf = true
	
	PC = PC + 1
	Cycle = 4
end


local function ByteSbc(R1)

	local SubVal = (R1 + (Cf and 1 or 0))

	Hf = ( band(R1 , 0xF) + (Cf and 1 or 0) ) > band(A , 0xF)
	Cf = SubVal > A
	
	A = band( ( A - SubVal ) , 0xFF)
	
	Zf = A == 0
	Nf = true
	
	PC = PC + 1
	Cycle = 4
end


local function ByteAnd(R1)
	A = band( A, R1 )
	
	Zf = A == 0
	Nf = false
	Hf = true
	Cf = false
	
	PC = PC + 1
	Cycle = 4
end

local function ByteXor(R1)
	A = bxor(A, R1)
	
	Zf = A == 0
	Nf = false
	Hf = false
	Cf = false
	
	PC = PC + 1
	cycle = 4
end

local function ByteOr(R1)
	A = bor(A, R1)
	
	Zf = A == 0
	Nf = false
	Hf = false
	Cf = false
	
	PC = PC + 1
	cycle = 4
end

local function ByteCmp(R1)


	Hf = band( R1 , 0xF ) > band( A , 0xF )
	Cf = R1 > A
	
	Zf = band((A - R1) , 0xFF ) == 0
	Nf = true
	
	PC = PC + 1
	cycle = 4
end


-- Byte Inc and Dec
local function ByteInc(R1)
	Hf = band(R1 , 0xF) == 0xF
	
	R1 = band( (R1+1) , 0xFF )
	
	Nf = false
	Zf = R1 == 0

	PC = PC + 1

	cycle = 4
	
	return R1
end

local function ByteDec(R1)
	Hf = ( band((R1 - 1) , 0xF ) > band(R1 , 0xF))
	
	R1 = band( (R1-1) , 0xFF )
	
	Nf = true
	Zf = R1 == 0
	
	PC = PC + 1
	cycle = 4
	
	return R1
end















--- MISC/CONTROL INSTRUCTIONS ---

-- NOP
Operators[ 0x00 ] =  function()	
	PC = PC + 1
	Cycle = 4
end

-- STOP
Operators[ 0x10 ] =  function()
	Halt = true

	PC = PC + 2
	Cycle = 4
	-- turns off the gameboy?
end

-- HALT
Operators[ 0x76 ] = function()
	if IME then
		Halt = true
	end
	
	PC = PC + 1
	Cycle = 4
end

-- Disable Interupts
Operators[ 0xF3 ] = function()
	IME = false
	
	PC = PC + 1
	Cycle = 4
end

--Enable Interupts
Operators[ 0xFB ] = function()
	IME = true
	
	PC = PC + 1
	Cycle = 4
end


-- CB opcodes
Operators[ 0xCB ] = function()
	OperatorsCB[Read(PC + 1) ]()
end



--- JUMPS/CALLS/RETURNS/FLOW CONTROL GENERAL --- 


-- Signed Jumps
Operators[ 0x18 ] =  function() JumpSign( true ) end
Operators[ 0x20 ] =  function() JumpSign( not Zf ) end
Operators[ 0x30 ] =  function() JumpSign( not Cf ) end
Operators[ 0x28 ] =  function() JumpSign( Zf ) end
Operators[ 0x38 ] =  function() JumpSign( Cf ) end

-- Absolute Jumps
Operators[ 0xC3 ] =  function() Jump( true ) end
Operators[ 0xC2 ] =  function() Jump( not Zf ) end
Operators[ 0xD2 ] =  function() Jump( not Cf ) end
Operators[ 0xCA ] =  function() Jump( Zf ) end
Operators[ 0xDA ] =  function() Jump( Cf ) end

-- Call Subroutine
Operators[ 0xCD ] =  function() Call( true ) end
Operators[ 0xC4 ] =  function() Call( not Zf ) end
Operators[ 0xD4 ] =  function() Call( not Cf ) end
Operators[ 0xCC ] =  function() Call( Zf ) end
Operators[ 0xDC ] =  function() Call( Cf ) end

-- Return from Subroutine
Operators[ 0xC9 ] = function() Return( true ); Cycle = 16 end
Operators[ 0xD9 ] = function() IME = true; Return( true ); Cycle = 16 end
Operators[ 0xC0 ] = function() Return( not Zf ) end
Operators[ 0xD0 ] = function() Return( not Cf ) end
Operators[ 0xC8 ] = function() Return( Zf ) end
Operators[ 0xD8 ] = function() Return( Cf ) end

-- ResetPC
Operators[ 0xC7 ] = function() ResetPC( 0x00 ) end
Operators[ 0xD7 ] = function() ResetPC( 0x10 ) end
Operators[ 0xE7 ] = function() ResetPC( 0x20 ) end
Operators[ 0xF7 ] = function() ResetPC( 0x30 ) end

Operators[ 0xCF ] = function() ResetPC( 0x08 ) end
Operators[ 0xDF ] = function() ResetPC( 0x18 ) end
Operators[ 0xEF ] = function() ResetPC( 0x28 ) end
Operators[ 0xFF ] = function() ResetPC( 0x38 ) end

-- Jump to address in HL

Operators[ 0xE9 ] = function()
	PC = bor( bshl( H, 8 ), L )
	
	Cycle = 4
end

--- 16 BIT ARITHMATIC & LOGIC ---

-- Incrimnt 16 Bit Register
Operators[ 0x03 ] =  function() C,B = WordInc(C,B) end
Operators[ 0x13 ] =  function() E,D = WordInc(E,D) end
Operators[ 0x23 ] =  function() L,H = WordInc(L,H) end
Operators[ 0x33 ] =  function() SP = SP + 1; PC = PC + 1; Cycle = 8 end

-- Decriment 16 Bit Register
Operators[ 0x0B ] =  function() C,B = WordDec(C,B) end
Operators[ 0x1B ] =  function() E,D = WordDec(E,D) end
Operators[ 0x2B ] =  function() L,H = WordDec(L,H) end
Operators[ 0x3B ] =  function() SP = SP - 1; PC = PC + 1; Cycle = 8 end

--Add 16 Bit Register to HL
Operators[ 0x09 ] =  function() WordAdd(B, C) end
Operators[ 0x19 ] =  function() WordAdd(D, E) end
Operators[ 0x29 ] =  function() WordAdd(H, L) end
Operators[ 0x39 ] =  function() WordAdd( band( bshr(SP,8) , 0xFF) , band(SP , 0xFF) ) end -- Split the SP up first

-- Add signed immediate to SP
Operators[ 0xE8 ] =  function()
	local D8 = Read(PC+1)
	local S8 = band(D8, 127) - band(D8, 128)-- This turns a regular 8 bit unsigned number into a signed number. 
	local tSP = SP + S8

	if S8 >= 0 then
		Cf = ( band(SP , 0xFF) + S8 ) > 0xFF
		Hf = ( band(SP , 0xF) + band( S8 , 0xF ) ) > 0xF
	else
		Cf = band(tSP , 0xFF) <= band(SP , 0xFF)
		Hf = band(tSP , 0xF)  <= band(SP , 0xF)
	end

	SP = band( tSP , 0xFFFF )

	Zf = false
	Nf = false

	PC = PC + 2
	Cycle = 16
end



-- Regular 8 bit loads

-- Load into B
Operators[ 0x40 ] =  function() B = B; Cycle = 4; PC = PC + 1 end
Operators[ 0x41 ] =  function() B = C; Cycle = 4; PC = PC + 1 end
Operators[ 0x42 ] =  function() B = D; Cycle = 4; PC = PC + 1 end
Operators[ 0x43 ] =  function() B = E; Cycle = 4; PC = PC + 1 end
Operators[ 0x44 ] =  function() B = H; Cycle = 4; PC = PC + 1 end
Operators[ 0x45 ] =  function() B = L; Cycle = 4; PC = PC + 1 end
Operators[ 0x46 ] =  function() B = Read( bor( bshl( H, 8 ), L ) ); Cycle = 8; PC = PC + 1 end
Operators[ 0x47 ] =  function() B = A; Cycle = 4; PC = PC + 1 end

-- Load into C
Operators[ 0x48 ] =  function() C = B; Cycle = 4; PC = PC + 1 end
Operators[ 0x49 ] =  function() C = C; Cycle = 4; PC = PC + 1 end
Operators[ 0x4A ] =  function() C = D; Cycle = 4; PC = PC + 1 end
Operators[ 0x4B ] =  function() C = E; Cycle = 4; PC = PC + 1 end
Operators[ 0x4C ] =  function() C = H; Cycle = 4; PC = PC + 1 end
Operators[ 0x4D ] =  function() C = L; Cycle = 4; PC = PC + 1 end
Operators[ 0x4E ] =  function() C = Read( bor( bshl( H, 8 ), L ) ); Cycle = 8; PC = PC + 1 end
Operators[ 0x4F ] =  function() C = A; Cycle = 4; PC = PC + 1 end

-- Load into D
Operators[ 0x50 ] =  function() D = B; Cycle = 4; PC = PC + 1 end
Operators[ 0x51 ] =  function() D = C; Cycle = 4; PC = PC + 1 end
Operators[ 0x52 ] =  function() D = D; Cycle = 4; PC = PC + 1 end
Operators[ 0x53 ] =  function() D = E; Cycle = 4; PC = PC + 1 end
Operators[ 0x54 ] =  function() D = H; Cycle = 4; PC = PC + 1 end
Operators[ 0x55 ] =  function() D = L; Cycle = 4; PC = PC + 1 end
Operators[ 0x56 ] =  function() D = Read( bor( bshl( H, 8 ), L ) ); Cycle = 8; PC = PC + 1 end
Operators[ 0x57 ] =  function() D = A; Cycle = 4; PC = PC + 1 end

-- Load into E
Operators[ 0x58 ] =  function() E = B; Cycle = 4; PC = PC + 1 end
Operators[ 0x59 ] =  function() E = C; Cycle = 4; PC = PC + 1 end
Operators[ 0x5A ] =  function() E = D; Cycle = 4; PC = PC + 1 end
Operators[ 0x5B ] =  function() E = E; Cycle = 4; PC = PC + 1 end
Operators[ 0x5C ] =  function() E = H; Cycle = 4; PC = PC + 1 end
Operators[ 0x5D ] =  function() E = L; Cycle = 4; PC = PC + 1 end
Operators[ 0x5E ] =  function() E = Read( bor( bshl( H, 8 ), L ) ); Cycle = 8; PC = PC + 1 end
Operators[ 0x5F ] =  function() E = A; Cycle = 4; PC = PC + 1 end

-- Load into H
Operators[ 0x60 ] =  function() H = B; Cycle = 4; PC = PC + 1 end
Operators[ 0x61 ] =  function() H = C; Cycle = 4; PC = PC + 1 end
Operators[ 0x62 ] =  function() H = D; Cycle = 4; PC = PC + 1 end
Operators[ 0x63 ] =  function() H = E; Cycle = 4; PC = PC + 1 end
Operators[ 0x64 ] =  function() H = H; Cycle = 4; PC = PC + 1 end
Operators[ 0x65 ] =  function() H = L; Cycle = 4; PC = PC + 1 end
Operators[ 0x66 ] =  function() H = Read( bor( bshl( H, 8 ), L ) ); Cycle = 8; PC = PC + 1 end
Operators[ 0x67 ] =  function() H = A; Cycle = 4; PC = PC + 1 end

-- Load into L
Operators[ 0x68 ] =  function() L = B; Cycle = 4; PC = PC + 1 end
Operators[ 0x69 ] =  function() L = C; Cycle = 4; PC = PC + 1 end
Operators[ 0x6A ] =  function() L = D; Cycle = 4; PC = PC + 1 end
Operators[ 0x6B ] =  function() L = E; Cycle = 4; PC = PC + 1 end
Operators[ 0x6C ] =  function() L = H; Cycle = 4; PC = PC + 1 end
Operators[ 0x6D ] =  function() L = L; Cycle = 4; PC = PC + 1 end
Operators[ 0x6E ] =  function() L = Read( bor( bshl( H, 8 ), L ) ); Cycle = 8; PC = PC + 1 end
Operators[ 0x6F ] =  function() L = A; Cycle = 4; PC = PC + 1 end

-- Load into (HL)
Operators[ 0x70 ] =  function() Write( bor( bshl( H, 8 ), L ), B); Cycle = 8; PC = PC + 1 end
Operators[ 0x71 ] =  function() Write( bor( bshl( H, 8 ), L ), C); Cycle = 8; PC = PC + 1 end
Operators[ 0x72 ] =  function() Write( bor( bshl( H, 8 ), L ), D); Cycle = 8; PC = PC + 1 end
Operators[ 0x73 ] =  function() Write( bor( bshl( H, 8 ), L ), E); Cycle = 8; PC = PC + 1 end
Operators[ 0x74 ] =  function() Write( bor( bshl( H, 8 ), L ), H); Cycle = 8; PC = PC + 1 end
Operators[ 0x75 ] =  function() Write( bor( bshl( H, 8 ), L ), L); Cycle = 8; PC = PC + 1 end

Operators[ 0x77 ] =  function() Write( bor( bshl( H, 8 ), L ), A); Cycle = 8; PC = PC + 1 end

-- Load into A
Operators[ 0x78 ] =  function() A = B; Cycle = 4; PC = PC + 1 end
Operators[ 0x79 ] =  function() A = C; Cycle = 4; PC = PC + 1 end
Operators[ 0x7A ] =  function() A = D; Cycle = 4; PC = PC + 1 end
Operators[ 0x7B ] =  function() A = E; Cycle = 4; PC = PC + 1 end
Operators[ 0x7C ] =  function() A = H; Cycle = 4; PC = PC + 1 end
Operators[ 0x7D ] =  function() A = L; Cycle = 4; PC = PC + 1 end
Operators[ 0x7E ] =  function() A = Read( bor( bshl( H, 8 ), L )); Cycle = 8; PC = PC + 1 end
Operators[ 0x7F ] =  function() A = A; Cycle = 4; PC = PC + 1 end


-- Load immediate data into register
Operators[ 0x06 ] =  function() B = Read(PC+1); Cycle = 8; PC = PC + 2 end
Operators[ 0x0E ] =  function() C = Read(PC+1); Cycle = 8; PC = PC + 2 end
Operators[ 0x16 ] =  function() D = Read(PC+1); Cycle = 8; PC = PC + 2 end
Operators[ 0x1E ] =  function() E = Read(PC+1); Cycle = 8; PC = PC + 2 end
Operators[ 0x26 ] =  function() H = Read(PC+1); Cycle = 8; PC = PC + 2 end
Operators[ 0x2E ] =  function() L = Read(PC+1); Cycle = 8; PC = PC + 2 end
Operators[ 0x36 ] =  function() Write( bor( bshl( H, 8 ), L ), Read(PC+1)); Cycle = 12; PC = PC + 2 end
Operators[ 0x3E ] =  function() A = Read(PC+1); Cycle = 8; PC = PC + 2 end

-- The wierd 8 bit loads
-- Load A into 0xFF00 + immediate data or visa-versa
Operators[ 0xE0 ] = function() Write( 0xFF00 + Read(PC+1), A); Cycle = 12; PC = PC + 2 end
Operators[ 0xF0 ] = function() A = Read( 0xFF00 + Read(PC+1)); Cycle = 12; PC = PC + 2 end

-- Load A into 0xFF + C or visa-versa. 
Operators[ 0xE2 ] = function() Write( 0xFF00 + C, A ); Cycle = 8; PC = PC + 1 end
Operators[ 0xF2 ] = function() A = Read( 0xFF00 + C ); Cycle = 8; PC = PC + 1 end

-- Load A into immediate addres (A16) or visa-versa
Operators[ 0xEA ] = function()
	local A16 = bor( bshl(Read(PC+2), 8), Read(PC+1) )
	Write( A16, A)
	
	Cycle = 16
	PC = PC + 3
end

Operators[ 0xFA ] = function()
	local A16 = bor( bshl(Read(PC+2), 8), Read(PC+1) )

	A = Read( A16 )
	
	Cycle = 16
	PC = PC + 3
end

Operators[ 0x02 ] = function()
	local A16 = bor( bshl( B, 8 ), C )
	Write( A16, A )

	Cycle = 8
	PC = PC + 1
end

Operators[ 0x12 ] = function()
	local A16 = bor( bshl( D, 8 ), E )
	Write( A16, A )

	Cycle = 8
	PC = PC + 1
end

Operators[ 0x22 ] = function()
	local A16 = bor( bshl( H, 8 ), L )
	Write( A16, A )

	L = L + 1
	if L > 0xFF then
		L = band( L , 0xFF )
		H = band( (H + 1) , 0xFF )
	end


	Cycle = 8
	PC = PC + 1
end

Operators[ 0x32 ] = function()
	local A16 = bor( bshl( H, 8 ), L )
	Write( A16, A )

	L = L - 1
	if L < 0 then
		L = band( L , 0xFF )
		H = band( (H - 1) , 0xFF )
	end

	Cycle = 8
	PC = PC + 1
end


Operators[ 0x0A ] = function()
	local A16 = bor( bshl( B, 8 ), C )
	A = Read( A16 )

	Cycle = 8
	PC = PC + 1
end

Operators[ 0x1A ] = function()
	local A16 = bor( bshl( D, 8 ), E )
	A = Read( A16 )

	Cycle = 8
	PC = PC + 1
end

Operators[ 0x2A ] = function()

	A = Read( bor( bshl( H, 8 ), L ) )

	L = L + 1
	if L > 0xFF then
		L = band(L , 0xFF)
		H = band( (H + 1) , 0xFF )
	end

	Cycle = 8
	PC = PC + 1
end

Operators[ 0x3A ] = function()

	A = Read( bor( bshl( H, 8 ), L ) )

	L = L - 1
	if L < 0 then
		L = band(L , 0xFF)
		H = band( (H - 1) , 0xFF )
	end

	Cycle = 8
	PC = PC + 1
end



--- 8 Bit Arithmatic and Logic ---

-- ADD
Operators[ 0x80 ] = function() ByteAdd(B) end
Operators[ 0x81 ] = function() ByteAdd(C) end
Operators[ 0x82 ] = function() ByteAdd(D) end
Operators[ 0x83 ] = function() ByteAdd(E) end
Operators[ 0x84 ] = function() ByteAdd(H) end
Operators[ 0x85 ] = function() ByteAdd(L) end
Operators[ 0x86 ] = function() ByteAdd( Read( bor( bshl( H, 8 ), L ) ) ); Cycle = 8 end
Operators[ 0x87 ] = function() ByteAdd(A) end

-- ADD with Carry (ADC)
Operators[ 0x88 ] = function() ByteAdc(B) end
Operators[ 0x89 ] = function() ByteAdc(C) end
Operators[ 0x8A ] = function() ByteAdc(D) end
Operators[ 0x8B ] = function() ByteAdc(E) end
Operators[ 0x8C ] = function() ByteAdc(H) end
Operators[ 0x8D ] = function() ByteAdc(L) end
Operators[ 0x8E ] = function() ByteAdc( Read( bor( bshl( H, 8 ), L ) ) ); Cycle = 8 end
Operators[ 0x8F ] = function() ByteAdc(A) end

-- SUB
Operators[ 0x90 ] = function() ByteSub(B) end
Operators[ 0x91 ] = function() ByteSub(C) end
Operators[ 0x92 ] = function() ByteSub(D) end
Operators[ 0x93 ] = function() ByteSub(E) end
Operators[ 0x94 ] = function() ByteSub(H) end
Operators[ 0x95 ] = function() ByteSub(L) end
Operators[ 0x96 ] = function() ByteSub( Read( bor( bshl( H, 8 ), L ) ) ); Cycle = 8 end
Operators[ 0x97 ] = function() ByteSub(A) end

-- SUB with Borrow (ABC)
Operators[ 0x98 ] = function() ByteSbc(B) end
Operators[ 0x99 ] = function() ByteSbc(C) end
Operators[ 0x9A ] = function() ByteSbc(D) end
Operators[ 0x9B ] = function() ByteSbc(E) end
Operators[ 0x9C ] = function() ByteSbc(H) end
Operators[ 0x9D ] = function() ByteSbc(L) end
Operators[ 0x9E ] = function() ByteSbc( Read( bor( bshl( H, 8 ), L ) ) ); Cycle = 8 end
Operators[ 0x9F ] = function() ByteSbc(A) end

-- AND
Operators[ 0xA0 ] = function() ByteAnd(B) end
Operators[ 0xA1 ] = function() ByteAnd(C) end
Operators[ 0xA2 ] = function() ByteAnd(D) end
Operators[ 0xA3 ] = function() ByteAnd(E) end
Operators[ 0xA4 ] = function() ByteAnd(H) end
Operators[ 0xA5 ] = function() ByteAnd(L) end
Operators[ 0xA6 ] = function() ByteAnd( Read( bor( bshl( H, 8 ), L ) ) ); Cycle = 8 end
Operators[ 0xA7 ] = function() ByteAnd(A) end

-- XOR
Operators[ 0xA8 ] = function() ByteXor(B) end
Operators[ 0xA9 ] = function() ByteXor(C) end
Operators[ 0xAA ] = function() ByteXor(D) end
Operators[ 0xAB ] = function() ByteXor(E) end
Operators[ 0xAC ] = function() ByteXor(H) end
Operators[ 0xAD ] = function() ByteXor(L) end
Operators[ 0xAE ] = function() ByteXor( Read( bor( bshl( H, 8 ), L ) ) ); Cycle = 8 end
Operators[ 0xAF ] = function() ByteXor(A) end

-- OR
Operators[ 0xB0 ] = function() ByteOr(B) end
Operators[ 0xB1 ] = function() ByteOr(C) end
Operators[ 0xB2 ] = function() ByteOr(D) end
Operators[ 0xB3 ] = function() ByteOr(E) end
Operators[ 0xB4 ] = function() ByteOr(H) end
Operators[ 0xB5 ] = function() ByteOr(L) end
Operators[ 0xB6 ] = function() ByteOr( Read( bor( bshl( H, 8 ), L ) ) ); Cycle = 8 end
Operators[ 0xB7 ] = function() ByteOr(A) end

-- CMP
Operators[ 0xB8 ] = function() ByteCmp(B) end
Operators[ 0xB9 ] = function() ByteCmp(C) end
Operators[ 0xBA ] = function() ByteCmp(D) end
Operators[ 0xBB ] = function() ByteCmp(E) end
Operators[ 0xBC ] = function() ByteCmp(H) end
Operators[ 0xBD ] = function() ByteCmp(L) end
Operators[ 0xBE ] = function() ByteCmp( Read( bor( bshl( H, 8 ), L ) ) ); Cycle = 8 end
Operators[ 0xBF ] = function() ByteCmp(A) end


-- All of the above but on immediate data
Operators[ 0xC6 ] = function() ByteAdd( Read(PC+1) ); Cycle = 8; PC = PC + 1 end
Operators[ 0xD6 ] = function() ByteSub( Read(PC+1) ); Cycle = 8; PC = PC + 1 end
Operators[ 0xE6 ] = function() ByteAnd( Read(PC+1) ); Cycle = 8; PC = PC + 1 end
Operators[ 0xF6 ] = function() ByteOr( Read(PC+1) ); Cycle = 8; PC = PC + 1 end

Operators[ 0xCE ] = function() ByteAdc( Read(PC+1) ); Cycle = 8; PC = PC + 1 end
Operators[ 0xDE ] = function() ByteSbc( Read(PC+1) ); Cycle = 8; PC = PC + 1 end
Operators[ 0xEE ] = function() ByteXor( Read(PC+1) ); Cycle = 8; PC = PC + 1 end
Operators[ 0xFE ] = function() ByteCmp( Read(PC+1) ); Cycle = 8; PC = PC + 1 end


-- Bitwise not on A
Operators[ 0x2F ] = function()
	A = 255-A
	
	Hf = true
	Nf = true
	
	PC = PC + 1
	Cycle = 4
end



-- Byte Incriment

Operators[ 0x04 ] = function() B = ByteInc(B) end
Operators[ 0x0C ] = function() C = ByteInc(C) end
Operators[ 0x14 ] = function() D = ByteInc(D) end
Operators[ 0x1C ] = function() E = ByteInc(E) end
Operators[ 0x24 ] = function() H = ByteInc(H) end
Operators[ 0x2C ] = function() L = ByteInc(L) end
Operators[ 0x34 ] = function()
	local R1 = Read( bor( bshl( H, 8 ), L ) )
	local R1 = ByteInc(R1)
	Write( bor( bshl( H, 8 ), L ), R1 )
	
	Cycle = 12
end
Operators[ 0x3C ] = function() A = ByteInc(A) end


-- Byte Decriment

Operators[ 0x05 ] = function() B = ByteDec(B) end
Operators[ 0x0D ] = function() C = ByteDec(C) end
Operators[ 0x15 ] = function() D = ByteDec(D) end
Operators[ 0x1D ] = function() E = ByteDec(E) end
Operators[ 0x25 ] = function() H = ByteDec(H) end
Operators[ 0x2D ] = function() L = ByteDec(L) end
Operators[ 0x35 ] = function()
	local R1 = Read( bor( bshl( H, 8 ), L ) )
	local R1 = ByteDec(R1)
	Write( bor( bshl( H, 8 ), L ), R1 )
	
	Cycle = 12
end
Operators[ 0x3D ] = function() A = ByteDec(A) end





-- STACK PUSH
Operators[ 0xC5 ] = function() StackPush(B, C) end
Operators[ 0xD5 ] = function() StackPush(D, E) end
Operators[ 0xE5 ] = function() StackPush(H, L) end
Operators[ 0xF5 ] = function()
	F = 0
	if Cf then F = bor(F, 16) end
	if Hf then F = bor(F, 32) end
	if Nf then F = bor(F, 64) end
	if Zf then F = bor(F, 128) end
	
	StackPush(A, F)
end

-- STACK POP
Operators[ 0xC1 ] = function() B, C = StackPop() end
Operators[ 0xD1 ] = function() D, E = StackPop() end
Operators[ 0xE1 ] = function() H, L = StackPop() end
Operators[ 0xF1 ] = function()
	A, F = StackPop()
	
	if band(F, 16) == 16 then Cf = true else Cf = false end
	if band(F, 32) == 32 then Hf = true else Hf = false end
	if band(F, 64) == 64 then Nf = true else Nf = false end
	if band(F, 128) == 128 then Zf = true else Zf = false end
end


-- 16 bit load immediate

Operators[ 0x01 ] = function() 
	B = Read(PC + 2)
	C = Read(PC + 1)
	
	PC = PC + 3
	Cycle = 12
end

Operators[ 0x11 ] = function() 
	D = Read(PC + 2)
	E = Read(PC + 1)
	
	PC = PC + 3
	Cycle = 12
end

Operators[ 0x21 ] = function() 
	H = Read(PC + 2)
	L = Read(PC + 1)
	
	PC = PC + 3
	Cycle = 12
end

Operators[ 0x31 ] = function() 
	SP = bor( bshl( Read( PC + 2 ) , 8 ) , Read(PC + 1) )
	
	PC = PC + 3
	Cycle = 12
end


-- Save SP at 16 bit immeiate address
Operators[ 0x08 ] = function() 

	local A16 = bor( bshl( Read( PC + 2 ) , 8 ) , Read(PC + 1) )
	local SPhi = bshr( band(SP, 0xFF00), 8 )
	local SPlo = band(SP , 0xFF )
	
	Write(A16,SPlo)
	Write(A16+1,SPhi)
	
	Cycle = 20
	PC = PC + 3
end

-- Load SP + signed immediate into HL
Operators[ 0xF8 ] = function() 
	local D8 = Read(PC+1)
	local S8 = ( band(D8, 127) - band(D8, 128))
	local tSP = SP + S8 
	
	if S8 >= 0 then
		Cf = ( band(SP , 0xFF) + ( S8 ) ) > 0xFF
		Hf = ( band(SP , 0xF) + band( S8 , 0xF ) ) > 0xF
	else
		Cf = band(tSP , 0xFF) <= band(SP , 0xFF)
		Hf = band(tSP , 0xF) <= band(SP , 0xF)
	end

	Zf = false
	Nf = false
	
	H = bshr( band( tSP , 0xFF00), 8 )
	L = band( tSP , 0xFF )
	
	Cycle = 12
	PC = PC + 2
end

-- Load HL into SP
Operators[ 0xF9 ] = function() 
	SP = bor( bshl( H, 8 ), L )
	
	Cycle = 8
	PC = PC + 1
end


-- Carry Operations
Operators[ 0x37 ] = function() 
	Cf = true
	Hf = false
	Nf = false
	
	PC = PC + 1
	Cycle = 4
end

Operators[ 0x3F ] = function() 

	Cf = not Cf
	Hf = false
	Nf = false
	
	PC = PC + 1
	Cycle = 4
end

-- DAA, this one is a bitch, credit to blarrg
Operators[ 0x27 ] = function() 


	if Nf then

		if Hf then A = band( A - 6, 0xFF ) end

		if Cf then A = A - 0x60 end

	else

		if band(A , 0xF) > 9 or Hf then A = (A + 0x06) end
		
		if A > 0x9F or Cf then A = (A + 0x60) end

	end

	--Cf = A > 0xFF

	Hf = false
	Zf = false

	if A > 0xFF then
		Cf = true
	end

	A = band(A, 0xFF)

	if A == 0 then
		Zf = true
	end


	
	PC = PC + 1
	Cycle = 4
end


--- ROTATES

Operators[ 0x17 ] = function() 
	local Bit7 = band( A, 128 ) == 128
	
	A = bor( band( bshl(A, 1) , 0xFF) , (Cf and 1 or 0) )

	Cf = Bit7
	Zf = false
	Nf = false
	Hf = false

	PC = PC + 1
	Cycle = 4

end

Operators[ 0x1F ] = function()
	local Bit0 = band( A, 1 ) == 1

	A = bor( band( bshr(A, 1) , 0xFF) , (Cf and 128 or 0) )

	Cf = Bit0
	Zf = false
	Nf = false
	Hf = false

	PC = PC + 1
	Cycle = 4
end

Operators[ 0x07 ] = function()
	local Bit7 = band( A, 128 ) == 128

	A = bor( band( bshl(A, 1) , 0xFF) , ( Bit7 and 1 or 0) )

	Cf = Bit7
	Zf = false
	Nf = false
	Hf = false

	PC = PC + 1
	Cycle = 4
end

Operators[ 0x0F ] = function()
	local Bit0 = band( A, 1 ) == 1

	A = bor( band( bshr(A, 1) , 0xFF) , (Bit0 and 128 or 0) )

	Cf = Bit0
	Zf = false
	Nf = false
	Hf = false

	PC = PC + 1
	Cycle = 4
end


