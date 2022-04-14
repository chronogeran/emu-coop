This is the source code repo for emu-coop. **[Probably you would rather be looking at the project webpage](https://mcclure.github.io/emu-coop/), which has more detail and a downloadable SNES emulator for Windows.**

# emu-coop

This directory contains some Lua scripts that, when loaded by a compliant emulator such as snes9x-rr or FCEUX, can synchronize emulator state over the internet (allowing "cooperative" playthroughs of single-player games).

Each game you want to use this with requires a "mode" file in the modes/ directory. **WARNING: Modes are PROGRAMS, like a .exe file. Do not install a mode file unless it came from someone you know and trust.** 

To run, run coop.lua. To run with additional debug messages (more verbose errors, and visibility for every message sent) run debug.lua instead.

## Supported Emulators

**Imporant: This is built to run with a fork of BizHawk. [Download it here.](https://github.com/chronogeran/BizHawk)**

Please note that not every core in BizHawk is supported. Use the indicated core when playing the given console.

Currently supported emulators/consoles:
* BizHawk
	* NES: NesHawk
	* DS: melonDS
	* PSX: Octoshock
* FCEUXWin32 (NES)
* snes9x-rr (SNES)

## Supported Games

* Crystalis (NES)
* Castlevania II: Simon's Quest (NES)
* The Legend of Zelda (NES)
* Solar Jetman (NES)
* The Legend of Zelda: A Link to the Past (SNES)
* Link to the Past Randomizer (SNES)
* Super Metroid (SNES)
* Castlevania: Symphony of the Night (PSX)
* Castlevania: Dawn of Sorrow (DS)
* Castlevania: Portrait of Ruin (DS)
* Castlevania: Order of Ecclesia (DS)

Contributions adding more games are welcome. Any game with a good degree of non-linearity or backtracking will work.

## See Also

Other similar projects providing access to multiplayer modes:
* http://multitroid.com/
* https://github.com/milesthenerd/bizhawk-co-op-metroid-fusion
* https://github.com/milesthenerd/AM2R-Multitroid

## Author / License

This is Chronogeran's fork of emu-coop. The original was written by
<<andi.m.mcclure@gmail.com>>. The "tloz_" modes (Zelda 1) were written by megmacAttack.

Big thanks to:
* The LTTP Randomizer team, esp. Mike Trethewey, Zarby89 and Karkat, for information
* Alex Zandra, Maya Shinohara, and Andypro1 from github for help testing

Unless otherwise noted, the license is:

	Copyright (C) 2017 Andi McClure

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
	ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
	TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
	PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT
	SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
	ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
	ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
	OR OTHER DEALINGS IN THE SOFTWARE.

Included in this directory is Penlight. Here is its license:

	Copyright (C) 2009-2016 Steve Donovan, David Manura.

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
	ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
	TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
	PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT
	SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
	ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
	ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
	OR OTHER DEALINGS IN THE SOFTWARE.

Included in this directory is Luasocket. Here is its license:

	LuaSocket 3.0 license
	Copyright © 2004-2013 Diego Nehab

	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the "Software"),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.

Included in this directory is IUP. Here is its license:

	Copyright (c) 1994-2017 Tecgraf/PUC-Rio.

	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the "Software"),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
