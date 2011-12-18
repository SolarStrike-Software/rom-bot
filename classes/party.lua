include("pawn.lua");
include("player.lua");

function icontarget(address) -- looks for icon I on mobs
	local pawn = CPawn(address);
	local icon = pawn:GetPartyIcon()
	pawn:update()
	if icon == 1 then 
		return true
	end
end

function PartyTable()
		if _timexx == nil then
			_timexx = os.time()
		end
		partymemberpawn={}
		local partymemberName={}
		local partymemberObj={}

		table.insert(partymemberName,1, player.Name)  -- need to insert player name.
		table.insert(partymemberObj,1, player:findNearestNameOrId(player.Name))
		table.insert(partymemberpawn,1, CPawn(player.Address))
	for i = 1, 5 do
		if _firsttimes == nil then -- post party names when bot started
			if GetPartyMemberName(i) ~= nil then
				cprintf(cli.yellow,"Party member "..i.." has the name of ")
				cprintf(cli.red, GetPartyMemberName(i).."\n")
				_firsttimes = true
			end
		end
	
		if os.time() - _timexx >= 60  then --only post party names every 60 seconds
			if GetPartyMemberName(i) ~= nil then
				cprintf(cli.yellow,"Party member "..i.." has the name of ")
				cprintf(cli.red, GetPartyMemberName(i).."\n")
			_timexx = os.time()
			end
		end

		if GetPartyMemberName(i) then
			table.insert(partymemberName,i + 1, GetPartyMemberName(i))
			table.insert(partymemberObj,i + 1, player:findNearestNameOrId(partymemberName[i + 1]))
			if partymemberObj[i + 1] then
				table.insert(partymemberpawn,i + 1, CPawn(partymemberObj[i + 1].Address))
			end
		end
	end
end

function PartyHeals()
if settings.profile.options.HEAL_FIGHT ~= true then settings.profile.options.HEAL_FIGHT = false end
_timexx = os.time()
	while(true) do
		if memoryReadBytePtr(getProc(),addresses.loadingScreenPtr, addresses.loadingScreen_offset) ~= 0 then
			repeat
				printf("loading screen has appeared, waiting for it to end.\n")
				yrest(1000)
			until memoryReadBytePtr(getProc(),addresses.loadingScreenPtr, addresses.loadingScreen_offset) == 0
		end
		PartyTable()
		for i,v in ipairs(partymemberpawn) do
			player:target(partymemberpawn[i])
			player:update()
			partymemberpawn[i]:update()
			partymemberpawn[i]:updateBuffs()
			target = player:getTarget();
			if target.HP/target.MaxHP*100 > 10 then
			player:checkSkills(true);
			end
			if (not player.Battling) then 
				getNameFollow()
			end	
		end
		if settings.profile.options.HEALER_FIGHT ~= false then
			--=== Find mobs with I icon and kill them ===--
			player:target(player:findEnemy(nil,nil,icontarget,nil)) 
			if player:haveTarget() then
				player:fight();
			end
		end		
	end
 end

function PartyDPS()
	if settings.profile.options.PARTY ~= true then settings.profile.options.PARTY = false end
		
	while(true) do
		player:update();
		player:checkSkills(true);
		
		--=== Find mobs with I icon and kill them ===--
		player:target(player:findEnemy(nil,nil,icontarget,nil)) 
		if player:haveTarget() then
			player:fight();
		end
		
		--=== If in combat then defend yourself and party ===--
		if player.Battling then
		player:target(player:findEnemy(true,nil,nil,nil))
			if player:haveTarget() then
				player:fight();
			end
		end
		getNameFollow()
		local selficon = player:GetPartyIcon()
		
		--=== if self icon II then mount up and follow ===--
		if selficon == 2 then
			while not player.Mounted do
				player:mount()
			end
		end
		
		--=== If self icon III then just follow ===--
		if selficon == 3 then
			
		end
		
		--=== If self icon VI then logout, also errors MM after logging out ===--
		if selficon == 6 then
			sendMacro("Logout();"); 
		end		
	end
end			

function getNameFollow()
	while (true) do	
  		if ( settings.profile.options.PARTY_FOLLOW_NAME ) then
    	if GetPartyMemberName(1) == settings.profile.options.PARTY_FOLLOW_NAME  then RoMScript("FollowUnit('party1');"); break  end
		if GetPartyMemberName(2) == settings.profile.options.PARTY_FOLLOW_NAME  then RoMScript("FollowUnit('party2');"); break  end
		if GetPartyMemberName(3) == settings.profile.options.PARTY_FOLLOW_NAME  then RoMScript("FollowUnit('party3');"); break  end
		if GetPartyMemberName(4) == settings.profile.options.PARTY_FOLLOW_NAME  then RoMScript("FollowUnit('party4');"); break  end
		if GetPartyMemberName(5) == settings.profile.options.PARTY_FOLLOW_NAME  then RoMScript("FollowUnit('party5');"); break  end
		RoMScript("FollowUnit('party1');");
		else RoMScript("FollowUnit('party1');");		

		end
		break
	end
end

function checkparty(_dist)
	local _dist = _dist or 200
	PartyTable()
	local _go = true
	local partynum = RoMScript("GetNumPartyMembers()")
	if partynum == #partymemberpawn then
		for i = 2,#partymemberpawn do
			player:update()
			partymemberpawn[i]:update()
			if partymemberpawn[i].X ~= nil then 
				if distance(partymemberpawn[i].X,partymemberpawn[i].Z,player.X,player.Z) > _dist then
					_go = false
				end
			else
			_go = false
			end
		end
	else
		_go = false
	end
	return _go
end