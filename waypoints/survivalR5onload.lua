-- R5Version 2.74

setExecutionPath(getExecutionPath().."/..")

bizarremechanism = 101489
guardianrockspirit = GetIdName(101269)
guardian = GetIdName(101270)
guardiandefender = GetIdName(101637)
guardianswordsman = GetIdName(101271)
franticcliffdemon = GetIdName(101272)
brownwoodenchest = 111956
smallbomb = 101486
mediumbomb = 101487
largebomb = 101488
treasuretile = GetIdName(111811)
joker = GetIdName(111814)

logentry = nil
numshells = getCurrency("shell")

function checkRelog()

	if logentry == "Ran out of time" and LastTileDug then
		if LastTileDug > 36 then LastTileDug = 36 end
		logentry = logentry .. string.format(" with %d tiles remaining.", 36 - LastTileDug)
	else
		logentry = logentry .. "."
	end

	-- Log result
	local filename = getExecutionPath() .. "/logs/survival.log";
	local file, err = io.open(filename, "a+");
	if file then
		file:write("Acc: "..RoMScript("GetAccountName()").."\tName: " ..string.format("%-10s",player.Name ).." \tDate: " .. os.date() ..
		" \tShells gained/total: "..getCurrency("shell") - numshells.."/".. getCurrency("shell").. "\t" ..logentry .. "\n")
		file:close();
	end

	if When_Finished == "relog" then
		ChangeChar()
		waitForLoadingScreen();
		yrest(3000)
		loadProfile()
		loadPaths(__WPL.FileName);
	elseif When_Finished == "charlist" then
		SetCharList(CharList)
		LoginNextChar()
		loadProfile()
		loadPaths(__WPL.FileName);
	elseif When_Finished == "end" then
		error("Ending script",2)
	else
		loadProfile() -- Because we messed with skills
		loadPaths(When_Finished)
	end
end

--=== Function to sort tables, at angle ===--
local function SEsize(_x, _z)
   local X1 = 2622.1403808594
   local Z1 = 2900.1105957031
   local X2 = 2471.7895507813
   local Z2 = 2954.833984375

   return math.floor(((_x-X1)*(Z2-Z1)-(X2-X1)*(_z-Z1))/math.sqrt((X2-X1)^2 + (Z2-Z1)^2) + 0.5)
end

local function NEsize(_x, _z)
   local X1 = 2471.7895507813
   local Z1 = 2954.833984375
   local X2 = 2526.5126953125
   local Z2 = 3105.1848144531

   return math.floor(((_x-X1)*(Z2-Z1)-(X2-X1)*(_z-Z1))/math.sqrt((X2-X1)^2 + (Z2-Z1)^2) + 0.5)
end

function addToNE(_x, _z, _s)
   return _x + (_s * 0.9397), _z - (_s * 0.3420)
end

function addToSE(_x, _z, _s)
   return _x + (_s * 0.3420), _z + (_s * 0.9397)
end

function GetAttackPosition(_x, _z)
   local SEvalue = SEsize(_x, _z)
   local NEvalue = NEsize(_x, _z)

	if 1 > SEvalue then -- nw edge
		_x, _z = addToSE(_x, _z, - attackdistance)
	elseif SEvalue > 159 then -- se edge
		_x, _z = addToSE(_x, _z, attackdistance)
	end

	if 1 > NEvalue then -- sw edge
		_x, _z = addToNE(_x, _z, - attackdistance)
	elseif NEvalue > 159 then -- ne edge
		_x, _z = addToNE(_x, _z, attackdistance)
	end

	return _x, _z
end

