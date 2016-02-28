local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local bshr = bit.rshift
local bshl = bit.lshift


local math_ceil = math.ceil
local math_floor = math.floor



















function RestartGPU() 


	--------------------------------
	-- LCD/GPU Hardware Registers --
	--------------------------------

	ScanCycle = 0	-- The number of cycles executed so far, resets at end of hblank.

	-- LCD Control Register
	LCDEnable = false -- Disables and enables the LCD
	WindowMap = 0x98000 -- Pointer to the Map used by the Window Tile map. 0 = 0x9800, 1 = 0x9C00
	WindowEnable = false -- Enables and Disables drawing of the window
	TileData = false -- Pointer to the tiledata used by both window and bg. 0 = 0x8800, 1 =0x8000
	BGMap = 0x9800 -- Pointer to the Map used by the BG. 0 = 0x9800, 1 = 0x9C00
	SpriteSize = 8 -- Sprite Vertical size. 0 = 8, 1 = 16
	SpriteEnable = false -- Enables/Disables drawing of sprites
	BGEnable = false -- Enabled/Disables the drawing of the BG

	-- LCD Status Register
	CoincidenceInterupt = false
	ModeTwoInterupt = false
	ModeOneInterupt = false
	ModeZeroInterupt = false

	CoincidenceFlag = 0
	Mode = 0

	-- Scroll Registers
	ScrollX = 0
	ScrollY = 0
	WindowX = 0
	WindowY = 0

	-- Current scanline Y coordinate register
	ScanlineY = 1

	-- Value to compare with ScanLineY for Coincidence (Nothing special, just a value you can R/W to)
	CompareY = 0

	-- Palettes

	--Drawing Method stuff

	interleve = 0x300
	FrameSkip = true

	Pixels = {} -- Stores the pixels drawn last frame, this way we only redraw what we need to. 

	for n = 0, 23040 do
		Pixels[n] = 1
	end

	ScanlinePixels = {}-- Stores the current scanlines pixels, drawing them at the end
	ScanlineData = {}-- Stores the current scanlines data, for comparing transparency

	for n = 0, 200 do
		ScanlinePixels[n] = 0
		ScanlineData[n] = 0
	end




end























function UpdateScreen()
	if LCDEnable then

		ScanCycle = ScanCycle + Cycle

		if ScanCycle > 456 then
			ScanCycle = ScanCycle - 456

			ScanlineY = ( ScanlineY + 1 )%154
		end


		if ScanlineY >= 144 and ScanlineY <= 153 then -- vblank

			if Mode ~= 1 then
				if ModeOneInterupt then IF = bor( IF, 2 ) end -- request LCD interupt for entering Mode 1
				IF = bor( IF, 1 ) -- Reques VBlank interupt
				Mode = 1
			end

		elseif ScanlineY >= 0 and ScanlineY <= 143 then -- not vblank

			if ScanCycle >= 1 and ScanCycle <= 80 then
				if Mode ~= 2 then
					if ModeTwoInterupt then IF = bor( IF, 2 ) end -- request LCD interupt for entering Mode 2
					Mode = 2
				end

			elseif ScanCycle >= 81 and ScanCycle <= 252 then
				if Mode ~= 3 then
					Mode = 3
				end

			elseif ScanCycle >= 253 and ScanCycle <= 456 then

				if Mode ~= 0 then
					Render_Scanline()
					if ModeZeroInterupt then IF = bor( IF, 2 ) end -- request LCD interupt for entering Mode 0
					Mode = 0
				end


			end

		end

	else

		ScanlineY = 0
		ScanCycle = 0
		Mode = 0

	end


	if ScanlineY == CompareY and CoincidenceInterupt then
		IF = bor( IF, 2 ) -- request LCD interrupt
	end

end

























-----------------
-- LCD and GPU --
-----------------

-- Background Scroll Y
MRead[ 0xFF42 ] = function(  Addr ) return ScrollY end
MWrite[ 0xFF42 ] = function(  Addr, Data ) ScrollY = Data end

-- Background Scroll X
MRead[ 0xFF43 ] = function(  Addr ) return ScrollX end
MWrite[ 0xFF43 ] = function(  Addr, Data ) ScrollX = Data end

