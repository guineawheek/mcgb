
local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local bshr = bit.rshift
local bshl = bit.lshift



function RestartTimers()


	------------------------------
	-- Timer Hardware Registers --
	------------------------------
	
	-- Timer
	TimerEnabled = false 	-- Is the timer enabled?
	TimerCounter = 1024  	-- The number of cycles per timer incriment
	TimerCycles   = 0		-- The cycle counter for timers, resets every timer incriment.
	TimerDB = { [0] = 1024, 16, 64, 256 } -- Cheaper than an elseif stack
	TimerBase = 0 			-- The timer base, when timer overflows it resets itself to this.
	Timer = 0			-- The timer itself
	
	-- Divider Timer (Incriments every 256 cycles, no interupt)
	DividerCycles = 0 		-- The cycle counter for the Didiver, resets every timer incriment
	Divider = 0			-- Easier to store it in a variable than in memory. 


end





-- Timers
MRead[ 0xFF04 ] = function( Addr ) return Divider end -- Divider
MRead[ 0xFF05 ] = function( Addr ) return Timer end -- Timer
MRead[ 0xFF06 ] = function( Addr ) return TimerBase end -- What the timer resets to
MRead[ 0xFF07 ] = function( Addr ) return IO[ 0xFF07 ] end -- Timer control register, only return first 3 bits?

MWrite[ 0xFF04 ] = function( Addr, Data ) Divider = 0 end -- Divider reset to 0 when written to
MWrite[ 0xFF05 ] = function( Addr, Data ) Timer = Data end -- Set timer
MWrite[ 0xFF06 ] = function( Addr, Data ) TimerBase = Data end -- Set timer base
MWrite[ 0xFF07 ] = function( Addr, Data )
	IO[ 0xFF07 ] = band(Data, 5)
	TimerCounter = TimerDB[ band(Data , 0x3)] -- Set the timer incriment rate to the first 2 bits with a lookup DB
	TimerEnabled = band(Data , 0x4) == 0x4 -- 3rd byte enables/disables the timer
end








function UpdateTimers()
	DividerCycles = DividerCycles + Cycle
	if DividerCycles > 255 then
		Divider = band ( (Divider + 1) , 0xFF )
		DividerCycles = DividerCycles - 256
	end


	if TimerEnabled then -- if the timer is enabled
		TimerCycles = TimerCycles + Cycle -- incriment the cycles until next timer inc
		if TimerCycles > TimerCounter then -- if they overflow, then reset the timer cycles and incriment the timer
			Timer = Timer +1
			TimerCycles = TimerCycles - TimerCounter
			if Timer > 255 then -- if the timer overflows, reset the timer and do the timer interupt. 
				Timer = TimerBase
				IF = bor( IF, 4 )
			end
		end
	end
end

