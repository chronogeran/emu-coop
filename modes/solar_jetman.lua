-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- Data source: https://datacrystal.romhacking.net/wiki/Crystalis:RAM_map
-- This file is available under Creative Commons CC0

local spec = {
	guid = "316df463-cac8-4894-acbd-0aede5921535",
	format = "1.2",
	name = "Solar Jetman",
	match = function(valueOverride, sizeOverride)
		return (memory.readbyte(0xffaa) == 0x68
			and memory.readbyte(0xffab) == 0x40
			and memory.readbyte(0xffac) == 0x84
			and memory.readbyte(0xffad) == 0x72
			and memory.readbyte(0xffae) == 0x85
			and memory.readbyte(0xffaf) == 0x74)
	end,
	--running = {"test", addr = 0x6c, lte = 0xfe},
	sync = {},
}

-- Map ID
local partnerMap = 0xff
spec.sync[0x3b] = {kind="trigger", receiveTrigger=function(value, previousValue)
	partnerMap = value
end}

-- Inventory
spec.sync[0x600] = {kind="delta", deltaMin=0, deltaMax=9, name="Homing Missles"}
spec.sync[0x601] = {kind="delta", deltaMin=0, deltaMax=9, name="Anti Gravity"}
spec.sync[0x602] = {kind="delta", deltaMin=0, deltaMax=9, name="Smart Bombs"}
spec.sync[0x603] = {kind="delta", deltaMin=0, deltaMax=9, name="Time Bombs"}
spec.sync[0x604] = {kind="delta", deltaMin=0, deltaMax=9, name="Star Bullets"}
spec.sync[0x605] = {kind="delta", deltaMin=0, deltaMax=9, name="Multi Warhead Missiles"}
spec.sync[0x606] = {kind="delta", deltaMin=0, deltaMax=9, name="Titanium Bullet Pack"}
spec.sync[0x607] = {kind="delta", deltaMin=0, deltaMax=9, name="Military Bullet System"}
spec.sync[0x608] = {kind="delta", deltaMin=0, deltaMax=9, name="Super Shields"}
spec.sync[0x609] = {kind="delta", deltaMin=0, deltaMax=9, name="Momentum Killer"}
spec.sync[0x60a] = {kind="delta", deltaMin=0, deltaMax=9, name="Efficient Engines"}
spec.sync[0x60b] = {kind="delta", deltaMin=0, deltaMax=9, name="Double Strength Thrusters"}
spec.sync[0x60c] = {kind="delta", deltaMin=0, deltaMax=9, name="Mapping Device"}
spec.sync[0x60d] = {kind="delta", deltaMin=0, deltaMax=9, name="Super Mapping Device"}

-- Money
-- It's in decimal so we can't do much for intelligent sync
for i = 0xcb, 0xd0 do
	spec.sync[i] = {}
end

-- Upgrades
-- Not using bitOr because when you upgrade from Nippon to Italian it clears a bit
spec.sync[0xdc] = {nameBitmap={
	[8]="Shields",
	[7]="Boosters",
	[2]="Italian Racing Jetpod",
	[1]="Nippon Sports Jetpod"
}}

-- Warpship Pieces
spec.sync[0xde] = {kind="bitOr", name="a piece of the Golden Warpship"}
-- need to support clearing bits at world 13
spec.sync[0xdf] = {name="a piece of the Golden Warpship"}

-- Enemies
for i = 0x460, 0x4b6 do
	spec.sync[i] = {cond=function(value, size)
		-- Only sync enemies if on same map
		return partnerMap == memory.readbyte(0x3b)
	end}
end

-- Objects in world: ID
for i = 0x513, 0x52c do
	spec.sync[i] = {cond=function(value, size)
		-- Only sync objects if on same map
		return partnerMap == memory.readbyte(0x3b)
	end}
end
-- Objects x position
for i = 0x200, 0x23e do
	local objIndex = i - 0x200
	-- Second half is high byte
	if objIndex >= 0x1f then objIndex = objIndex - 0x1f end
	spec.sync[i] = {kind=function(value, previousValue, receiving)
		local interactableIndex = memory.readbyte(0x393 + objIndex)
		local allow = memory.readbyte(0x513 + interactableIndex) ~= 0
		return allow, value
	end,
	cond=function(value, size)
		-- Only sync objects if on same map
		return partnerMap == memory.readbyte(0x3b)
	end}
end
-- Objects y position
for i = 0x25d, 0x29b do
	local objIndex = i - 0x5d
	-- Second half is high byte
	if objIndex >= 0x1f then objIndex = objIndex - 0x1f end
	spec.sync[i] = {kind=function(value, previousValue, receiving)
		local interactableIndex = memory.readbyte(0x393 + objIndex)
		local allow = memory.readbyte(0x513 + interactableIndex) ~= 0
		return allow, value
	end,
	cond=function(value, size)
		-- Only sync objects if on same map
		return partnerMap == memory.readbyte(0x3b)
	end}
end


-- When loading into other maps in the same world,
-- item collection and enemies defeated are saved for when
-- you return to that map

-- Saved object status
for i = 0x60e, 0x61f do
	spec.sync[i] = {}
end

-- Saved enemy status
for i = 0x626, 0x632 do
	spec.sync[i] = {}
end

return spec
