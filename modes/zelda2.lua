-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- Data source: https://datacrystal.romhacking.net/wiki/Zelda_II:_The_Adventure_of_Link:RAM_map
-- This file is available under Creative Commons CC0

local spec = {
	guid = "32b20118-7cfb-4c7c-8968-ff26976af1f1",
	format = "1.2",
	name = "Zelda II: The Adventure of Link",
	pipe = "tcp",
	match = {"stringtest", addr=0xffe0, value="LEGEND OF ZELDA2"},
	--running = {"test", addr = 0x6c, lte = 0xfe}, TODO
	sync = {},
	custom = {},
}

-- Next Lvl EXP
spec.sync[0x770] = {size=2}

-- Magic
spec.sync[0x773] = {}
-- Health
spec.sync[0x774] = {}

-- EXP
spec.sync[0x775] = {size=2, kind="delta", deltaMin=0}

-- Attack LV
spec.sync[0x777] = {}
-- Magic LV
spec.sync[0x778] = {}
-- Life LV
spec.sync[0x779] = {}

-- Magic spells
-- Shield
spec.sync[0x77b] = {name="Shield"}
-- Jump
spec.sync[0x77c] = {name="Jump"}
-- Life
spec.sync[0x77d] = {name="Life"}
-- Fairy
spec.sync[0x77e] = {name="Fairy"}
-- Fire
spec.sync[0x77f] = {name="Fire"}
-- Reflect
spec.sync[0x780] = {name="Reflect"}
-- Spell
spec.sync[0x781] = {name="Spell"}
-- Thunder
spec.sync[0x782] = {name="Thunder"}

-- Magic Containers
spec.sync[0x783] = {}
-- Heart Containers
spec.sync[0x784] = {}

-- Items
-- Candle
spec.sync[0x785] = {name="Candle"}
-- Glove
spec.sync[0x786] = {name="Glove"}
-- Raft
spec.sync[0x787] = {name="Raft"}
-- Boots
spec.sync[0x788] = {name="Boots"}
-- Flute
spec.sync[0x789] = {name="Flute"}
-- Cross
spec.sync[0x78a] = {name="Cross"}
-- Hammer
spec.sync[0x78b] = {name="Hammer"}
-- Magic Key
spec.sync[0x78c] = {name="Magic Key"}

-- Keys
spec.sync[0x793] = {kind="delta", deltaMin=0}
-- Boss crystals
spec.sync[0x794] = {}
-- Attacks (up/down thrust)
spec.sync[0x796] = {king="bitOr"}

-- Other flags
for i=0,4 do
	spec.sync[0x798 + i] = {}
end

-- Death count
spec.sync[0x79f] = {kind="delta"}

return spec
