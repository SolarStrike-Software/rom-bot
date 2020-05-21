function checkclicked(address)
	local proc = getProc()
	local tmp = memoryReadRepeat("int", proc, address + addresses.game_root.pawn.attackable_flags) or 0;
	if bitAnd(tmp,0x8) then
		return memoryReadRepeat("float", proc, address + addresses.game_root.pawn.fading) == 0
	else
		return false
	end
end

function pawnevalfunc(address, pawn)
	if(checkclicked(address)== true and pawn.Alive and pawn.HP >=1 and pawn.Id ~= 106882)then
		return true
	else
		return false
	end
end
function myexlude(address, pawn)
	if(pawn.Id == 106882 or pawn.Id == 106884 )then
		return true
	else
		return false;
	end
end
function movetoBag()
	yrest(1000)
	inventory:update()
	for i = 61,240 do
		local item = inventory.BagSlot[i]
		if (not item.Empty) and item.Available and (item.Id == 202903 
			or item.Id == 202904 
			or item.Id == 202905 
			or item.Id == 202435 
			or item.Id == 202902 
			or item.Id == 203784
			or item.Id == 201139
			or item.Id == 201141
			or (item.Id >= 207743 and item.Id <= 207750)) then 
			cprintf(cli.yellow,"Placing %s in the itemshop backpack.\n",item.Name)
			item:moveTo("itemshop")
			yrest(1000)
		end
	end
end
function exchange()
	inventory:update()
	while(inventory:itemTotalCount(241648) > 0 and inventory:itemTotalCount(241647) > 0) do
		repeat
			yrest(100)
		until player:target_NPC(121035)
		sendMacro("ChoiceOption(2);");
		yrest(500);
		inventory:update()
	end
end
function exitroom(ExchangeKeys, MovetoItemBag)
	repeat	
		RoMScript("CloseWindows()");
		yrest(50)
		RoMScript("CloseWindows()");
		repeat
			RoMScript("CloseWindows()");
			yrest(100)
		until player:target_NPC(120687);
		sendMacro("ChoiceOption(1);");
		yrest(500);
		if(RoMScriptNoCheck ~= nil)then
			yrest(100);
			info =  RoMScriptNoCheck("StaticPopup_OnClick(StaticPopup1, 1);");
		else
			RoMScript("StaticPopup_OnClick(StaticPopup1, 1);")
		end
	until waitForLoadingScreen(10) 
	RoMScript("CloseWindows()");
	yrest(500)
	if( ExchangeKeys == true)then
		exchange()
	end
	if(MovetoItemBag == true)then
		movetoBag();
	end
end
function CPawn:findBestClickPoint(aoerange, skillrange, onlyaggro, evalFunc, excludeFunc)
	-- Finds best place to click to get most mobs including this pawn.
	self:updateXYZ()

	player:updateXYZ()
	local MobList = {}
	local EPList = {}
	
    if( type(evalFunc) ~= "function" ) then
		--default func
		evalFunc = function (address,pawn)
         	if pawn.Alive and pawn.HP >=1 and pawn.Attackable and pawn.Level > 1 then
				return true
			else
			    return false
			end
		end;
	end
	if( type(excludeFunc) ~= "function" ) then
		--default func
		excludeFunc = function (address,pawn)
         	return false;
		end;
	end
	local function CountMobsInRangeOfCoords(x,z)
		local c = 0
		local exclude = false;
		local excludeList = false;
		local included = false;
		local list = {}
		for k,mob in ipairs(MobList) do
			if distance(x,z,mob.X,mob.Z) <= aoerange then
				if(excludeFunc(mob.Address,mob))then
					exclude = true;
				end
				table.insert(list,k)
				c=c+1
			end
		end
		if(exclude == true)then
			return 0, list;
		else
			return c, list;	
		end
	end


	local function GetEquidistantPoints(p1, p2, dist)
		-- Returns the 2 points that are both 'dist' away from both p1 and p2
		local xvec = p2.X - p1.X
		local zvec = p2.Z - p1.Z
		local ratio = math.sqrt(dist*dist/(xvec*xvec +zvec*zvec) - 0.25)
		-- transpose
		local newxvec = zvec * ratio
		local newzvec = xvec * ratio

		local ep1 = {X = (p1.X + p2.X)/2 + newxvec, Z = (p1.Z + p2.Z)/2 - newzvec}
		local ep2 = {X = (p1.X + p2.X)/2 - newxvec, Z = (p1.Z + p2.Z)/2 + newzvec}

		return ep1, ep2
	end

	-- The value this function needs to beat or match (if aoe center is this pawn)
	local countmobs = self:countMobs(aoerange, onlyaggro)

	-- Check if user wants to bypass this function
	-- Blubblab:c I'dont need that
