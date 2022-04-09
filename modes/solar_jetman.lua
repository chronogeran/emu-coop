-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- This file is available under Creative Commons CC0

local spec = {
	guid = "316df463-cac8-4894-acbd-0aede5921535",
	format = "1.2",
	name = "Solar Jetman",
	pipe = "tcp",
	match = function(valueOverride, sizeOverride)
		return (memory.readbyte(0xffaa) == 0x68
			and memory.readbyte(0xffab) == 0x40
			and memory.readbyte(0xffac) == 0x84
			and memory.readbyte(0xffad) == 0x72
			and memory.readbyte(0xffae) == 0x85
			and memory.readbyte(0xffaf) == 0x74)
	end,
	-- Use first object for running test. Usually fuel counter or wormhole
	running = {"test", addr = 0x513, gte = 0x01},
	sync = {},
	custom = {}
}

-- Map ID
local partnerMap = 0x00 -- Assume world 1 to start
spec.sync[0x3b] = {kind="trigger", receiveTrigger=function(value, previousValue)
	message("partner is on map " .. value)
	partnerMap = value
end}
local onSameMapAsPartner = function()
	return partnerMap == memory.readbyte(0x3b)
end

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

-- Persistent Enemies
for i = 0x460, 0x4b6 do
	spec.sync[i] = {cond=function(value, size)
		-- Only sync enemies if on same map
		return onSameMapAsPartner()
	end}
end

-- Persistent object IDs
for i = 0x513, 0x52c do
	spec.sync[i] = {cond=function(value, size)
		-- Only sync objects if on same map
		return onSameMapAsPartner()
	end}
end
-- Persistent object positions
for i = 0x52d, 0x594 do
	spec.sync[i] = {cond=function(value, size)
		-- Only sync objects if on same map
		return onSameMapAsPartner()
	end}
end

-- Local objects

local partnerLocalObjectTypes={} -- Not using this. Do I need to?
local partnerLocalObjectIndices={}
local ObjectTypeAddr = 0x322
local ObjectIndexAddr = 0x39e
local WorldObjectType = 0x0a
local ObjectXLowAddr = 0x20b
local ObjectXHighAddr = ObjectXLowAddr + 0x1f
local ObjectYLowAddr = ObjectXHighAddr + 0x3e
local ObjectYHighAddr = ObjectYLowAddr + 0x1f

local shouldSyncPersistentObject = function(offset)
	return onSameMapAsPartner() and memory.readbyte(ObjectTypeAddr + offset) == WorldObjectType
end

for i = ObjectTypeAddr, ObjectTypeAddr + 3 do
	spec.sync[i] = {kind=function(value, previousValue, receiving)
		local allow = false
		if receiving then
			-- Allow is always false on receive. We're just keeping track.
			if onSameMapAsPartner() then
				partnerLocalObjectTypes[i - ObjectTypeAddr] = value
			end
		else
			-- Only sync objects if on same map
			allow = value ~= previousValue and onSameMapAsPartner()
		end
		return allow, value
	end}
end
for i = ObjectIndexAddr, ObjectIndexAddr + 3 do
	spec.sync[i] = {kind=function(value, previousValue, receiving)
		local allow = false
		local offset = i - ObjectIndexAddr
		if receiving then
			if onSameMapAsPartner() then
				partnerLocalObjectIndices[offset] = value
			end
		else
			allow = shouldSyncPersistentObject(offset)
		end
		return allow, value
	end}
end

local syncObjectPosition = function(startAddress, endAddress)
	for i = startAddress, endAddress do
		spec.sync[i] = {kind=function(value, previousValue, receiving)
			local allow = false
			local offset = i - startAddress

			if receiving then
				-- Check map on both sides just to be safe
				if onSameMapAsPartner() then
					-- The same object may be loaded in two different indices
					-- So match them up
					local receivingObjectIndex = partnerLocalObjectIndices[offset]
					local localOffset = 0
					local found = false
					while (not found and localOffset <= 3)
					do
						if memory.readbyte(ObjectTypeAddr + localOffset) == WorldObjectType
							and memory.readbyte(ObjectIndexAddr + localOffset) == receivingObjectIndex then
							found = true
						else
							localOffset = localOffset + 1
						end
					end

					-- Custom write instead of allow true
					if found then
						memory.writebyte(startAddress + localOffset, value)
					end
				end
			else
				allow = shouldSyncPersistentObject(offset)
			end

			return allow, value
		end}
	end
end

syncObjectPosition(ObjectXLowAddr, ObjectXLowAddr + 3)
syncObjectPosition(ObjectXHighAddr, ObjectXHighAddr + 3)
syncObjectPosition(ObjectYLowAddr, ObjectYLowAddr + 3)
syncObjectPosition(ObjectYHighAddr, ObjectYHighAddr + 3)

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

-- Warp to ship on partner blast off

-- Listen for when we're blasting off
spec.sync[0x637] = {kind="trigger", receiveTrigger=function(value, previousValue)
	local blastOffMusic = 5
	if value == blastOffMusic and onSameMapAsPartner() then
		print("partner blast off; teleport to ship")
		-- teleport to mother ship
		local motherShipX = memory.readbyte(0x52d) + SHIFT(memory.readbyte(0x561), -8)
		local motherShipY = memory.readbyte(0x547) + SHIFT(memory.readbyte(0x57b), -8)
		local destinationX, destinationY = motherShipX - 3, motherShipY + 4
		memory.writebyte(0x200, AND(destinationX, 0xff))
		memory.writebyte(0x21f, AND(SHIFT(destinationX, 8), 0xff))
		memory.writebyte(0x25d, AND(destinationY, 0xff))
		memory.writebyte(0x27c, AND(SHIFT(destinationY, 8), 0xff))
	end
end}

return spec
