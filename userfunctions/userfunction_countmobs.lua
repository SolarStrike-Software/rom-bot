-- CountMobs by Rock5
-- Version 0.4

function CountMobs(onlyaggro, inrange)
	local aggrocount = 0

	local objectList = CObjectList();
	objectList:update();
	for i = 0,objectList:size() do
		local obj = objectList:getObject(i);
		if obj ~= nil and obj.Type == PT_MONSTER and
		  (inrange == nil or inrange >= distance(player.X,player.Z,player.Y,obj.X,obj.Z,obj.Y) ) then
			local pawn = CPawn(obj.Address);
			if pawn.Alive and pawn.Attackable then
				if onlyaggro == true then
					if pawn.TargetPtr == player.Address then
						aggrocount = aggrocount + 1
					end
				else
					aggrocount = aggrocount + 1
				end
			end
		end
	end

	return aggrocount
end

function CountPlayers(inrange, printnames, ignoreFriends)
	local count = 0

	local objectList = CObjectList();
	objectList:update();
	for i = 0,objectList:size() do
		local obj = objectList:getObject(i);
		if obj ~= nil and obj.Type == PT_PLAYER and obj.Address ~= player.Address and obj.Name ~= "<UNKNOWN>" and
		  (inrange == nil or inrange >= distance(player.X,player.Z,player.Y,obj.X,obj.Z,obj.Y) ) then
			if ignoreFriends ~= true or CPawn(obj.Address):isFriend() == false then
				count = count + 1
				if printnames == true then printf(obj.Name.."\t") end
			end
		end
	end
	if printnames == true then printf("\n") end

	return count
end
