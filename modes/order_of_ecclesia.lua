-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- This file is available under Creative Commons CC0

local spec = {
	guid = "e3d39049-71a8-42f7-9675-ddf9715ba14e",
	format = "1.2",
	name = "Castlevania: Order of Ecclesia",
	pipe = "tcp",
	match = {"stringtest", addr=0x023ffa80, value="CASTLEVANIA3YR9E"},
	running = {"test", addr = 0x02100374, size=4, gte = 1}, -- Using game clock as running test
	sync = {},
	custom = {},
}

-- Map exploration
for i=0,0x168 do
	spec.sync[0x02100144 + i] = {kind="bitOr", receiveTrigger=function(value, previousValue)
	end}
end

-- TODO alignment
-- Glyphs
for i=0,0x31 do
	spec.sync[0x021003ea + i] = {size=1, mask=0xf, kind="delta", receiveTrigger=function (value, previousValue)
		-- Get guide data
		-- TODO test
		if previousValue == 0 then
			local val = memory.readbyte(0x021003ea + i)
			memory.writebyte(0x021003ea + i, OR(0x90, val))
		end
	end}
end
-- R Glyphs
for i=0,0x16 do
	spec.sync[0x02100421 + i] = {size=1, mask=0xf, kind="delta", receiveTrigger=function (value, previousValue)
		-- Get guide data
		-- TODO test
		if previousValue == 0 then
			local val = memory.readbyte(0x02100421 + i)
			memory.writebyte(0x02100421 + i, OR(0x90, val))
		end
	end}
end

-- Relics
for i=0,5 do
spec.sync[0x02100458 + i] = {size=1, mask=0xf,
	receiveTrigger=function (value, previousValue)
		-- Equip abilities when receiving them
		if value == 1 then
			memory.writebyte(0x02100458 + i, 0x91)
		end
	end
}
end

-- Bestiary: enemies defeated
for i=0,0xf do
	spec.sync[0x02100344 + i] = {kind="bitOr"}
end
-- Bestiary: Item 1 drop
for i=0,0xf do
	spec.sync[0x02100354 + i] = {kind="bitOr"}
end
-- Bestiary: Item 2 drop
for i=0,0xf do
	spec.sync[0x02100364 + i] = {kind="bitOr"}
end

-- TODO verify space/alignment
-- Area visit flags (for area name popup)
spec.sync[0x02100378] = {size=4, kind="bitOr"}
-- TODO verify event space/alignment
-- Events, item pickups (todo: don't know end range)
for i=0,0x7f do
	spec.sync[0x02100378 + i] = {kind="bitOr"}
end

-- TODO alignment
-- Item Inventory
for i=0,0xea do
	spec.sync[0x0210045e + i] = {size=1, mask=0xf, kind="delta", receiveTrigger=function (value, previousValue)
		-- Get guide data
		-- TODO test
		if previousValue == 0 then
			local val = memory.readbyte(0x0210045e + i)
			memory.writebyte(0x0210045e + i, OR(0x90, val))
		end
	end}
end

-- HP
--spec.sync[0x021002b4] = {size=2, kind="delta"}
-- Max HP
--spec.sync[0x021002b6] = {size=2}
-- MP
--spec.sync[0x021002b8] = {size=2, kind="delta"}
-- Max MP
--spec.sync[0x021002ba] = {size=2}
-- Hearts
--spec.sync[0x021002bc] = {size=2, kind="delta"}
-- Max Hearts
--spec.sync[0x021002be] = {size=2}

-- EXP
spec.sync[0x0210030c] = {size=4, kind="delta", deltaMin=0}
-- Gold
spec.sync[0x02100310] = {size=4, kind="delta", deltaMin=0}
-- Kills
spec.sync[0x021005e8] = {size=4, kind="delta", deltaMin=0}

return spec