--	if settings.profile.options.FORCE_BETTER_AOE_TARGETING == false then
--		return countmobs, self.X, self.Z
--	end

	-- First get list of mobs within (2 x aoerange) of this pawn and (skillrange + aoerange) from player.
	local objectList = CObjectList();
	objectList:update();
	for i = 0,objectList:size() do
		local obj = objectList:getObject(i);
		if obj ~= nil and obj.Type == PT_MONSTER and (settings.profile.options.AOE_TARGETING_IGNORE_ALTITUDE or 0.5 > math.abs(obj.Y - self.Y)) and -- only count mobs on flat floor, results would be unpredictable on hilly surfaces when clicking.
		  aoerange*2 >= distance(self.X,self.Z,self.Y,obj.X,obj.Z,obj.Y) and (skillrange + aoerange >= distance(player.X, player.Z, obj.X, obj.Z)) then
			local pawn = CPawn.new(obj.Address);
			pawn:updateAlive()
			pawn:updateHP()
			pawn:updateAttackable()
			pawn:updateLevel()
			pawn:updateXYZ() -- For the rest of the function
			 if evalFunc(pawn.Address,pawn)== true then
				if onlyaggro == true then
					pawn:updateTargetPtr()
					if pawn.TargetPtr == player.Address then
						table.insert(MobList,pawn)
					end
				else
					table.insert(MobList,pawn)
				end
			end
		end
	end

	-- Deal with easy solutions
	if countmobs > #MobList or #MobList < 2 then
		return countmobs, self.X, self.Z
	elseif #MobList == 2 then
		local averageX = (MobList[1].X + MobList[2].X)/2
		local averageZ = (MobList[1].Z + MobList[2].Z)/2
		return 2, averageX, averageZ
	end

	-- Get list of best equidistant points(EPs) and add list of mobs in range for each point
	local bestscore = 0
	for p1 = 1, #MobList-1 do
		local mob1 = MobList[p1]
		for p2 = p1+1, #MobList do
			local mob2 = MobList[p2]
			local ep1, ep2 = GetEquidistantPoints(mob1, mob2, aoerange - 3) -- '-1' buffer
			-- Check ep1 and add
			local dist = distance(player.X, player.Z, ep1.X, ep1.Z)
			if aoerange >= distance(ep1, self) or (settings.profile.options.FORCE_BETTER_AOE_TARGETING and dist < settings.profile.options.MAX_TARGET_DIST) then -- EP doesn't miss primary target(self)
				local tmpcount, tmplist = CountMobsInRangeOfCoords(ep1.X, ep1.Z)
				if tmpcount > bestscore then
					bestscore = tmpcount
					EPList = {} -- Reset for higher scoring EPs
				end
				if tmpcount == bestscore then
					ep1.Mobs = tmplist
					table.insert(EPList,ep1)
				end
			end
			local dist2 = distance(player.X, player.Z, ep2.X, ep2.Z)
			-- Check ep2 and add
			if aoerange > distance(ep2,self)  or (settings.profile.options.FORCE_BETTER_AOE_TARGETING and dist2 < settings.profile.options.MAX_TARGET_DIST)then -- EP doesn't miss primary target(self)
				local tmpcount, tmplist = CountMobsInRangeOfCoords(ep2.X, ep2.Z)
				if tmpcount > bestscore then
					bestscore = tmpcount
					EPList = {} -- Reset for higher scoring EPs
				end
				if tmpcount == bestscore then
					ep2.Mobs = tmplist
					table.insert(EPList,ep2)
				end
			end
		end
	end

	-- Is best score good enough to beat self:countMobs?
	if countmobs >= bestscore then
		return countmobs, self.X, self.Z
	end

	-- Sort EP mob lists for easy comparison
	for i = 1, #EPList do
		table.sort(EPList[i].Mobs)
	end

	-- Find a set of EPs with matching mob list to first
	local BestEPSet = {EPList[1]}
	for i = 2, #EPList do
		local match = true
		for k,v in ipairs(EPList[1].Mobs) do
			if v ~= EPList[i].Mobs[k] then
				match = false
				break
			end
		end
		-- Same points
		if match then
			table.insert(BestEPSet,EPList[i])
		end
	end

	-- Get average of EP points. That is our target point
	local totalx, totalz = 0, 0
	for k,v in ipairs(BestEPSet) do
		totalx = totalx + v.X
		totalz = totalz + v.Z
	end

	-- Average x,z
	local AverageX = totalx/#BestEPSet
	local AverageZ = totalz/#BestEPSet

	return bestscore, AverageX, AverageZ
