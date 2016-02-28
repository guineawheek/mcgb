local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local bshr = bit.rshift
local bshl = bit.lshift


function RestartSound() 
        -- no sound, this is minecraft.
        -- Hence, all the actual sound calls are dummied out.


	--Setup the waveforms for the 4 Square waveforms duties. 

	--[[SquareWaveData = {}


	-- Middle A + 1Octave, 880Hz Square Wave. 50% Duty
	SQ50 = love.sound.newSoundData( 16, 880*16, 16, 1 )
	for n = 0, 7 do SQ50:setSample( n , 1 ) end
	for n = 8, 15 do SQ50:setSample( n , -1 ) end

	SQ25 = love.sound.newSoundData( 16, 880*16, 16, 1 )
	for n = 0, 3 do SQ50:setSample( n , 1 ) end
	for n = 4, 15 do SQ50:setSample( n , -1 ) end

	SQ75 = love.sound.newSoundData( 16, 880*16, 16, 1 )
	for n = 0, 11 do SQ50:setSample( n , 1 ) end
	for n = 12, 15 do SQ50:setSample( n , -1 ) end

	SQ12 = love.sound.newSoundData( 16, 880*16, 16, 1 )
	for n = 0, 1 do SQ50:setSample( n , 1 ) end
	for n = 2, 15 do SQ50:setSample( n , -1 ) end

	SquareWaveData[0] = SQ12
	SquareWaveData[1] = SQ25
	SquareWaveData[2] = SQ50
	SquareWaveData[3] = SQ75







	Square1 = love.audio.newSource( SQ50, "static" )
	Square1:setLooping( true )

	Square2 = love.audio.newSource( SQ50, "static" )
	Square2:setLooping( true )
        --]]


	SoundCycle = 0


	Square1Enabled = false

	Square1Frequency = 0

	Square1SweepTime = 0
	Square1SweepShfit = 0
	Square1SweepDirection = 0
	Square1SweepCounter = 0

	Square1LengthCounter = 0
	Square1LengthEnable = false
	Square1Duty = 2

	Square1Volume = 15
	Square1VolumeDirection = 0 
	Square1VolumeSweep = 0 
	Square1VolumeCounter = 0






	Square2Enabled = false

	Square2Frequency = 0

	Square2LengthCounter = 0
	Square2LengthEnable = false
	Square2Duty = 2

	Square2Volume = 15
	Square2VolumeDirection = 0 
	Square2VolumeSweep = 0 
	Square2VolumeCounter = 0


end



























-- Square 1

--NR10, Sweep Register
MRead[ 0xFF10 ] = function( Addr ) return IO[Addr] end

MWrite[ 0xFF10 ] = function( Addr, Data )
	IO[Addr] = Data

	Square1SweepShift = band( Data, 7 )
	Square1SweepDirection = band( Data, 8 )
	Square1SweepTime = bshr( Data, 4 ) * 2

end

--NR11, Duty & Sound Length
MRead[ 0xFF11 ] = function( Addr ) return IO[Addr] end

MWrite[ 0xFF11 ] = function( Addr, Data )

	Square1LengthCounter = 64 - band( Data, 0x3F )

	if band( Data, 0xC0 ) ~= Square1Duty then
		Square1Duty = band( Data, 0xC0 )
		IO[Addr] = Square1Duty

		--[[Square1:stop()
		Square1 = love.audio.newSource( SquareWaveData[ bshr( Data, 6 ) ], "static" )
		Square1:setLooping( true )
		Square1:setPitch( (131072/(2048-Square1Frequency))/880 )
		Square1:setVolume(Square1Volume/15)

		if Square1Enabled then
			Square1:play()
		end
                --]]
	end


end

--NR12, Volume Envelope
MRead[ 0xFF12 ] = function( Addr ) return IO[Addr] end

MWrite[ 0xFF12 ] = function( Addr, Data )
	IO[Addr] = Data


	Square1Volume = bshr( band( Data, 0xF0 ), 4 )
	Square1VolumeDirection = bshr( band( Data, 8 ), 3 ) 
	Square1VolumeSweep = band( Data, 7 )

	--Square1:setVolume(Square1Volume/15)

end

--NR13, Frequency Lo
MRead[ 0xFF13 ] = function( Addr ) return 0 end

MWrite[ 0xFF13 ] = function( Addr, Data )
	
	Square1Frequency = band( Square1Frequency, 0xF00 ) + Data

	--Square1:setPitch( (131072/(2048-Square1Frequency))/880 )

end

--NR14, Frequency Hi
MRead[ 0xFF14 ] = function( Addr ) return IO[Addr] end

MWrite[ 0xFF14 ] = function( Addr, Data )

	Square1Frequency = band( Square1Frequency, 0x0FF ) + bshl( band( Data, 0x7 ), 8)
	Square1LengthEnable = band( Data, 0x40 ) == 0x40
	IO[Addr] = band( Data, 0x40 )

	if band( Data, 0x80 ) == 0x80 then 
		Square1Enabled = true
		--[[Square1:play()
		Square1:setPitch( (131072/(2048-Square1Frequency))/880 )
		Square1:setVolume(Square1Volume/15)
                --]]
		Square1LengthCounter = 64
	end


	
end




























-- Square 2


--NR21, Duty & Sound Length
MRead[ 0xFF16 ] = function( Addr ) return IO[Addr] end

