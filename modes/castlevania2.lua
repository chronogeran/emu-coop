-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- This file is available under Creative Commons CC0

local spec = {
	guid = "d65a9917-b53c-4217-ab50-41122d58d58a",
	format = "1.2",
	name = "Castlevania II: Simon's Quest",
	pipe = "tcp",
	match = {"stringtest", addr=0xffe9, value="CASTLE2"},
	--running = {"test", addr = 0x6c, lte = 0xfe}, todo
	sync = {},
	custom = {},
}

-- EXP
spec.sync[0x46] = {}
spec.sync[0x47] = {}
-- Hearts
spec.sync[0x48] = {}
spec.sync[0x49] = {}
-- Weapons
spec.sync[0x4a] = {}
-- Laurels
spec.sync[0x4c] = {}
-- Garlic
spec.sync[0x4d] = {}

-- Life
spec.sync[0x80] = {}
-- Max Life
spec.sync[0x81] = {}

-- Level
spec.sync[0x8b] = {}

-- Items
spec.sync[0x91] = {}
spec.sync[0x92] = {kind="bitOr"}

-- Whip
spec.sync[0x434] = {}

return spec
