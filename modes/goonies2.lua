-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- This file is available under Creative Commons CC0

local spec = {
	guid = "61d0d1e0-5331-40dd-b2e0-ad8aa912ea53",
	format = "1.2",
	name = "Goonies II",
	match = {"stringtest", addr=0xffe9, value="GOONIES"},
	--running = {"test", addr = 0x6c, lte = 0xfe}, TODO
	sync = {},
	custom = {},
}

-- Keys
spec.sync[0x500] = {kind="delta", deltaMin=0}
-- Bombs
spec.sync[0x501] = {kind="delta", deltaMin=0}
-- Molotov Cocktails
spec.sync[0x502] = {kind="delta", deltaMin=0}
-- Health
spec.sync[0x503] = {kind="delta", deltaMin=0}

-- Items
spec.sync[0x509] = {kind="bitOr"}
spec.sync[0x50a] = {kind="bitOr"}
-- Weapons
spec.sync[0x50b] = {kind="bitOr"}

-- Rescued Goonies
spec.sync[0x50d] = {kind="bitOr"}

-- Slingshot Ammo
spec.sync[0x50e] = {kind="delta", deltaMin=0}

return spec