local tiles
--=== Create table of tiles ===--
function createTileTable()
	repeat
		tiles = {}

		local objectList = CObjectList();
		objectList:update();
		local objSize = objectList:size()

		for i = 0,objSize do
			local obj = objectList:getObject(i);
			if obj.Id == 111811 or obj.Id == 111812 then
				table.insert(tiles, table.copy(obj))
			end
		end

		-- sort by address
		local function addresssortfunc(a,b)
			return a.Address > b.Address
		end
		table.sort(tiles, addresssortfunc)

		-- check for duplicate addresses
		for i = #tiles - 1, 1, -1 do
			if tiles[i].Address == tiles[i+1].Address then
				print("Diplicate found. Removing.\a")
				table.remove(tiles,i)
			end
		end

		if #tiles ~= 36 then
			printf("#tiles = "..#tiles..". Redoing table.\n")
			yrest(500)
		end
	until #tiles == 36

	-- Sort function
	local function sortfunc(a,b)
		if SEsize(a.X,a.Z) == SEsize(b.X,b.Z) then
			return NEsize(b.X,b.Z) > NEsize(a.X,a.Z)
		else
			return SEsize(b.X,b.Z) > SEsize(a.X,a.Z)
		end
	end

   -- Sort tiles
   table.sort(tiles, sortfunc)
end

--=== look for indicator that the tile is clickable ===--
function clicktile(address)
	local tmp = memoryReadRepeat("int", getProc(), address + addresses.game_root.pawn.attackable_flags) or 0;
	if bitAnd(tmp,0x8) then
		return true
	else
		return false
	end
end

--=== look for indicator that the chest has loot ===--
function clickchest(address)
	local chest = memoryReadRepeat("byte", getProc(), address + addresses.game_root.pawn.lootable_flags + 0x07) or 0
	if chest ~= 0 then
		return true
	else
		return false
	end
end

--=== custom fight function ===--
function myfight(target)
	target = CPawn(target.Address)

	-- Kill any aggro mobs before going back to target
	player:update()
	if player.Battling then
		repeat
			yrest(50)
			local _enemy = findaggroenemy()
			if _enemy then
				player:target(_enemy);
				player:fight()
			end
		until _enemy == nil or player.HP < 1 or player.Alive == false
	end

	-- Attack target
	target:update()
	player:aimAt(target)
	while target.Id ~= 0 and target.HP > 4 and target:isAlive() do
		yrest(50)
		player:target(target)
		if aoefound == false and (player.Class1 == CLASS_WARRIOR or player.Class1 == CLASS_CHAMPION) then Attack() end
		-- Check skills
		for i,v in pairs(settings.profile.skills) do
			if v.AutoUse and v:canUse(false, target) and
			   (v.Type == STYPE_DOT or v.Type == STYPE_DAMAGE) and
			   AllowSkillCastTime >= v.CastTime then
				local oldHP = target.HP -- Remember HP for extra check
				player:cast(v) -- Cast attack skill
				repeat yrest(50) player:update() until not player.Casting
				player:checkSkills(true) -- Friendly skills only.
				-- Wait a bit of time for damage to register, avoids casting another skill needlessly.
				local starttime = os.clock()
				yrest(150)
				repeat
					yrest(50)
					target:update()
				until target.Id == 0 or 5 > target.HP or target.HP < oldHP or aoefound or (os.clock()-starttime) >= 1
				-- End checking skills if target dead or if using AOE
				local damage = memoryReadInt(getProc(), target.Address + addresses.game_root.pawn.hp--[[0x1D0]])
				if target.Id == 0 or 5 > target.HP or damage == oldHP or aoefound then
					break
				end
			end
		end
		target:update()
		player:update()
		-- player dead?
		if (player.HP < 1 or player.Alive == false) then break end
		player:checkPotions()
	end
	player:resetSkills()
end

local function evalfunc(addr)
	local pawn = CPawn(addr)
	if pawn.HP > 4 and pawn:isAlive() then
		if aoefound then
			return attackrange > distance(player.X, player.Z, pawn.X, pawn.Z)
		else
			return attackdistance*1.5 > distance(player.X, player.Z, pawn.X, pawn.Z)
		end
	end
end

--=== First mobs to kill ===--
function trashmelee()
	cprintf(cli.yellow,"Clearing trash...\n")
	while (player:findNearestNameOrId({bizarremechanism,guardianrockspirit},nil,function(addr) local pawn = CPawn(addr) return pawn.HP > 4 and pawn:isAlive() end)) do
		for i = 1,#orderlist do
			if not RoMScript("TimeKeeperFrame:IsVisible()") then
				return
			end
			local tile = tiles[orderlist[i]]
			fly()
			local x,z = GetAttackPosition(tile.X,tile.Z)
			teleport(x, z, 18)
			if distance(player.X, player.Z, x, z) > 5 then
				player:moveTo(CWaypoint(x,z,18),true)
			end

			repeat
				player.X = x
				player.Z = z
				local trash = player:findNearestNameOrId(bizarremechanism, nil, evalfunc)
				if trash then
					player:target(trash)
					myfight(trash)
					player:clearTarget();
				end
			until trash == nil or player.HP < 1 or player.Alive == false

			repeat
				local spawn = player:findNearestNameOrId(guardianrockspirit, nil, evalfunc)
				if spawn then
					player:target(spawn)
					myfight(spawn)
					player:clearTarget();
				end
			until spawn == nil or player.HP < 1 or player.Alive == false
			if (player.HP < 1 or player.Alive == false) then
				logentry = "Player died."
				return
			end
		end
	end
	breaktiles()
end

--=== Start of tiles function ===--
function breaktiles()
	cprintf(cli.yellow,"Digging up tiles...\n")
	if aoefound then
		aoeskill.AutoUse = false
	end
	--=== First run of tiles ===--
	orderlist = {6,24,5,23,4,22,3,21,2,20,1,19,16,36,18,35,17,34,15,33,14,32,13,31,28,12,30,11,29,10,27,9,26,8,25,7}
	for i = 1,#orderlist do
		local tile = tiles[orderlist[i]]
		player:checkPotions()

		-- Dig tile
		local threshold = 120
		if clicktile(tile.Address) == true then
			repeat
				if not RoMScript("TimeKeeperFrame:IsVisible()") then
					return
				end

				fly()
				if player.X > tile.X+10 or tile.X-10 > player.X or player.Z > tile.Z+10 or tile.Z-10 > player.Z then
					teleport_SetStepSize(threshold)
					teleport(tile.X+1,tile.Z+1,18)
					threshold = threshold/2
				end
				player:update()

				if player.Battling then
					repeat
						local _enemy = findaggroenemy()
						if _enemy then
							player:target(_enemy);
							player:fight()
						end
					until _enemy == nil or player.HP < 1 or player.Alive == false
				end

				if (player.HP < 1 or player.Alive == false) then
					logentry = "Player died."
					return
				end

				player:target(tile); yrest(200)
				Attack() yrest(500)
				repeat
					yrest(50)
					player:update()
				until player.Casting == false
			until clicktile(tile.Address) == false
			LastTileDug = i

			yrest(500);

			-- see what's there
			local starttime = os.clock()
			repeat
				local result = player:findNearestNameOrId({"^"..guardian.."$", guardiandefender,guardianswordsman,franticcliffdemon,brownwoodenchest,smallbomb,mediumbomb,largebomb})
				if result and 15 > distance(player.X,player.Z,result.X,result.Z) then
					result = CPawn(result.Address)
					printf("%s found. Id %d.\n", result.Name, result.Id)
					if result.Name == guardian or result.Name == guardiandefender or result.Name == guardianswordsman or result.Name == franticcliffdemon then
						player:target(result)
						flyoff()
						player:fight()
						if (player.HP < 1 or player.Alive == false) then
							logentry = "Player died."
							return
						end
						if result.Name == franticcliffdemon then
							yrest(500)
							result:update()
							if result.Lootable then
								player:target(result)
								yrest(100)
								Attack()
								yrest(2000)
							end
							-- one more time
							result:update()
							if result.Lootable then
								player:target(result)
								yrest(100)
								Attack()
								yrest(2000)
							end
						end
					elseif result.Id == brownwoodenchest then
						repeat
							player:target(result); yrest(200)
							Attack() yrest(1000)
							repeat
								yrest(50)
								player:update()
							until player.Casting == false
							yrest(100);
						until clickchest(result.Address) ~= true
					end
					break
				end
			until os.clock() - starttime > 2
		end
	end
	teleport(2563, 2923) -- tele away from possible bomb.
	teleport_SetStepSize(120)
	chests() -- double check for left over chests. There shouldn't be any
end

--=== Open chests ===--
function chests()
	local chest
	repeat
		chest = player:findNearestNameOrId(brownwoodenchest,nil,clickchest)
		if chest then
			if not RoMScript("TimeKeeperFrame:IsVisible()") then
				return
			end
			fly()
			teleport(chest.X+10,chest.Z+10,18)
			repeat
				player:target_Object(chest.Id, nil, nil, true);
			until clickchest(chest.Address) ~= true
		end
	until chest == nil
	local secondsleft
	repeat secondsleft = RoMScript("TimeKeeperFrame.startTime-GetTime()") yrest(100) until secondsleft
	local mm = string.format("%2s", math.floor(secondsleft/ 60))
	local ss = string.format("%02s", math.floor(math.fmod(secondsleft, 60)))
	printf("Succeeded at Survival with %s:%s remaining.\n",mm,ss)
	logentry = string.format("Succeeded with %s:%s remaining.",mm,ss)
end

--=== find enemys that have you targeted ===--
function findaggroenemy()
	local obj = nil
	local pawn = nil
	local objectList = CObjectList();
	objectList:update();

	for i = 0,objectList:size() do
		obj = objectList:getObject(i);
		if( obj ~= nil and obj.Type == PT_MONSTER) then
			pawn = CPawn(obj.Address)
			if pawn:isAlive() and pawn.HP > 4 and pawn.TargetPtr == player.Address then
				return pawn
			end
		end
	end
end

--=== Check skills and COMBAT_DISTANCE values
function checkskills()
	-- Needs to be minimum 50
	if settings.profile.options.COMBAT_DISTANCE < 50 then
		cprintf(cli.lightgray,"COMBAT_DISTANCE increased to 50.\n")
		settings.profile.options.COMBAT_DISTANCE = 50
	end

	-- If melee, set COMBAT_DISTANCE to 50
	if settings.profile.options.COMBAT_DISTANCE > 50 and
	   settings.profile.options.COMBAT_TYPE == "melee" and
	   player.Class2 ~= CLASS_SCOUT then
		settings.profile.options.COMBAT_DISTANCE = 50
	end

	-- Recheck skills for COMBAT_DISTANCE of usuable skills
	if settings.profile.options.COMBAT_DISTANCE > 50 then
		local highestrange = 50
		for k,s in pairs(settings.profile.skills) do
			if s.Available and (s.Type == STYPE_DAMAGE or s.Type == STYPE_DOT) and
				AllowSkillCastTime >= s.CastTime and s.Range > highestrange then
					highestrange = s.Range
			end
		end

		if settings.profile.options.COMBAT_DISTANCE > highestrange then
			cprintf(cli.lightgray,"COMBAT_DISTANCE reduced to %d\n",highestrange)
			settings.profile.options.COMBAT_DISTANCE = highestrange
		end
	end

	if settings.profile.options.COMBAT_DISTANCE > 60 then
		attackdistance = 50
		orderlist = {12, 30, 35, 32, 25, 7, 2, 5}
	else
		attackdistance = 25
		orderlist = {6, 12, 18, 24, 30, 36, 35, 34, 33, 32, 31, 25, 19, 13, 7, 1, 2, 3, 4, 5}
	end

	-- assume if user wants to use aoe it will be first attack skill
	-- find aoe skill
	aoefound = false
	firstskillpriority = nil
	player:update()
	for k,v in pairs(settings.profile.skills) do
		if v.Available and (v.Type == STYPE_DAMAGE or v.Type == STYPE_DOT) then
			if not firstskillpriority then firstskillpriority = v.priority end
			aoeskill = settings.profile.skills[k]
			for k,v in pairs(aoeskills) do
				if aoeskill.Name == v then
					cprintf(cli.yellow,"AOE skill found as first skill, %s\n",aoeskill.Name)
					aoefound = true
					aoeskill.AutoUse = true
					aoeskill.MobCount = 1
					aoeskill.maxuse = 0
					aoeskill.priority = firstskillpriority + 1
					if aoeskill.Range > settings.profile.options.COMBAT_DISTANCE then
						cprintf(cli.lightgray,"COMBAT_DISTANCE increased to %d.\n",aoeskill.Range)
						settings.profile.options.COMBAT_DISTANCE = aoeskill.Range
					end
					table.sort(settings.profile.skills, function(a,b) return a.priority > b.priority end)
					attackdistance = 35
					attackrange = 52
					orderlist = {12, 30, 35, 32, 25, 7, 2, 5}
					break
				end
			end

			if not aoefound then
				for k,v in pairs(aoeskillsbig) do
					if aoeskill.Name == v then
						cprintf(cli.yellow,"AOE skill found as first skill, %s\n",aoeskill.Name)
						aoefound = true
						aoeskill.AutoUse = true
						aoeskill.MobCount = 1
						aoeskill.priority = firstskillpriority + 1
						attackrange = aoeskill.Range
						if aoeskill.Range > settings.profile.options.COMBAT_DISTANCE then
							cprintf(cli.lightgray,"COMBAT_DISTANCE increased to %d.\n",aoeskill.Range)
							settings.profile.options.COMBAT_DISTANCE = aoeskill.Range
						end
						table.sort(settings.profile.skills, function(a,b) return a.priority > b.priority end)
						attackdistance = 35
						attackrange = 75
						orderlist = {18, 34, 19, 3,}
						break
					end
				end
			end
		end

		if aoefound == true then break end
	end
	settings.profile.options.COMBAT_STOP_DISTANCE = settings.profile.options.COMBAT_DISTANCE
end

local wp = __WPL.Waypoints[__WPL.CurrentWaypoint]
if distance(player.X,player.Z,wp.X,wp.Z) > 350 then
	print("Too far to run script.")
	logentry = "Too far to run script."
	checkRelog()
	return
end

--=== Table numbering system ===--
--[[
	1 7  13 19 25 31
	2 8  14 20 26 32
	3 9  15 21 27 33
	4 10 16 22 28 34
	5 11 17 23 29 35
	6 12 18 24 30 36
* -- entrance to room.
]]

--=== Turn off looting, wastes time ===--
settings.profile.options.LOOT = false
settings.profile.options.TARGET_LEVELDIF_ABOVE = "15" -- Need to try to kill anything in there or no point.
settings.profile.options.TARGET_LEVELDIF_BELOW = "100" -- trash is lvl 15 which people won't allow for in profile.
settings.profile.options.ANTI_KS = false
settings.profile.options.MAX_TARGET_DIST = 300        -- Or it wont attack trash mobs too far from the door.
teleport_SetStepSize(120)
