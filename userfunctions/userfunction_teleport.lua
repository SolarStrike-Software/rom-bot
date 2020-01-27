-----------------------
--  teleport function
--   rock5's version
--
--   special thx to:
-- fobsaucej, duartedj
-----------------------

local VERSION = 2.1

local STEP_SIZE = 115 -- Actually 120 but set to 115 to give a bit of a buffer.
local STEP_PAUSE = 500 -- in ms

local gameroot = addresses.client_exe_module_start + addresses.game_root.base; -- old staticbase_char

function teleport_GetVersion()
	return VERSION
end

function teleport_SetStepSize(val)
	if val and type(val) == "number" then
		STEP_SIZE = val
	end
end

function teleport_SetStepPause(val)
	if val and type(val) == "number" then
		STEP_PAUSE = val
	end
end

function teleport(dX,dZ,dY, absolute)
	------------
	-- Usage:
	-- dX,dZ,dY are coordinates, absolute true or nil = abs coords, false = relative pos
	------------

	-- for backward compatibility. Accepts 2 coords.
	if type(dY) == "boolean" then
		absolute = dY
		dY = nil
	end

	if (not dX) and (not dZ) and (not dY) then
		printf("Must supply at least 1 coordinate");
		return;
	end

	player:update()
	local address  = memoryReadInt(getProc(), gameroot) + addresses.game_root.player.base
	local offsetX = { 0x4, 0xB0};
	local offsetZ = { 0x4, 0xB8};
	local offsetY = { 0x4, 0xB4};
	local pos = {player.X, player.Z, player.Y};


	if absolute == false then
		if dX == nil then dX = 0 end
		if dZ == nil then dZ = 0 end
		if dY == nil then dY = 0 end
		pos[1] = pos[1] + dX;
		pos[2] = pos[2] + dZ;
		pos[3] = pos[3] + dY;
	else
		if dX == nil then dX = pos[1] end
		if dZ == nil then dZ = pos[2] end
		if dY == nil then dY = pos[3] end
		pos = {dX,dZ,dY};
	end

	local totalDistance = distance(player.X, player.Z, player.Y,pos[1],pos[2],pos[3])
	if totalDistance > STEP_SIZE then
		-- incremental stes
		local steps = math.ceil(totalDistance/STEP_SIZE)
		local xStep = (pos[1] - player.X)/ steps
		local zStep = (pos[2] - player.Z)/ steps
		local yStep = (pos[3] - player.Y)/ steps
		for i = 1, steps - 1 do
			memoryWriteFloatPtr(getProc(), address , offsetX, player.X + xStep); -- x value
			memoryWriteFloatPtr(getProc(), address , offsetZ, player.Z + zStep); -- z value
			memoryWriteFloatPtr(getProc(), address , offsetY, player.Y + yStep); -- y value
			yrest(STEP_PAUSE)
			player:update()
		end
	end

	-- Take last or only step
	memoryWriteFloatPtr(getProc(), address , offsetX, pos[1]); -- x value
	memoryWriteFloatPtr(getProc(), address , offsetZ, pos[2]); -- z value
	memoryWriteFloatPtr(getProc(), address , offsetY, pos[3]); -- y value
	cprintf(cli.green,"Player Teleported to X: %d\tZ: %d\tY: %d\n",pos[1],pos[2],pos[3]);
	yrest(STEP_PAUSE)
	player:update();
end

function teleportToWP(index)
	-- Check arg
	if index == nil then
		-- Default "next waypoint"
		index = __WPL.CurrentWaypoint
	elseif type(index) == "string" then
		-- To tag
		index = __WPL:findWaypointTag(index)
		if index == 0 then
			print("Tag used in teleportToWP(), was not found.")
			return
		end
	elseif type(index) ~= "number" or index < 1 or index > #__WPL.Waypoints then
		-- Invalid index
		print("Invalid index number used in teleportToWP().")
		return
	end

	-- Make the next waypoint to move to, the one you are teleporting to.
	if index ~= __WPL.CurrentWaypoint then
		__WPL:setWaypointIndex(index)
	end

	local wp = __WPL.Waypoints[index]
	teleport(wp.X, wp.Z, wp.Y)
end