end
function CPlayer:findListofNameOrId(_objtable, _ignore, evalFunc)
	if type(_objtable) == "number" or type(_objtable) == "string" then
		_objtable = {_objtable}
	end
	if type(_ignore) == "number" or type(_ignore) == "string" then
		_ignore = {_ignore}
	end
	local findList ={}
	local whichList ={}
	local testvar = 0;
	ignore = ignore or 0;
	local closestObject = nil;
	local obj = nil;
	local objectList = CObjectList();
	objectList:update();

	if( type(evalFunc) ~= "function" ) then
		evalFunc = function (unused) return true; end;
	end
	local function sortbyrange(obja, objb)
		if( distance(self.X, self.Z, self.Y, obja.X, obja.Z, obja.Y) <
			distance(self.X, self.Z, self.Y, objb.X, objb.Z, objb.Y) ) then
				return true;
		else
			return false;
		end
	end
	local function searchIgnoreList(obj)
		if(_ignore)then
			for __, _ignoreAdresse in pairs(_ignore) do
				if(obj.Adresse == _ignoreAdresse ) then
					return false
				end
			end
		end
		return true
	end
	self:updateXYZ()
	for __, _objnameorid in pairs(_objtable) do
		local tempList = {}
		local found = false;
		for i = 0,objectList:size() do
			obj = objectList:getObject(i);
			if( obj ~= nil ) then
				if( searchIgnoreList(obj) and obj.Address ~= player.Address and (obj.Id == tonumber(_objnameorid) or string.find(obj.Name, _objnameorid, 1, true) )) then
					if( evalFunc(obj.Address,obj) == true ) then
						table.insert(tempList,obj)
						if(whichList["".._objnameorid..""] ~= nil)then
							whichList["".._objnameorid..""] = whichList["".._objnameorid..""] + 1;
						else
							whichList["".._objnameorid..""] = 1;
						end
					end
				end
			end
		end
		table.sort(tempList,sortbyrange)
		table.insert(findList,tempList)
	end
	
   return whichList,findList;
end
function RoMScriptNoCheck(script)
	-- Check if in game
	if not isInGame() then
		-- Cannot execute RoMScript. Not in game.
		return
	end

	if commandMacro == 0 then
		-- setupMacros() hasn't run yet
		return
	else -- check if still valid
		local __, cName = readMacro(commandMacro)
		local __, rName = readMacro(resultMacro)
		if cName ~= COMMAND_MACRO_NAME or rName ~= RESULT_MACRO_NAME then -- macros moved
			setupMacros()
		end
	end

	--- Get the real offset of the address
	local macro_address = memoryReadUInt(getProc(), getBaseAddress(addresses.macro.base));

--	local scriptDef;

