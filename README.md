mcgb, a hacky gameboy emulator for ComputerCraft
================================================

Credit
======
I took [this](https://love2d.org/forums/viewtopic.php?f=5&t=8834) emulator and 
patched it to work with ComputerCraft. Unfortunately, this version has an average
framerate of about 3 seconds per frame, which is literally unplayable.


Building:
=========
On a mac or linux machine, running build.sh in the development directory will
concatenate all the lua files together to produce mcgb.

Otherwise, just use the preassembled mcgb file.

Usage
======
Requires Minecraft 1.8 and at least ComputerCraft 1.74.
It's not very user friendly. The input method was to use a Command Computer
and have it poll block states at relative coords defined in config.lua.
Get the mcgb file and a rom into a Command Computer (may require tweaking configs 
so the computers can hold files of the rom size) and running
```mcgb /path/to/rom.gb``` should run it on two full size Advanced Monitors connected by
wire cables.

What works
==========
Execution, albeit very slowly.

What doesn't work
=================
Input. Not at all. Too slow.

No save file system

No sound (this is Minecraft)

Invalid paths to roms will produce a cryptic error about trying to call a function of nil.

What could be done
==================
Make it faster.

Write a proper input system.

(Somehow get sound working???)