-- Window Scroll X
MRead[ 0xFF4A ] = function(  Addr ) return WindowY end
MWrite[ 0xFF4A ] = function(  Addr, Data ) WindowY = Data end

-- Window Scroll Y
MRead[ 0xFF4B ] = function(  Addr ) return WindowX end
MWrite[ 0xFF4B ] = function(  Addr, Data ) WindowX = Data end



-- Current Scanline Register
MRead[ 0xFF44 ] = function(  Addr ) return ScanlineY end
MWrite[ 0xFF44 ] = function(  Addr, Data ) ScanlineY = 0 end -- Reset Scanline

-- LY Compare
MRead[ 0xFF45 ] = function(  Addr ) return CompareY end
MWrite[ 0xFF45 ] = function(  Addr, Data ) CompareY = Data end

-- LCD Control Register
MRead[ 0xFF40 ] = function(  Addr ) return IO[Addr] end
MWrite[ 0xFF40 ] = function(  Addr, Data )

	IO[Addr] = Data

	LCDEnable 		=  band(128, Data) == 128
	WindowMap 		=  ( band(64, Data) == 64 and 0x9C00 or 0x9800)
	WindowEnable 	=  band(32, Data) == 32
	TileData 		=  band(16, Data) == 16
	BGMap 			=  ( band(8, Data) == 8 and 0x9C00 or 0x9800)
	SpriteSize 		=  ( band(4, Data) == 4 and 16 or 8)
	SpriteEnable 	=  band(2, Data) == 2
	BGEnable 		=  band(1, Data) == 1

end

-- LCD Status Regiter

MRead[ 0xFF41 ] = function(  Addr )
	return ( (CoincidenceInterupt and 64 or 0) +
	(ModeTwoInterupt and 32 or 0) +
	(ModeOneInterupt and 16 or 0) +
	(ModeZeroInterupt and 8 or 0) +
	(CompareY == ScanlineY and 4 or 0) +
	Mode )
end

MWrite[ 0xFF41 ] = function(  Addr, Data )
	CoincidenceInterupt = band(Data, 64) == 64
	ModeTwoInterupt = band(Data, 32) == 32
	ModeOneInterupt = band(Data, 16) == 16
	ModeZeroInterupt = band(Data, 8) == 8
end





