--	if( settings.options.LANGUAGE == "spanish" ) then
--		scriptDef = "/redactar";
--	else
--		scriptDef = "/script";
--	end

	--- Macro length is max 255, and after we add the return code,
	--- we are left with about 155 character limit.

	local dataPart = 0 -- The part of the data to get
	local raw = ""     -- Combined raw data from 'R'
	repeat
		local text

		-- The command macro
		if dataPart == 0 then
			-- The initial command macro
--			text = scriptDef.." R='' a={" .. script ..
--			"} for i=1,#a do R=R..tostring(a[i])" ..
--			"..'" .. string.char(9) .. "' end" ..
--			" EditMacro("..resultMacro..",'"..RESULT_MACRO_NAME.."',7,R)";
			text = script
		else
			-- command macro to get the rest of the data from 'R'
--			text = scriptDef.." EditMacro("..resultMacro..",'"..
--			RESULT_MACRO_NAME.."',7,string.sub(R,".. (1 + dataPart * 255) .."))";
			text = "SendMore"
		end

		-- Check to make sure length is within bounds
		local len = string.len(text);
		if( len > 254 ) then
			error("Macro text too long by "..(len - 254), 2);
		end

		repeat
			-- Write the command macro
			writeToMacro(commandMacro, text)

			-- Write something on the first address, to see when its over written
			memoryWriteByte(getProc(), macro_address + addresses.macro.size *(resultMacro - 1) + addresses.macro.content , 6);

			-- Execute it
			if( settings.profile.hotkeys.MACRO ) then
--				keyboardPress(settings.profile.hotkeys.MACRO.key);
				keyboardHold(settings.profile.hotkeys.MACRO.key);
				rest(100)
				keyboardRelease(settings.profile.hotkeys.MACRO.key);
			end

			local tryagain = false

			-- A cheap version of a Mutex... wait till it is "released"
			-- Use high-res timers to find out when to time-out
			local startWaitTime = getTime();
			while( memoryReadByte(getProc(), macro_address + addresses.macro.size *(resultMacro - 1) + addresses.macro.content) == 6 ) do
				if( deltaTime(getTime(), startWaitTime) > 800 ) then
					if settings.options.DEBUGGING then
						printf("0x%X\n", getBaseAddress(addresses.inputbox_base))
					end
					if memoryReadUInt(getProc(), getBaseAddress(addresses.inputbox_base)) == 0 then
						keyboardPress(settings.hotkeys.ESCAPE.key); yrest(500)
						if RoMScript("GameMenuFrame:IsVisible()") then
							-- Clear the game menu and reset editbox focus
							keyboardPress(settings.hotkeys.ESCAPE.key); yrest(300)
							RoMCode("z = GetKeyboardFocus(); if z then z:ClearFocus() end")
						end
					end


					tryagain = true
					break
				end;
				rest(1);
			end
		until tryagain == false

		--- Read the outcome from the result macro
		local rawPart = readMacro(resultMacro)

		raw = raw .. rawPart

		dataPart = dataPart + 1
	until string.len(rawPart) < 255

	readsz = "";
	ret = {};
	cnt = 0;
	for i = 1, string.len(raw), 1 do
		local byte = string.byte(raw, i);

		if( byte == 0 or byte == null) then -- Break on NULL terminator
			break;
		elseif( byte == 9 ) then -- Use TAB to seperate
			-- Implicit casting
			if( string.find(readsz, "^[%-%+]?%d+%.?%d+$") ) then readsz = tonumber(readsz);  end;
			if( string.find(readsz, "^[%-%+]?%d+$") ) then readsz = tonumber(readsz);  end;
			if( readsz == "true" ) then readsz = true; end;
			if( readsz == "false" ) then readsz = false; end;

			table.insert(ret, readsz);
			cnt = cnt+1;
			readsz = "";
		else
			readsz = readsz .. string.char(byte);
		end
	end

	local err = ret[1]
	if err == false then
	return -1;
		--error("IGF:".."\\"..script.."\\ "..ret[2],0)
	elseif err == true then
		table.remove(ret,1)
	end

	return unpack(ret);
end