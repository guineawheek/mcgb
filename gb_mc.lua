argv = {...}
canvas = nil

modules = {
    "gmb_opcodes",
    "gmb_cb_opcodes",
    "gmb_memory",
    "gameboy",
    "gmb_gpu",
    "gmb_interupts",
    "gmb_timers",
    "gmb_joypad",
    "gmb_sound",
    "config",
}

for i = 1, #modules do
    -- crappy require replacement
    loadfile(modules..".lua")
end
function math.clamp(x, min, max)
    return x < min and min or (x > max and max or x)
end

function ccload()

    Options = {}
    Restart()

    ColourPalette = {}
    ColourPalette[3] = colors.black
    ColourPalette[2] = colors.gray
    ColourPalette[1] = colors.lightGrey
    ColourPalette[0] = colors.white
    loadfile
end

function startrom()
    if commands == nil then
        print("error: computer is not command-capable.")
        print("We need this to check input.")
        exit()
    end
    if #argv == 0 then
        print("usage: gbemu [rom]")
        exit()
    end
     Restart()
    LoadRom(argv)
    State = "emulate"
end

function run()
    ccload()
    startrom()
    canvas.clear()
    while 1 do
        os.sleep(1/20)
        UpdateKeys()
        Think()
    end
run()
