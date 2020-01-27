--=== 								===--
--===    Original done by Tsutomu 	===--
--=== Version 1.3 patch 4.0.2.2436	===--
--=== 	  Updated by lisa & rv55	===--
--=== 	  Modified by Andre235		===--
--=== 								===--


-- Speed hack settings
percent_speed_increase    = 19 		-- Percent to increase speed. (19% is 'safe')
maintain_speed			= true		-- Keeps checking speed and keep at optimal.

local gameroot = addresses.client_exe_module_start + addresses.game_root.base;



function isSpeedFast()
	local baseSpeed = memoryReadFloat(getProc(), addresses.baseSpeedAddress + addresses.baseSpeedOffset)
	return getSpeed() > baseSpeed
end

function getSpeed()
	local playerAddress = memoryReadIntPtr(getProc(), gameroot, addresses.game_root.player.base) or 0
	if playerAddress ~= 0 then
		local mountaddress = memoryReadInt(getProc(), playerAddress + addresses.speedhack.mounted) or 0
		if mountaddress == 0 then
			return memoryReadFloat(getProc(), playerAddress + addresses.speedhack.pawn_speed)
		else
			return memoryReadFloat(getProc(), mountaddress + addresses.speedhack.pawn_speed)
		end
	end
end

function speed(_speed)
	-- Current base speed, includes buff effects.
	local baseSpeed = memoryReadFloat(getProc(), getBaseAddress(addresses.speedhack.speed.base) + addresses.speedhack.speed.offset)

	if _speed == false then
		_speed = baseSpeed
	else
		_speed = baseSpeed * (1+percent_speed_increase/100)
		print("set speed to:", _speed);
	end

	-- Change the speed.
	local playerAddress = memoryReadIntPtr(getProc(), gameroot, addresses.game_root.player.base) or 0
	if playerAddress ~= 0 then
		local mountaddress = memoryReadInt(getProc(), playerAddress + addresses.speedhack.mounted) or 0
		if mountaddress == 0 then
			memoryWriteFloat(getProc(), playerAddress + addresses.speedhack.pawn_speed, _speed)
		else
			memoryWriteFloat(getProc(), mountaddress + addresses.speedhack.pawn_speed, _speed)
		end
	end
end
