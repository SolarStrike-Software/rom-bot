--=== 								===--
--===    Original done by Tsutomu 	===--
--=== Version 1.3 patch 4.0.2.2436	===--
--=== 	  Updated by lisa & rv55	===--
--=== 	  Modified by Andre235		===--
--=== 								===--


-- Speed hack settings
percent_speed_increase    = 19 		-- Percent to increase speed. (19% is 'safe')
maintain_speed			= true		-- Keeps checking speed and keep at optimal.



function isSpeedFast()
	local baseSpeed = memoryReadFloat(getProc(), getBaseAddress(addresses.movement_speed.base));
	return getSpeed() > baseSpeed;
end

function getSpeed()
	local playerAddress = memoryReadIntPtr(getProc(), getBaseAddress(addresses.game_root.base), addresses.game_root.player.base) or 0;
	if playerAddress ~= 0 then
		return memoryReadFloat(getProc(), playerAddress + addresses.game_root.pawn.base_speed);
	end
end

function speed(_speed)
	-- Current base speed, includes buff effects.
	local baseSpeed = memoryReadFloat(getProc(), getBaseAddress(addresses.movement_speed.base));
	local playerAddress = memoryReadIntPtr(getProc(), getBaseAddress(addresses.game_root.base), addresses.game_root.player.base) or 0;
	
	if( playerAddress ~= 0 ) then
		local mountAddress = memoryReadInt(getProc(), playerAddress + addresses.game_root.pawn.mount_ptr) or 0;

		if _speed == false then
			_speed = baseSpeed;
		else
			_speed = baseSpeed * (1+percent_speed_increase/100);
		end
		
		-- Change the speed.
		memoryWriteFloat(getProc(), playerAddress + addresses.game_root.pawn.base_speed, _speed);
		if( mountAddress ) then
			memoryWriteFloat(getProc(), mountAddress + addresses.game_root.pawn.base_speed, _speed);
		end
	end
end