function Render_Scanline()



	local PalMem = IO[ 0xFF47 ]

	-- Setup the palette
	local BGPal = {
	[0] = band( PalMem, 3 ),
	band( bshr(PalMem, 2), 3), 
	band( bshr(PalMem, 4), 3),
	band( bshr(PalMem, 6), 3) }	


	local YCo = ScanlineY 
	local PixelY = YCo + 0.5

	local TileX = math_floor( ScrollX/8 ) 
	local TileY = math_floor( band((ScrollY + YCo), 0xFF)/8 )

	local XOffset = 7 - ( ScrollX % 8 )
	local YOffset = (ScrollY + YCo) % 8

	local WinTileY = math_floor( (YCo - WindowY)/8 )
	local WinYOfffset = (YCo - WindowY) % 8

	local WinX = WindowX - 7


	if BGEnable then

		for i = 0, 20 do

			local TileID = VRAM[ BGMap + band(i + TileX, 0x1F) + TileY*32 ]
			local ByteA
			local ByteB

			if TileData then

				ByteA = VRAM[ 0x8000 + TileID*16 + YOffset*2 ]
				ByteB = VRAM[ 0x8000 + TileID*16 + YOffset*2 + 1 ]

			else

				TileID = band(TileID, 127) - band(TileID, 128)

				ByteA = VRAM[ 0x9000 + TileID*16 + YOffset*2 ]
				ByteB = VRAM[ 0x9000 + TileID*16 + YOffset*2 + 1 ]

			end

			for j = 0, 7 do
					
				local PixelX = i*8 - j + XOffset 

				if PixelX >= 0 and PixelX < 160 then

					local BitA = band( bshr(ByteA, j), 1) 
					local BitB = band( bshr(ByteB, j), 1)

					local Colour = BGPal[ BitB*2 + BitA ]

					ScanlinePixels[PixelX] = Colour
					ScanlineData[PixelX] = BitB*2 + BitA
				end
			end
		end
	end

	if WindowEnable and YCo >= WindowY and WinX >= -7 and WinX < 160 then

		for i = 0, 20 do

			local TileID = VRAM[ WindowMap + i + WinTileY*32 ]
			local ByteA
			local ByteB

			if TileData then

				ByteA = VRAM[ 0x8000 + TileID*16 + WinYOfffset*2 ]
				ByteB = VRAM[ 0x8000 + TileID*16 + WinYOfffset*2 + 1 ]

			else

				TileID = band(TileID, 127) - band(TileID, 128)

				ByteA = VRAM[ 0x9000 + TileID*16 + WinYOfffset*2 ]
				ByteB = VRAM[ 0x9000 + TileID*16 + WinYOfffset*2 + 1 ]

			end

			for j = 0, 7 do
					
				local PixelX = i*8 - j + WindowX

				if PixelX >= 0 and PixelX < 160 then

					local BitA = band( bshr(ByteA, j), 1) 
					local BitB = band( bshr(ByteB, j), 1)

					local Colour = BGPal[ BitB*2 + BitA ]

					ScanlinePixels[PixelX] = Colour
					ScanlineData[PixelX] = BitB*2 + BitA
				end
			end
		end
	end



	if SpriteEnable then

		local PalMem1 = IO[ 0xFF49 ]
		local PalMem2 = IO[ 0xFF48 ]

		local SpPal1 = {
		band( bshr(PalMem1, 2), 3), 
		band( bshr(PalMem1, 4), 3),
		band( bshr(PalMem1, 6), 3) }

		local SpPal2 = {
		band( bshr(PalMem2, 2), 3), 
		band( bshr(PalMem2, 4), 3),
		band( bshr(PalMem2, 6), 3) }

		if SpriteSize == 8 then

			for n = 160, 0, -4 do

				local YPos = OAM[ 0xFE00 + n ] - 16
				local XPos = OAM[ 0xFE00 + n + 1 ] - 8
				local TileID = OAM[ 0xFE00 + n + 2 ]
				local SpriteFlags = OAM[ 0xFE00 + n + 3 ]
				
				local Alpha =  band(SpriteFlags  , 128) == 128
				local YFlip = band(SpriteFlags , 64)    == 64
				local XFlip = band(SpriteFlags , 32)    == 32
				local SPalID = band(SpriteFlags , 16)   == 16

				if ScanlineY >= YPos and ScanlineY < YPos + 8 then

					local TileOffset = YFlip and -(ScanlineY - YPos) + 7 or ScanlineY - YPos

					local ByteA = VRAM[ 0x8000 + TileID*16 + TileOffset*2 ]
					local ByteB = VRAM[ 0x8000 + TileID*16 + TileOffset*2 + 1 ]

					for j = 0, 7 do
							
						local PixelX = XFlip and j + XPos or -j + 7 + XPos

						if PixelX >= 0 and PixelX < 160 then

							local BitA = band( bshr(ByteA, j), 1) 
							local BitB = band( bshr(ByteB, j), 1)

							if BitA + BitB > 0 then

								local Colour = SPalID and SpPal1[ BitB*2 + BitA ] or SpPal2[ BitB*2 + BitA ] 

								if ( not Alpha ) or ScanlineData[PixelX] == 0 then
									ScanlinePixels[PixelX] = Colour
								end

							end
						end
					end
				end
			end

		else

			for n = 160, 0, -4 do

				local YPos = OAM[ 0xFE00 + n ] - 16
				local XPos = OAM[ 0xFE00 + n + 1 ] - 8
				local TileID = OAM[ 0xFE00 + n + 2 ]
				local SpriteFlags = OAM[ 0xFE00 + n + 3 ]
				
				local Alpha =  band(SpriteFlags  , 128) == 128
				local YFlip = band(SpriteFlags , 64)    == 64
				local XFlip = band(SpriteFlags , 32)    == 32
				local SPalID = band(SpriteFlags , 16)   == 16

				if ScanlineY >= YPos and ScanlineY < YPos + 16 then

					local TileOffset = YFlip and -(ScanlineY - YPos) + 15 or ScanlineY - YPos

					if TileOffset < 8 then

						TileID = band(TileID, 0xFE)

					else

						TileID = bor(TileID, 0x01)

						TileOffset = TileOffset - 8

					end


					local ByteA = VRAM[ 0x8000 + TileID*16 + TileOffset*2 ]
					local ByteB = VRAM[ 0x8000 + TileID*16 + TileOffset*2 + 1 ]


					for j = 0, 7 do
							
						local PixelX = XFlip and j + XPos or -j + 7 + XPos

						if PixelX >= 0 and PixelX < 160 then

							local BitA = band( bshr(ByteA, j), 1) 
							local BitB = band( bshr(ByteB, j), 1)

							if BitA + BitB > 0 then

								local Colour = SPalID and SpPal1[ BitB*2 + BitA ] or SpPal2[ BitB*2 + BitA ]

								if ( not Alpha ) or ScanlineData[PixelX] == 0 then
									ScanlinePixels[PixelX] = Colour
								end

							end
						end
					end
				end
			end
		end
	end



	for n = 0, 159 do
		local Colour = ScanlinePixels[n]
		local ArrayCoords = YCo*170 + n + 1

		if Pixels[ArrayCoords] ~= Colour then

			--love.graphics.setColor( ColourPalette[Colour][1], ColourPalette[Colour][2], ColourPalette[Colour][3], 255 )
			--love.graphics.point( n + 0.5, YCo + 0.5 )
                        
                        canvas:drawPixel(n, YCo, ColourPalette[Colour])
			Pixels[ArrayCoords] = Colour

		end
	end