MWrite[ 0xFF16 ] = function( Addr, Data )

	Square2LengthCounter = 64 - band( Data, 0x3F )

	if band( Data, 0xC0 ) ~= Square2Duty then
		Square2Duty = band( Data, 0xC0 )
		IO[Addr] = Square2Duty

		--[[Square2:stop()
		Square2 = love.audio.newSource( SquareWaveData[ bshr( Data, 6 ) ], "static" )
		Square2:setLooping( true )
		Square2:setPitch( (131072/(2048-Square2Frequency))/880 )
		Square2:setVolume(Square2Volume/15)

		if Square2Enabled then
			Square2:play()
		end
                --]]
	end


end

--NR22, Volume Envelope
MRead[ 0xFF17 ] = function( Addr ) return IO[Addr] end

MWrite[ 0xFF17 ] = function( Addr, Data )
	IO[Addr] = Data


	Square2Volume = bshr( band( Data, 0xF0 ), 4 )
	Square2VolumeDirection = bshr( band( Data, 8 ), 3 ) 
	Square2VolumeSweep = band( Data, 7 )

	--Square2:setVolume(Square2Volume/15)

end

--NR23, Frequency Lo
MRead[ 0xFF18 ] = function( Addr ) return 0 end

MWrite[ 0xFF18 ] = function( Addr, Data )
	
	Square2Frequency = band( Square2Frequency, 0xF00 ) + Data

	--Square2:setPitch( (131072/(2048-Square2Frequency))/880 )

end

--NR24, Frequency Hi
MRead[ 0xFF19 ] = function( Addr ) return IO[Addr] end

MWrite[ 0xFF19 ] = function( Addr, Data )

	Square2Frequency = band( Square2Frequency, 0x0FF ) + bshl( band( Data, 0x7 ), 8)
	Square2LengthEnable = band( Data, 0x40 ) == 0x40
	IO[Addr] = band( Data, 0x40 )

	if band( Data, 0x80 ) == 0x80 then 
		Square2Enabled = true
		--[[Square2:play()
		Square2:setPitch( (131072/(2048-Square2Frequency))/880 )
		Square2:setVolume(Square2Volume/15)
                --]]
		Square2LengthCounter = 64
	end


	
end













































function UpdateSound()

	SoundCycle = SoundCycle + Cycle

	if SoundCycle > 16383 then
		SoundCycle = SoundCycle - 16384
		--1/256th of a second

		if Square1Enabled then 


			if Square1SweepTime > 0 and Square1SweepShift > 0 then
				Square1SweepCounter = Square1SweepCounter + 1
				if Square1SweepCounter == Square1SweepTime then
					Square1SweepCounter = 0

					local Square1FrequencyShadow = Square1Frequency / bshl( 1, Square1SweepShift )

					if Square1SweepDirection == 0 then
						Square1FrequencyShadow = Square1Frequency + Square1FrequencyShadow

						if Square1FrequencyShadow > 2047 then
							Square1Enabled = false
							--Square1:stop()
						else
							Square1Frequency = Square1FrequencyShadow
							--Square1:setPitch( (131072/(2048-Square1Frequency))/880 )
							--Square1:setVolume(Square1Volume/15)
						end

					else
						Square1FrequencyShadow = Square1Frequency - Square1FrequencyShadow

						if Square1FrequencyShadow > 2047 then
							Square1Enabled = false
							--Square1:stop()
						else
							Square1Frequency = Square1FrequencyShadow
							--Square1:setPitch( (131072/(2048-Square1Frequency))/880 )
							--Square1:setVolume(Square1Volume/15)
						end

					end
				end
			end

			if Square1LengthEnable then
				Square1LengthCounter = Square1LengthCounter - 1

				if Square1LengthCounter == 0 then
					--Square1:stop()
					Square1Enabled = false
					Square1LengthEnable = false
				end
			end

			if Square1VolumeSweep ~= 0 then
				Square1VolumeCounter = Square1VolumeCounter + 1
				if Square1VolumeCounter > 4* Square1VolumeSweep - 1 then
					Square1VolumeCounter = 0

					local Square1VolumeShadow = Square1Volume + ( Square1VolumeDirection * 2 - 1 ) 

					if Square1VolumeShadow < 0 or Square1VolumeShadow > 15 then
						Square1VolumeSweep = 0 
					else
						Square1Volume = Square1VolumeShadow
						--Square1:setVolume(Square1Volume/15)
					end
				end
			end

		end








		if Square2Enabled then 

			if Square2LengthEnable then
				Square2LengthCounter = Square2LengthCounter - 1

				if Square2LengthCounter == 0 then
					--Square2:stop()
					Square2Enabled = false
					Square2LengthEnable = false
				end
			end

			if Square2VolumeSweep ~= 0 then
				Square2VolumeCounter = Square2VolumeCounter + 1
				if Square2VolumeCounter > 4*Square2VolumeSweep - 1 then
					Square2VolumeCounter = 0

					local Square2VolumeShadow = Square2Volume + ( Square2VolumeDirection * 2 - 1 )

					if Square2VolumeShadow < 0 or Square2VolumeShadow > 15 then
						Square2VolumeSweep = 0 
					else
						Square2Volume = Square2VolumeShadow
						--Square2:setVolume(Square2Volume/15)
					end
				end
			end

		end



	end



end
