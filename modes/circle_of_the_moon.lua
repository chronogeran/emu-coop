-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- This file is available under Creative Commons CC0

local spec = {
	guid = "d82a8f4e-ec7e-45b8-80dd-3d06ff8f7ad8",
	format = "1.2",
	name = "Castlevania: Circle of the Moon",
	match = {"stringtest", addr=0x080000a0, value="DRACULA AGB1"},
	--running = {"test", addr = 0x020f703c, size=4, gte = 1}, -- Using game clock as running test
	sync = {},
	custom = {},
}

-- Flags
-- RC
for i=0,0x84,4 do
	spec.sync[0x02025370 + i] = {kind="bitOr", size=4}
end

-- Visit flags (one area per byte)
-- RC
for i=0,0x10,4 do
	spec.sync[0x02025400 + i] = {kind="bitOr", size=4}
end

-- Rooms explored
-- TODO Delta presents a problem if you explore same room at same time, but plain has the problem if you explore different rooms
-- Maybe drive from map data
spec.sync[0x02025414] = {kind="delta", size=2}

-- Map
for i=0,0x134,4 do
	spec.sync[0x02025430 + i] = {kind="bitOr", size=4}
end

-- HP
--spec.sync[0x0202562e] = {kind="delta", size=2}
-- MP
--spec.sync[0x02025636] = {kind="delta", size=2}
-- Hearts
--spec.sync[0x0202563c] = {kind="delta", size=2}
-- Subweapon
--spec.sync[0x02025640] = {}

-- EXP
spec.sync[0x02025668] = {kind="delta", size=4}

-- Cards
for i=0,0x10,4 do
	spec.sync[0x02025674 + i] = {kind="bitOr", size=4}
end

-- Inventory
for i=0,0x34,4 do
	spec.sync[0x020256ed + i] = {kind="delta", size=4}
end

-- TODO verify that this updates actual maxes
-- Max Hearts ups used
spec.sync[0x0202572c] = {kind="delta"}
-- Max HP ups used
spec.sync[0x0202572d] = {kind="delta"}
-- Max MP ups used
spec.sync[0x0202572e] = {kind="delta"}

-- Relics
spec.sync[0x0202572f] = {kind="bitOr", size=4}
spec.sync[0x02025733] = {kind="bitOr", size=4}

return spec