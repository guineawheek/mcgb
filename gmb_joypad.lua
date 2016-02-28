
local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local bshr = bit.rshift
local bshl = bit.lshift



function isDown( b )
    local x, y, z = commands.getBlockPosition()
    local plate = commands.getBlockInfo(x + b[1], y + b[2], z + b[3])
    return plate.state.powered
    -- we say the button is pressed if the pressure plate is pressed.
end


function UpdateKeys()

	local OldButtonByte = ButtonByte
	local OldDPadByte = DPadByte

	ButtonByte = ( isDown( START ) and band( ButtonByte, (15 - 8) )  or bor( ButtonByte, 8 ) )
	ButtonByte = ( isDown( SELECT ) and band( ButtonByte, (15 - 4) )  or bor( ButtonByte, 4 ) ) 
	ButtonByte = ( isDown( BUTTONB ) and band( ButtonByte, (15 - 2) )  or bor( ButtonByte, 2 ) )
	ButtonByte = ( isDown( BUTTONA ) and band( ButtonByte, (15 - 1) )  or bor( ButtonByte, 1 ) ) 

	DPadByte = ( isDown( DOWN ) and    band( DPadByte, (15 - 8) )  or bor( DPadByte, 8 ) ) 
	DPadByte = ( isDown( UP ) and  band( DPadByte, (15 - 4) )  or bor( DPadByte, 4 ) )
	DPadByte = ( isDown( LEFT ) and  band( DPadByte, (15 - 2) )  or bor( DPadByte, 2 ) ) 
	DPadByte = ( isDown( RIGHT ) and band( DPadByte, (15 - 1) )  or bor( DPadByte, 1 ) ) 

	if ButtonByte ~= OldButtonByte or DPadBye ~= OldDPadByte then
		IF = bor( IF, 16 )
	end

end


function RestartJoypad()

	-- 
	DPadByte = 0xF
	ButtonByte = 0xF

	SelectButtonKeys = true
	SelectDirectionKeys = false

end







--- JOYP

MRead[ 0xFF00 ] = function(  Addr )
	if SelectDirectionKeys then
		return ButtonByte + (SelectDirectionKeys and 16 or 0) + (SelectButtonKeys and 32 or 0)
	elseif SelectButtonKeys then
		return DPadByte + (SelectDirectionKeys and 16 or 0) + (SelectButtonKeys and 32 or 0)
	end
end

MWrite[ 0xFF00 ] = function(  Addr, Data )
	SelectDirectionKeys = band(Data, 16) == 16 
	SelectButtonKeys = band(Data, 32) == 32
end