end










--[[




	if SpriteSize == 8 then


		local PalMem1 = Memory[ 0xFF49 ]
		local PalMem2 = Memory[ 0xFF48 ]

		for n = 0, 159, 4 do
			local YPos = Memory[ 0xFE00 + n ]
			if YPos > 0 and YPos < 160 then
				local XPos = Memory[ 0xFE00 + (n+1) ]
				if XPos > 0 and XPos < 168 then

					local SpriteFlags = Memory[ 0xFE00 + (n+3) ]
					
					local TileID = Memory[ 0xFE00 + (n+2) ]
					local Alpha =  band(SpriteFlags  , 128) == 128
					local YFlip = band(SpriteFlags , 64)    == 64
					local XFlip = band(SpriteFlags , 32)    == 32
					local SPalID = band(SpriteFlags , 16)   == 16

					if SPalID then
						SpPal = {
						band( bshr(PalMem1, 2), 3), 
						band( bshr(PalMem1, 4), 3),
						band( bshr(PalMem1, 6), 3) }
					else
						SpPal = {
						band( bshr(PalMem2, 2), 3), 
						band( bshr(PalMem2, 4), 3),
						band( bshr(PalMem2, 6), 3) }
					end


					for i = 0,7 do

						local ByteA = Memory[ 0x8000 + TileID*16 + i*2]
						local ByteB = Memory[ 0x8000 + TileID*16 + i*2 + 1]

						for j = 0,7 do

						local BitA = band( bshr(ByteA, j), 1) --that's a lower-case L, not a 1
						local BitB = band( bshr(ByteB, j), 1)

							if ( bshl(BitB, 1) +  BitA) > 0 then

								local PixelX = XPos - 1 + (XFlip and j - 7 or -j)
								local PixelY = YPos - 16 + (YFlip and -i + 7 or i)

								local ArrayCoords = (PixelX + 1) + (PixelY + 1)*170
								
								local Colour = ColourDB[ SpPal[ BitB*2 +  BitA] ]

								if PixelX >= 0 and PixelX < 160 and PixelY >= 0 and PixelY < 144 then

								if Pixels[ArrayCoords] ~= Colour then

									love.graphics.setColor( Colour, Colour, Colour, 255 )
									love.graphics.point( PixelX + 1.5, PixelY + 1.5 )

									Pixels[ArrayCoords] = Colour

								end
								end
							end
						end
					end
				end
			end
		end
	else
















function GPUDraw2()


	local PalMem = Memory[ 0xFF47 ]

	-- Setup the palette
	local BGPal = {
	band( bshr(PalMem, 2), 3), 
	band( bshr(PalMem, 4), 3),
	band( bshr(PalMem, 6), 3) }	
	BGPal[0] = band( PalMem, 3 )


	for i = 0,31 do
		for j = 0,31 do

		local TileID = Memory[ BGMap + i + j*32 ]

		for ii = 0, 7 do
			local ByteA
			local ByteB

			if TileData == 0x8000 then

				ByteA = Memory[ 0x8000 + TileID*16 + ii*2 ]
				ByteB = Memory[ 0x8000 + TileID*16 + ii*2 + 1 ]

			else

				TileID = band(TileID, 127) - band(TileID, 128)

				ByteA = Memory[ 0x8000 + TileID*16 + ii*2 ]
				ByteB = Memory[ 0x8000 + TileID*16 + ii*2 + 1 ]

			end

			for jj = 0, 7 do
					
				local PixelX = i*8 + -jj + 20
				local PixelY = j*8 + ii + 20

				local BitA = band( bshr(ByteA, jj), 1) 
				local BitB = band( bshr(ByteB, jj), 1)

				local Colour = ColourDB[ BGPal[ bor( bshl(BitB,1) ,  BitA) ] ]

				local ArrayCoords = PixelX + (PixelY + 1)*170

					if Pixels[ArrayCoords] ~= Colour then

						love.graphics.setColor( Colour, Colour, Colour, 255 )
						love.graphics.point( PixelX + 0.5, PixelY + 0.5 )

						Pixels[ArrayCoords] = Colour

					end
				end
			end
		end
	end
end





function GPUDraw()

	local XMax = 21
	local YMax = 19

	if WindowEnable and WindowX >= 0 and WindowX < 167 and WindowY >= 0 and WindowY < 144  then
		XMax = math_floor((WindowX - 7)/8)
		YMax = math_floor((WindowY)/8)
	end




	if true then

		local PalMem = Memory[ 0xFF47 ]
		local BGPal = {
		band( bshr(PalMem, 2), 3), 
		band( bshr(PalMem, 4), 3),
		band( bshr(PalMem, 6), 3) }

		BGPal[0] = band( PalMem, 3 )

		local TileX = math_floor(ScrollX/8)
		local TileY = math_floor(ScrollY/8)

		local TileMap = BGMap

		for i = 0, 18 do -- The Vertical, 19 tiles max high (Possible 18 if it's lined up)

			for j = 0, 20 do -- The Horizontal, 21 tiles max high (Possibly 20 if it's lined up)


				local iy = (i + TileY)
				local jx = (j + TileX)

				local ii = band(iy , 0x1F) -- Wrap Around
				local jj = band(jx , 0x1F) -- Wrap Around



				-- Get the current Tile based on the current map
				local TileID = 0
					
				if TileData == 0x8000 then
					TileID = Memory[ TileMap + ii*32 + jj ]
				else
					TileID = Memory[ TileMap + ii*32 + jj ]
					TileID = band(TileID, 127) - band(TileID, 128)
					TileData = 0x9000
				end

				-- Loop through the 8 by 8 tile. 
				
				if not (i > YMax and j > XMax) then

					for k = 0,7 do

						local ByteA = Memory[ TileData + TileID*16 + k*2]
						local ByteB = Memory[ TileData + TileID*16 + k*2 + 1]

						for l = 0,7 do

							local BitA = band( bshr(ByteA, l), 1) --that's a lower-case L, not a 1
							local BitB = band( bshr(ByteB, l), 1)
								
							local PixelX = (jx*8 - l + 7	) - ScrollX
							local PixelY = (iy*8 + k + 0) - ScrollY

							if PixelX >= 0 and PixelX < 160 and PixelY >= 0 and PixelY < 144 then

								local Colour = ColourDB[ BGPal[ bor( bshl(BitB,1) ,  BitA) ] ]

								local ArrayCoords = (PixelX + 1) + (PixelY + 1)*170

								if Pixels[ArrayCoords] ~= Colour then

									love.graphics.setColor( Colour, Colour, Colour, 255 )
									love.graphics.point( PixelX + 1.5, PixelY + 1.5 )

									Pixels[ArrayCoords] = Colour

								end
							end
						end
					end
				end
			end
		end
	end






	if WindowEnable and WindowX >= 0 and WindowX < 167 and WindowY >= 0 and WindowY < 144  then

		WindowX = WindowX - 7

		XMax = math_floor((160 - WindowX)/8)
		YMax = math_floor((144 - WindowY)/8)

		local PalMem = Memory[ 0xFF47 ]
		local WinPal = {
		band( bshr(PalMem, 2), 3),
		band( bshr(PalMem, 4), 3),
		band( bshr(PalMem, 6), 3) }

		WinPal[0] = band( PalMem, 3 )







		local WinMap = WindowMap

			for i = 0, YMax do

				for j = 0, XMax do

				local TileID
					
				if TileData == 0x8000 then
					TileID = Memory[ WinMap + i*32 + j ]
				else
					TileID = Memory[ WinMap + i*32 + j ]
					TileID = band(TileID, 127) - band(TileID, 128)
					TileData = 0x9000
				end

				for k = 0,7 do

					local ByteA = Memory[ TileData + TileID*16 + k*2]
					local ByteB = Memory[ TileData + TileID*16 + k*2 + 1]

					for l = 0,7 do

						local BitA = band( bshr(ByteA, l), 1) --that's a lower-case L, not a 1
						local BitB = band( bshr(ByteB, l), 1)
							
						local PixelX = (j*8 - l + 7 ) + WindowX 
						local PixelY = (i*8 + k ) + WindowY

						if PixelX >= 0 and PixelX < 160 and PixelY >= 0 and PixelY < 144 then

							local Colour = ColourDB[ WinPal[ bor( bshl(BitB,1) ,  BitA) ] ]

							local ArrayCoords = (PixelX + 1) + (PixelY + 1)*170

								if Pixels[ArrayCoords] ~= Colour then

									love.graphics.setColor( Colour, Colour, Colour, 255 )
									love.graphics.point( PixelX + 1.5, PixelY + 1.5 )

									Pixels[ArrayCoords] = Colour

								end
						end
					end
				end
			end
		end
	end








	if SpriteSize == 8 then


		local PalMem1 = Memory[ 0xFF49 ]
		local PalMem2 = Memory[ 0xFF48 ]

		for n = 0, 159, 4 do
			local YPos = Memory[ 0xFE00 + n ]
			if YPos > 0 and YPos < 160 then
				local XPos = Memory[ 0xFE00 + (n+1) ]
				if XPos > 0 and XPos < 168 then

					local SpriteFlags = Memory[ 0xFE00 + (n+3) ]
					
					local TileID = Memory[ 0xFE00 + (n+2) ]
					local Alpha =  band(SpriteFlags  , 128) == 128
					local YFlip = band(SpriteFlags , 64)    == 64
					local XFlip = band(SpriteFlags , 32)    == 32
					local SPalID = band(SpriteFlags , 16)   == 16

					if SPalID then
						SpPal = {
						band( bshr(PalMem1, 2), 3), 
						band( bshr(PalMem1, 4), 3),
						band( bshr(PalMem1, 6), 3) }
					else
						SpPal = {
						band( bshr(PalMem2, 2), 3), 
						band( bshr(PalMem2, 4), 3),
						band( bshr(PalMem2, 6), 3) }
					end


					for i = 0,7 do

						local ByteA = Memory[ 0x8000 + TileID*16 + i*2]
						local ByteB = Memory[ 0x8000 + TileID*16 + i*2 + 1]

						for j = 0,7 do

						local BitA = band( bshr(ByteA, j), 1) --that's a lower-case L, not a 1
						local BitB = band( bshr(ByteB, j), 1)

							if ( bshl(BitB, 1) +  BitA) > 0 then

								local PixelX = XPos - 1 + (XFlip and j - 7 or -j)
								local PixelY = YPos - 16 + (YFlip and -i + 7 or i)

								local ArrayCoords = (PixelX + 1) + (PixelY + 1)*170
								
								local Colour = ColourDB[ SpPal[ BitB*2 +  BitA] ]

								if PixelX >= 0 and PixelX < 160 and PixelY >= 0 and PixelY < 144 then

								if Pixels[ArrayCoords] ~= Colour then

									love.graphics.setColor( Colour, Colour, Colour, 255 )
									love.graphics.point( PixelX + 1.5, PixelY + 1.5 )

									Pixels[ArrayCoords] = Colour

								end
								end
							end
						end
					end
				end
			end
		end
	else

		local PalMem1 = Memory[ 0xFF49 ]
		local PalMem2 = Memory[ 0xFF48 ]

		for n = 0, 159, 4 do
			local YPos = Memory[ 0xFE00 + n ]
			if YPos > 0 and YPos < 160 then
				local XPos = Memory[ 0xFE00 + (n+1) ]
				if XPos > 0 and XPos < 168 then

					local SpriteFlags = Memory[ 0xFE00 + (n+3) ]
					
					local TileID = band( Memory[ 0xFE00 + (n+2) ] , 0xFE )
					local Alpha =  band(SpriteFlags  , 128) == 128
					local YFlip = band(SpriteFlags , 64)    == 64
					local XFlip = band(SpriteFlags , 32)    == 32
					local SPalID = band(SpriteFlags , 16)   == 16

					if SPalID then
						SpPal = {
						band( bshr(PalMem1, 2), 3), 
						band( bshr(PalMem1, 4), 3),
						band( bshr(PalMem1, 6), 3) }
					else
						SpPal = {
						band( bshr(PalMem2, 2), 3), 
						band( bshr(PalMem2, 4), 3),
						band( bshr(PalMem2, 6), 3) }
					end


					for i = 0,7 do

						local ByteA = Memory[ 0x8000 + TileID*16 + i*2]
						local ByteB = Memory[ 0x8000 + TileID*16 + i*2 + 1]

						for j = 0,7 do

							local BitA = band( bshr(ByteA, j), 1) --that's a lower-case L, not a 1
							local BitB = band( bshr(ByteB, j), 1)


							if BitB*2 + BitA > 0 then

								local PixelX = XPos - 1 + (XFlip and j - 7 or -j)
								local PixelY = YPos - 16 + (YFlip and -i + 7 or i) + (YFlip and 8 or 0)

								local ArrayCoords = (PixelX + 1) + (PixelY + 1)*170
								
								local Colour = ColourDB[ SpPal[ BitB*2 + BitA ] ]

								if PixelX >= 0 and PixelX < 160 and PixelY >= 0 and PixelY < 144 then

									if Pixels[ArrayCoords] ~= Colour then

										love.graphics.setColor( Colour, Colour, Colour, 255 )
										love.graphics.point( PixelX + 1.5, PixelY + 1.5 )

										Pixels[ArrayCoords] = Colour

									end
								end
							end
						end
					end

					local n2 = n + 1
					
					local TileID2 = TileID + 0x01


					for i = 0,7 do

						local ByteA = Memory[ 0x8000 + TileID2*16 + i*2 + 0]
						local ByteB = Memory[ 0x8000 + TileID2*16 + i*2 + 1]

						for j = 0,7 do

							local BitA = band( bshr(ByteA, j), 1) --that's a lower-case L, not a 1
							local BitB = band( bshr(ByteB, j), 1)


							if BitB*2 + BitA > 0 then

								local PixelX = XPos - 1 + (XFlip and j - 7 or -j) 
								local PixelY = YPos - 16 + (YFlip and -i + 7 or i) + (YFlip and 0 or 8)

								local ArrayCoords = (PixelX + 1) + (PixelY + 1)*170
								
								local Colour = ColourDB[ SpPal[ BitB*2 + BitA ] ]

								if PixelX >= 0 and PixelX < 160 and PixelY >= 0 and PixelY < 144 then

									if Pixels[ArrayCoords] ~= Colour then

										love.graphics.setColor( Colour, Colour, Colour, 255 )
										love.graphics.point( PixelX + 1.5, PixelY + 1.5 )

										Pixels[ArrayCoords] = Colour

									end
								end
							end
						end
					end

























				end
			end
		end
	end
end


]]--
