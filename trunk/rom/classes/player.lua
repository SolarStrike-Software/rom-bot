include("pawn.lua");
include("skill.lua");

WF_NONE = 0;   -- We didn't fail
WF_TARGET = 1; -- Failed waypoint because we have a target
WF_DIST = 2;   -- Broke because our distance somehow increased. It happens.
WF_STUCK = 3;  -- Failed waypoint because we are stuck on something.
WF_COMBAT = 4; -- stopped waypoint because we are in combat

ONLY_FRIENDLY = true;	-- only cast friendly spells HEAL / HOT / BUFF
JUMP_FALSE = false		-- dont jump to break cast
JUMP_TRUE = true		-- jump to break cast

-- The craft numbers corespond with their order in memory
CRAFT_BLACKSMITHING = 0
CRAFT_CARPENTRY = 1
CRAFT_ARMORCRAFTING = 2
CRAFT_TAILORING = 3
CRAFT_COOKING = 4
CRAFT_ALCHEMY = 5
CRAFT_MINING = 6
CRAFT_WOODCUTTING = 7
CRAFT_HERBALISM = 8

local BreakFromFight = false

CPlayer = class(CPawn);

function CPlayer.new()
	local playerAddress = memoryReadRepeat("intptr", getProc(), addresses.staticbase_char, addresses.charPtr_offset);
	local np = CPlayer(playerAddress);
	np:initialize();
	np:update();
	return np;
end

function CPlayer:update()
	local addressChanged = false

	-- Ensure that our address hasn't changed. If it has, fix it.
	local tmpAddress = memoryReadRepeat("intptr", getProc(), addresses.staticbase_char, addresses.charPtr_offset) or 0;
	if( tmpAddress ~= self.Address and tmpAddress ~= 0 ) then
		self.Address = tmpAddress;
		cprintf(cli.green, language[40], self.Address);
		addressChanged = true
		if self.Class1 == CLASS_WARDEN then
			setpetautoattacks()
		end
	end;

	CPawn.update(self); -- run base function

	if addressChanged or (#settings.profile.skills == 0 and next(settings.profile.skillsData) ~= nil) then
		settings.loadSkillSet(self.Class1)
		-- Reset editbox false flag on start up
		if memoryReadUInt(getProc(), addresses.editBoxHasFocus_address) == 0 then
			RoMScript("GetKeyboardFocus():ClearFocus()")
		end
		addressChanged = false
	end

	-- If have 2nd class, look for 3rd class
	-- Class1 and Class2 are done in the pawn class. Class3 only works for player.
	local classInfoSize = 0x294
	if self.Class2 ~= -1 then
		for i = 1, 8 do
			local level = memoryReadInt(getProc(),addresses.charClassInfoBase + (classInfoSize * i) + addresses.charClassInfoLevel_offset)
			if level > 0 and i ~= self.Class1 and i ~= self.Class2 then
				-- must be class 3
				self.Class3 = i
				break
			end
		end
	end


	self.Level = memoryReadRepeat("int", getProc(), addresses.charClassInfoBase + (classInfoSize* self.Class1 ) + addresses.charClassInfoLevel_offset) or self.Level
	self.Level2 = memoryReadRepeat("int", getProc(), addresses.charClassInfoBase + (classInfoSize* self.Class2 ) + addresses.charClassInfoLevel_offset) or self.Level2
	self.Level3 = memoryReadRepeat("int", getProc(), addresses.charClassInfoBase + (classInfoSize* self.Class3 ) + addresses.charClassInfoLevel_offset) or self.Level3
	self.XP = memoryReadRepeat("int", getProc(), addresses.charClassInfoBase + (classInfoSize* self.Class1 ) + addresses.charClassInfoXP_offset) or self.XP
	self.TP = memoryReadRepeat("int", getProc(), addresses.charClassInfoBase + (classInfoSize* self.Class1 ) + addresses.charClassInfoTP_offset) or self.TP

	self.Casting = (memoryReadRepeat("intptr", getProc(), addresses.castingBarPtr, addresses.castingBar_offset) ~= 0);

	self.Battling = memoryReadRepeat("byteptr", getProc(), addresses.staticbase_char, addresses.charBattle_offset) == 1;

	self.Stance = memoryReadRepeat("byteptr", getProc(), addresses.staticbase_char, addresses.charStance_offset) or self.Stance
	self.Stance2 = memoryReadRepeat("byteptr", getProc(), addresses.staticbase_char, addresses.charStance_offset + 2) or self.Stance2

	self.ActualSpeed = memoryReadFloatPtr(getProc(), addresses.staticbase_char, addresses.actualSpeed_offset) or self.ActualSpeed
	self.Moving = (self.ActualSpeed > 0)

	local tmp = self:getBuff(503827)
	if tmp then -- has natures power
		self.Nature = tmp.Level + 1
	else
		self.Nature = 0
	end

	-- remember aggro start time, used for timed ranged pull
	if( self.Battling == true ) then
		if(self.aggro_start_time == 0) then
			self.aggro_start_time = os.time();
		end
	else
		self.aggro_start_time = 0;
	end

	if( self.Casting == nil or self.Battling == nil or self.Direction == nil ) then
		error("Error reading memory in CPlayer:update()");
	end

	self.PetPtr = memoryReadRepeat("uint", getProc(), self.Address + addresses.pawnPetPtr_offset) or self.PetPtr
	if( self.Pet == nil ) then
		self.Pet = CPawn(self.PetPtr);
	else
		self.Pet.Address = self.PetPtr;
		if( self.Pet.Address ~= 0 ) then
			self.Pet:update();
		end
	end

	-- Update our exp gain
	if( os.difftime(os.time(), self.LastExpUpdateTime) > self.ExpUpdateInterval ) then
		--local newExp = RoMScript("GetPlayerExp()") or 0;	-- Get newest value
		--local maxExp = RoMScript("GetPlayerMaxExp()") or 1; -- 1 by default to prevent division by zero

		local newExp = self.XP or 0;
		local maxExp = memoryReadRepeat("intptr", getProc(), addresses.charMaxExpTable_address, (self.Level-1) * 4) or 1;

		self.LastExpUpdateTime = os.time();					-- Reset timer

		if( type(newExp) ~= "number" ) then newExp = 0; end;
		if( type(maxExp) ~= "number" ) then maxExp = 1; end;

		-- If we have not begun tracking exp, start by gathering
		-- our current value, but do not count it as a gain
		if( self.ExpInsertPos == 0 ) then
			self.ExpInsertPos = 1;
			self.LastExp = newExp;
		else
			local gain = 0;
			local expGainSum = 0;
			local valueCount = 0;

			if( newExp > self.LastExp ) then
				gain = newExp - self.LastExp;
			elseif( newExp < self.LastExp ) then
				-- We probably just leveled up. Just get our current, new value and use that.
				gain = newExp;
			end

			self.LastExp = newExp;
			self.ExpTable[self.ExpInsertPos] = gain;
			self.ExpInsertPos = self.ExpInsertPos + 1;
			if( self.ExpInsertPos > self.ExpTableMaxSize ) then
				self.ExpInsertPos = 1;
			end;

			for i,v in pairs(self.ExpTable) do
				valueCount = valueCount + 1;
				expGainSum = expGainSum + v;
			end

			self.ExpPerMin = expGainSum / ( valueCount * self.ExpUpdateInterval / 60 );
			self.TimeTillLevel = (maxExp - newExp) / self.ExpPerMin;
			if( self.TimeTillLevel > 9999 ) then
				self.TimeTillLevel = 9999;
			end
		end
	end
end

-- Inserts a skill at the end of the queue.
-- Accepts a skill name like PRIEST_RISING_TIDE
-- or a skill object
function CPlayer:queueSkill(skill, blocking)
	blocking = blocking or false;

	if( type(skill) == "string" ) then
		local skill_found = false;
		for i,v in pairs(settings.profile.skills) do
			if( v.Name == skill ) then
				skill_found = true;
				skill = CSkill(v);
				break;
			end
		end

		if( skill_found == false ) then
			cprintf(cli.yellow, "Unknown profile skill %s. Check your manual castings "..
			  "(e.g. in the events or waypoint files). Be sure the skill is in the "..
			  "skills section of your profile.\n", skill);
			return;
		end
	end

	if( type(skill) ~= "table" ) then
		cprintf(cli.red, "[DEBUG] Error: 'skill' is not a table in CPlayer:queueSkill()\n");
		return;
	end

	skill.Blocking = blocking;
	table.insert(self.SkillQueue, skill);
end

function CPlayer:flushSkillQueue()
	self.SkillQueue = {};
end

function CPlayer:getNextQueuedSkill()
	if( #self.SkillQueue > 0 ) then
		return self.SkillQueue[1];
	else
		return nil;
	end
end

function CPlayer:popSkillQueue()
	table.remove(self.SkillQueue, 1);
end

function CPlayer:harvest(_id, _second_try)
	local function findNearestHarvestable(_id, ignore)
		ignore = ignore or 0;
		local closestHarvestable = nil;
		local obj = nil;
		local objectList = CObjectList();
		objectList:update();

		for i = 0,objectList:size() do
			obj = objectList:getObject(i);

			if( obj ~= nil ) then
				if( obj.Type == PT_NODE and obj.Address ~= ignore and
					(_id == obj.Id or (not _id and database.nodes[obj.Id])) ) then
					local harvestThis = true;
					if( database.nodes[obj.Id] ) then
						local harvestType = database.nodes[obj.Id].Type;
						if( harvestType == NTYPE_WOOD and settings.profile.options.HARVEST_WOOD == false ) then
							harvestThis = false;
						elseif( harvestType == NTYPE_HERB and settings.profile.options.HARVEST_HERB == false ) then
							harvestThis = false;
						elseif( harvestType == NTYPE_ORE and settings.profile.options.HARVEST_ORE == false ) then
							harvestThis = false;
						end
					end

					if( harvestThis == true ) then
						local dist = distance(self.X, self.Z, obj.X, obj.Z);
						if( closestHarvestable == nil ) then
							if( distance(self.X, self.Z, self.Y, obj.X, obj.Z, obj.Y) < settings.profile.options.HARVEST_DISTANCE ) then
								closestHarvestable = obj;
							end
						else
							if( distance(self.X, self.Z, self.Y, obj.X, obj.Z, obj.Y) <
								distance(self.X, self.Z, self.Y, closestHarvestable.X, closestHarvestable.Z, closestHarvestable.Y) ) then
								-- this node is closer
								closestHarvestable = obj;
							end
						end
					end
				end
			end
		end

		return closestHarvestable;
	end

	local function nodeStillFound(node)
		local closestHarvestable = nil;
		local obj = nil;
		local objectList = CObjectList();
		objectList:update();

		for i = 0,objectList:size() do
			obj = objectList:getObject(i);
			if( obj.Address == node.Address ) then
				return true;
			end
		end

		return false;
	end

	yrest(200); -- Make sure we come to a stop before attempting to harvest.
	local lastHarvestedNodeAddr = nil;
	while(true) do
		self:update();
		closestHarvestable = findNearestHarvestable(_id, lastHarvestedNodeAddr);
		if( closestHarvestable == nil ) then
			printf(language[79]);
			return;
		end

		if( type(settings.profile.events.onHarvest) == "function" ) then
			arg1 = CPawn(closestHarvestable.Address);
			local status,result = pcall(settings.profile.events.onHarvest);
			if( status == false ) then
				local msg = sprintf("onHarvest error: %s", result);
				error(msg);
			end

			if( result == false ) then -- They chose to not harvest this in the event
				return;
			end
		end

		-- Check harvest skill level.
		if database.nodes[closestHarvestable.Id] then
			local harvestLevel = database.nodes[closestHarvestable.Id].Level
			local harvestType = database.nodes[closestHarvestable.Id].Type
			local craftLevel
			if harvestType == NTYPE_ORE then
				craftLevel = self:getCraftLevel(CRAFT_MINING)
			elseif harvestType == NTYPE_WOOD then
				craftLevel = self:getCraftLevel(CRAFT_WOODCUTTING)
			elseif harvestType == NTYPE_HERB then
				craftLevel = self:getCraftLevel(CRAFT_HERBALISM)
			end
			if harvestLevel > craftLevel then
				print(language[76]) -- Harvest skill level too low
				return false;
			end
		end

		cprintf(cli.yellow, language[95], closestHarvestable.Name);

		if( distance(self.X, self.Z, self.Y, closestHarvestable.X, closestHarvestable.Z, closestHarvestable.Y) > 80 ) then
			self:moveInRange(CWaypoint(closestHarvestable.X, closestHarvestable.Z), 39, true);
		end

		if( nodeStillFound(closestHarvestable) ) then
			self:target(closestHarvestable.Address)
			yrest(100)
			Attack();
			yrest(100);
		else
			return; -- Node disappeared for whatever reason...
		end

		if _id and not database.nodes[closestHarvestable.Id] then -- The rest is not needed if not resource node
			return true;
		end

		yrest(500);

		self:update();
		local timeStart = getTime();
		local skip = false;
		while( not self.Harvesting ) do
			-- Wait to start harvesting
			yrest(100);
			self:update();
			if( self.Battling ) then
				printf(language[78]);
				skip = true;
				break;
			end

			if( deltaTime(getTime(), timeStart) > 3000 ) then
				-- Maybe the command didn't go through. Try once more.
				Attack()
				yrest(500);
				break;
			end
		end
		self:update();
		timeStart = getTime();
		while( self.Harvesting and skip == false ) do
			yrest(100);
			self:update();
			if( self.Battling ) then
				printf(language[78]);
				break;
			end

			if( not nodeStillFound(closestHarvestable) or self.TargetPtr ~= closestHarvestable.Address ) then
				break;
			end

			if( deltaTime(getTime(), timeStart) > 45000 ) then
				-- Taking too long. Drop out.
				printf("Stop harvesting. Taking too long.\n");
				break;
			end
		end

		self:update();
		if( not self.Battling ) then
			lastHarvestedNodeAddr = closestHarvestable.Address;
		else
			while( self.Battling ) do
				local enemy = self:findEnemy(true, nil, nil, nil)
				self:target(enemy);
				self:update();
				if( self:haveTarget() ) then
					self:fight();
				end
			end
		end
	end
end

-- Returns nil if nothing found, otherwise returns a pawn
function CPlayer:findEnemy(aggroOnly, _id, evalFunc, ignore)
	ignore = ignore or 0;
	local aggroOnly = aggroOnly or false;
	local bestEnemy = nil;
	local bestScore = 0;
	local obj = nil;
	local objectList = CObjectList();
	objectList:update();

	if( type(evalFunc) ~= "function" ) then
		evalFunc = function (unused) return true; end;
	end

	-- The 'max' values that each scoring sub-part uses
	local SCORE_DISTANCE = 60;      -- closer = more score; actually score will usually be less than half
	local SCORE_AGGRESSIVE = 80;    -- aggressive = score
	local SCORE_ATTACKING = 100;    -- attacking = score
	local SCORE_HEALTHPERCENT = 75; -- lower health = more score

	for i = 0,objectList:size() do
		obj = objectList:getObject(i);
		if( obj ~= nil ) then
			local inp = memoryReadRepeat("int", getProc(), obj.Address + addresses.pawnAttackable_offset) or 0;
			if not bitAnd(inp,0x4000000) then -- Invisible/attackable?
				if( obj.Type == PT_MONSTER and (_id == obj.Id or _id == nil) and obj.Address ~= ignore) then
					local dist = distance(self.X, self.Z, obj.X, obj.Z);
					local pawn = CPawn(obj.Address);
					local _target = pawn:getTarget();

					if( evalFunc(pawn.Address, pawn) == true ) then
						if( distance(self.X, self.Z, pawn.X, pawn.Z ) < settings.profile.options.MAX_TARGET_DIST and
						(( (pawn.TargetPtr == self.Address or (pawn.TargetPtr == self.PetPtr and self.PetPtr ~= 0) or _target.InParty == true ) and
						aggroOnly == true) or aggroOnly == false) ) then
							local currentScore = 0;
							currentScore = currentScore + ( (settings.profile.options.MAX_TARGET_DIST - dist) / settings.profile.options.MAX_TARGET_DIST * SCORE_DISTANCE );
							currentScore = currentScore + ( (pawn.MaxHP - pawn.HP) / pawn.MaxHP * SCORE_HEALTHPERCENT );
							if( pawn.TargetPtr == self.Address ) then currentScore = currentScore + SCORE_ATTACKING; end;
							if( pawn.Aggressive ) then
								currentScore = currentScore + SCORE_AGGRESSIVE;
							end;
							if _target.InParty == true  then currentScore = currentScore + 5000 end
							if( bestEnemy == nil ) then
								bestEnemy = obj;
								bestScore = currentScore;
							elseif( currentScore > bestScore ) then
								bestEnemy = obj;
								bestScore = currentScore;
							end
						end
					end
				end
			end
		end
	end

	if( bestEnemy ) then
		return CPawn(bestEnemy.Address);
	else
		return nil;
	end
end

function CPlayer:target(pawnOrAddress)
	local address = nil;
	if( type(pawnOrAddress) == "number" ) then
		address = pawnOrAddress;
	elseif( type(pawnOrAddress) == "table" ) then
		address = pawnOrAddress.Address;
	end

	if( address == nil ) then return; end;

	local addressId = memoryReadRepeat("uint", getProc(), address + addresses.pawnId_offset) or 0;

	if addressId == 0 or addressId > 999999 then -- The pawn or object no longer exists
		self.TargetPtr = 0
		return
	end

	memoryWriteInt(getProc(), self.Address + addresses.pawnTargetPtr_offset, address);
	self.TargetPtr = address
end

--[[
function CPlayer:harvest( _id, _second_try )
	if( foregroundWindow() ~= getWin() ) then
		cprintf(cli.yellow, language[94]);
		return;
	end

	local function scan()
		local mousePawn;
		-- Screen dimension variables
		local wx, wy, ww, wh = windowRect(getWin());
		local halfWidth = ww/2;
		local halfHeight = wh/2;

		-- Scan rect variables
		local scanWidth = settings.profile.options.HARVEST_SCAN_WIDTH; -- Width, in 'steps', of the area to scan
		local scanHeight = settings.profile.options.HARVEST_SCAN_HEIGHT; -- Height, in 'steps', of area to scan
		local scanXMultiplier = settings.profile.options.HARVEST_SCAN_XMULTIPLIER;	-- multiplier for scan width
		local scanYMultiplier = settings.profile.options.HARVEST_SCAN_YMULTIPLIER;	-- multiplier for scan line height
		local scanStepSize = settings.profile.options.HARVEST_SCAN_STEPSIZE; -- Distance, in pixels, between 'steps'
		local scan_yrest = settings.profile.options.HARVEST_SCAN_YREST;	-- yrest between mouse movements

		-- readaption stepsize to games client size
		-- node width at 975 screen width is about 66 (for moxa)
		scanStepSize = scanStepSize * ww / 1024;
		if (settings.profile.options.DEBUG_HARVEST) then
			cprintf(cli.yellow, "Your original stepsize is %d for 1024 screen width. We recalutate it to %d by %d screen width.\n",
			  settings.profile.options.HARVEST_SCAN_STEPSIZE, scanStepSize, ww);
			scan_yrest = scan_yrest + 200;
			cprintf(cli.yellow, "Your rest between scan movements: %d ms, we add 200 ms for debugging resons.\n",
			  settings.profile.options.HARVEST_SCAN_YREST);
		end

		local mx, my; -- Mouse x/y temp values

		mouseSet(wx + (halfWidth*scanXMultiplier - (scanWidth/2*scanStepSize)),
		wy  + (halfHeight*scanYMultiplier - (scanHeight/2*scanStepSize)));
		yrest(100);

		local scanstart, scanende, scanstep;
		-- define scan direction top/down  or   bottom/up
		if( settings.profile.options.HARVEST_SCAN_TOPDOWN == true ) then
			scanstart = 0;
			scanende = scanHeight-1;
			scanstep = 1;
		else
			scanstart = scanHeight;
			scanende = 0;
			scanstep = -1;
		end;

		-- Scan nearby area for a node
		keyboardHold(key.VK_SHIFT);	-- press shift so you can scan trough players
		for y = scanstart, scanende, scanstep do
			my = math.ceil(halfHeight * scanYMultiplier * settings.profile.options.HARVEST_SCAN_YMOVE
			               - (scanHeight / 2 * scanStepSize) + ( y * scanStepSize ));

			for x = 0,scanWidth-1 do
				mx = math.ceil(halfWidth * scanXMultiplier - (scanWidth / 2 * scanStepSize) + ( x * scanStepSize ));
				if (settings.profile.options.DEBUG_HARVEST) then
					cprintf(cli.yellow, " %d.%d", wx + mx, wy + my);
				end
				mouseSet(wx + mx, wy + my);
				yrest(scan_yrest);
				mousePawn = CPawn(memoryReadIntPtr(getProc(),
				addresses.staticbase_char, addresses.mousePtr_offset));

				-- list found ids if id "test" was given
				if( mousePawn.Address ~= 0
					and distance(self.X, self.Z, mousePawn.X, mousePawn.Z) < 150
					and _id == "test" ) then
					cprintf(cli.yellow, "Object found id %d %s\n", mousePawn.Id, mousePawn.Name);
				end

				-- id was given, return them if found
				if( mousePawn.Address ~= 0
					and distance(self.X, self.Z, mousePawn.X, mousePawn.Z) < 150
					and _id == mousePawn.Id ) then
					return mousePawn.Address, mx, my, mousePawn.Id;
				end

				-- normal harvesting
				if( mousePawn.Address ~= 0 and mousePawn.Type == PT_NODE
					and distance(self.X, self.Z, mousePawn.X, mousePawn.Z) < 150
					and database.nodes[mousePawn.Id] ) then
					return mousePawn.Address, mx, my, mousePawn.Id;
				end
			end
			if (settings.profile.options.DEBUG_HARVEST) then
				printf("\n");
			end
		end
		keyboardRelease(key.VK_SHIFT);


		return 0, nil, nil, 0;
	end


	detach(); -- Remove attach bindings
	local mouseOrigX, mouseOrigY = mouseGetPos();
	local foundHarvestNode, nodeMouseX, nodeMouseY, hf_node_id = scan();
	local hf_found = false;
	local startHarvestTime = os.time();

	if( foundHarvestNode ~= 0 and nodeMouseX and nodeMouseY ) then

		-- If out of distance, move and rescan
		local mousePawn = CPawn(foundHarvestNode);
		local dist = distance(self.X, self.Z, mousePawn.X, mousePawn.Z)

		-- We found something. Lets harvest it.
		hf_found = true;
		cprintf(cli.green, language[95], mousePawn.Name);		-- we found ...

		if( dist > 35 and dist < 150 ) then
			printf(language[80]);		-- Move in
			self:moveTo( CWaypoint(mousePawn.X, mousePawn.Z), true );
			yrest(200);
			foundHarvestNode, nodeMouseX, nodeMouseY = scan();
		end

		while( foundHarvestNode ~= 0 and nodeMouseX and nodeMouseY ) do

			self:update();

			if( self.Battling ) then	-- we get aggro, stop harvesting
				keyboardRelease(key.VK_SHIFT);
				if( self.Returning ) then	-- set wp one back to harverst wp
					__RPL:backward();	-- again after the fight
				else
					__WPL:backward();
				end;
				break;
			end;

			if( os.difftime(os.time(), startHarvestTime) > settings.profile.options.HARVEST_TIME ) then
				break;
			end

			local wx,wy = windowRect(getWin());
			--mouseSet(wx + nodeMouseX, wy + nodeMouseY);
			mouseSet(wx + nodeMouseX, wy + nodeMouseY);
			yrest(50);
			mousePawn = CPawn(memoryReadIntPtr(getProc(), addresses.staticbase_char, addresses.mousePtr_offset));
			yrest(50);

			if( mousePawn.Address ~= 0 and mousePawn.Id == hf_node_id ) then
				-- Node/Object is still here

				-- Begin gathering
				keyboardHold(key.VK_SHIFT);
				mouseLClick();
				yrest(100);
				mouseLClick();
				keyboardRelease(key.VK_SHIFT);

				-- Wait for a few seconds... constantly check for aggro
				local startWaitTime = os.time();
				while( os.difftime(os.time(), startWaitTime) < 2 ) do

--					yrest(100);
					inventory:updateSlotsByTime(100);	-- use time to update inventory

					self:update();

					-- Make sure it didn't disapear
					mousePawn = CPawn(memoryReadIntPtr(getProc(),
					addresses.staticbase_char, addresses.mousePtr_offset));

					if( mousePawn.Address == 0 ) then
						break;
					end;

					if( self.Battling ) then
						break;
					end
				end

				self:update();

			else
				-- Node/Object is gone
				break;
			end
		end
	end

	mouseSet(mouseOrigX, mouseOrigY);
	attach(getWin()); -- Re-attach bindings

	-- sometimes harvesting breaks at begin after found, because camera is still
	-- moving, in that case, wait a little and harvest again
	if( hf_found == true   and
	    not _second_try    and 			-- only one extra harverst try
	    os.difftime(os.time(), startHarvestTime) < 5 ) then
		cprintf(cli.green, language[81]);		-- Unexpected interruption at harvesting begin
			yrest(5000);
		self:harvest( _id, true );
	end

end
]]

function CPlayer:initialize()
	memoryWriteInt(getProc(), self.Address + addresses.pawnCasting_offset, 0);
end

-- Resets "toggled" skills to off & used counter to 0
function CPlayer:resetSkills()
	for i,v in pairs(settings.profile.skills) do
		if( v.Toggled ) then
			v.Toggled = false;
		end
		if( v.used ) then
			v.used = 0;
		end
	end
end

-- Resets skill cooldowns / used after death
function CPlayer:resetSkillLastCastTime()
	for i,v in pairs(settings.profile.skills) do
		if( v.Name ~= "PRIEST_SOUL_BOND" ) then		-- real cooldown of 1800 sec

			v.LastCastTime = { low = 0, high = 0 };
		end;
	end
end

local function RestWhileCheckingForWaypoint(_duration)
	if #__WPL.Waypoints > 0 and player.Moving then
		-- rest for _duration but if moving stop when reaching waypoint
		local starttime = os.clock()
		local curWP = __WPL.Waypoints[__WPL.CurrentWaypoint]
		local lastdist = distance(player.X,player.Z,curWP.X, curWP.Z)
		repeat
			startdist = lastdist
			yrest(10)
			player:update()
			lastdist = distance(player.X, player.Z, curWP.X, curWP.Z)
		until (os.clock() - starttime) > _duration/1000 or
					 (lastdist < 10 or lastdist > startdist) -- and wp reached or moving away
	else
		yrest(_duration)
	end
end

function CPlayer:cast(skill)
	-- If given a string, look it up.
	-- If given a skill object, use it natively.
	if( type(skill) == "string" ) then
		local skill_found = false;
		for i,v in pairs(settings.profile.skills) do
			if( v.Name == skill ) then
				skill_found = true;
				skill = v; break;
			end
		end
		if( skill_found == false ) then
			cprintf(cli.yellow, "Unknown profile skill %s. Check your manual castings "..
			  "(e.g. in the events or waypoint files). Be sure the skill is in the "..
			  "skills section of your profile.\n", skill);
		end
	end

	local hf_temp;
	if( skill.hotkey == "MACRO" or skill.hotkey == "" or skill.hotkey == nil) then
		hf_temp = "MACRO";
	else
		hf_temp = getKeyName(skill.hotkey);
	end

	local continue = true;
	if( type(settings.profile.events.onPreSkillCast) == "function" ) then
		arg1 = skill;
		if ( onPreSkillCast_active ~= true ) then	-- avoid calling event if already within an event
			onPreSkillCast_active = true;
			local status,result = pcall(settings.profile.events.onPreSkillCast);
			if( status == false ) then
				local msg = sprintf("onPreSkillCast error: %s", result);
				error(msg);
			end
			if( result == false ) then continue = false; end;
			onPreSkillCast_active = false;
		end
	end

	if(continue == true) then
		if self.Casting then self:waitTillCastingEnds() end -- Wait for previous cast to end minus undercut
		while skill.CastTime == 0 and self.Casting do  -- fixes instant cast after timed cast timing problem, waits till finished
			self:update(); yrest(50);
		end
		printf(language[21], hf_temp, string.sub(skill.Name.."                      ", 1, 20));	-- first part of 'casting ...'
		skill:use();
		local startTime = getTime();
		-- yrest(100);
		self:update();

		-- Wait for casting to start (if it has a decent cast time)
		if( skill.CastTime > 0 ) then
			-- wait for previous cast to finish. >PRIOR assume missed it
			local prior = getSkillUsePrior();

			while (self.Casting) and (deltaTime(getTime(),startTime) < prior) do
				self:update(); yrest(10);
			end
	--		local startTime = os.time();
			startTime = getTime();
			while( not self.Casting ) do -- wait for casting to start
				-- break cast with jump if aggro before casting finished
				if( self:check_aggro_before_cast(JUMP_TRUE, skill.Type) and
				   ( skill.Type == STYPE_DAMAGE or
					 skill.Type == STYPE_DOT ) ) then	-- with jump
					printf(language[82]);	-- close print 'Casting ..." / aborted
					return;
				end;
				yrest(50);
				self:update();
	--			if( os.difftime(os.time(), startTime) > skill.CastTime ) then
				if( deltaTime(getTime(), startTime) > 1500 ) then -- Assume failed to caste after 1.5 sec
					printf(language[180]);	-- close print 'Casting ..." / aborted
					return;
				end
			end;

			self.LastSkillStartTime=getTime() -- now that casting = true reset starttime to now
		else
			RestWhileCheckingForWaypoint(700); -- assume .7 second yrest
		end

		-- count cast to enemy targets
		if( skill.Target == STARGET_ENEMY ) then	-- target is unfriendly
			self.Cast_to_target = self.Cast_to_target + 1;
		end;

	-- ??? why wait?
	-- we have above a 500 wait if no CastTime or the self.Casting flag
	--	if( skill.CastTime == 0 ) then
	--		yrest(500);
	--	else
	--		yrest(100);
	--	end;

		-- print HP of our target
		-- we do it later, because the client needs some time to change the values
		 local target = self:getTarget();
		printf("=>   "..target.Name.." ("..target.HP.."/"..target.MaxHP..")\n");	-- second part of 'casting ...'

		-- the check was only done after every complete skill round
		-- hence the message is not really needed anymore
		-- we move the check INTO the skill round to be more accurate
		-- by the max_fight_time option could be reduced
		if( target.HP ~= lastTargetHP ) then
			self.lastHitTime = os.time();
			lastTargetHP = target.HP;
	--				printf(language[23]);		-- target HP changed
		end

		if( type(settings.profile.events.onSkillCast) == "function" ) then
			arg1 = skill;
			if ( onSkillCast_active ~= true ) then	-- avoid calling event if already within an event
				onSkillCast_active = true;
				local status,err = pcall(settings.profile.events.onSkillCast);
				if( status == false ) then
					local msg = sprintf("onSkillCast error: %s", err);
					error(msg);
				end
				onSkillCast_active = false;
			end
		end
	else
		continue = true;
	end
end

-- Check if you can use any skills, and use them
-- if they are needed.
function CPlayer:checkSkills(_only_friendly, target)
	local used = false;
	self:update();
	--=== don't cast any skills if mounted ===--
	--if settings.profile.options.DISMOUNT == false and player.Mounted then return false end

	local target = target or self:getTarget();
	if ( target ~= nil and _only_friendly ~= true ) then
			target:update();
	end

	local useQueue = true;
	if( #self.SkillQueue > 0 ) then
		-- Queue is not empty. See if we can cast anything
		local skill = self:getNextQueuedSkill();
		local target = self:getTarget();
		if( skill.Blocking ) then
			if( skill:canUse(false, target) ) then
				if( self.Cast_to_target > settings.profile.options.MAX_SKILLUSE_NODMG  and
					target.HP == target.MaxHP ) then
					printf(language[83]);			-- Taking too long to damage target
					self.Last_ignore_target_ptr = self.TargetPtr;	-- remember break target
					self.Last_ignore_target_time = os.time();		-- and the time we break the fight
					self:clearTarget();

					if( self.Battling ) then
						yrest(1000);
					   keyboardHold( settings.hotkeys.MOVE_BACKWARD.key);
					   yrest(1000);
					   keyboardRelease( settings.hotkeys.MOVE_BACKWARD.key);
					   self:update();
					end

					break_fight = true;
				end

				if( skill.CastTime > 0 ) then
					keyboardRelease( settings.hotkeys.MOVE_FORWARD.key );
					yrest(200); -- Wait to stop only if not an instant cast spell
				end

				self:cast(skill);
				used = true;
				self:popSkillQueue();
			else
				useQueue = false;
			end
		else
			if( skill:canUse(false, target) ) then
				if( self.Cast_to_target > settings.profile.options.MAX_SKILLUSE_NODMG  and
					target.HP == target.MaxHP ) then
					printf(language[83]);			-- Taking too long to damage target
					self.Last_ignore_target_ptr = self.TargetPtr;	-- remember break target
					self.Last_ignore_target_time = os.time();		-- and the time we break the fight
					self:clearTarget();

					if( self.Battling ) then
						yrest(1000);
					   keyboardHold( settings.hotkeys.MOVE_BACKWARD.key);
					   yrest(1000);
					   keyboardRelease( settings.hotkeys.MOVE_BACKWARD.key);
					   self:update();
					end

					break_fight = true;
				end

				if( skill.CastTime > 0 ) then
					keyboardRelease( settings.hotkeys.MOVE_FORWARD.key );
					yrest(200); -- Wait to stop only if not an instant cast spell
				end

				self:cast(skill);
				used = true;
				useQueue = false;
			end

			self:popSkillQueue();
		end
	else
		-- Queue is empty, continue like normal
		useQueue = false;
	end

	if( not useQueue ) then
		local last_dist_to_wp
		local attack_skill_used = false -- Used for priority casting
		for i,v in pairs(settings.profile.skills) do
			if( v.AutoUse and v:canUse(_only_friendly, target) ) and
			  (settings.profile.options.PRIORITY_CASTING ~= true or attack_skill_used == false) then
				-- break if just checking buff, moving and reached WP. So it can turn
				if _only_friendly and #__WPL.Waypoints > 0 and self.Moving then
					local curWP = __WPL.Waypoints[__WPL.CurrentWaypoint]
					local distToWP = distance(self.X, self.Z, curWP.X, curWP.Z)
					if distToWP < 10 then -- wp reached
						break
					end
					if last_dist_to_wp and distToWP > last_dist_to_wp then -- moving away from wp
						break
					end

					last_dist_to_wp = distToWP
				end

				-- additional potion check while working at a 'casting round'
				self:checkPotions();

				-- Short time break target: after x casts without damaging
				local target = self:getTarget();
				if( self.Cast_to_target > settings.profile.options.MAX_SKILLUSE_NODMG  and
					target.HP == target.MaxHP ) then
					printf(language[83]);			-- Taking too long to damage target
					self.Last_ignore_target_ptr = self.TargetPtr;	-- remember break target
					self.Last_ignore_target_time = os.time();		-- and the time we break the fight
					self:clearTarget();

					if( self.Battling ) then
						yrest(1000);
					   keyboardHold( settings.hotkeys.MOVE_BACKWARD.key);
					   yrest(1000);
					   keyboardRelease( settings.hotkeys.MOVE_BACKWARD.key);
					   self:update();
					end

					break_fight = true;
					break;
				end

				if( v.CastTime > 0 ) then
					keyboardRelease( settings.hotkeys.MOVE_FORWARD.key );
					yrest(200); -- Wait to stop only if not an instant cast spell
				end

				if settings.profile.options.PRIORITY_CASTING == true and (v.Type == STYPE_DAMAGE or v.Type == STYPE_DOT) then
					attack_skill_used = true
				end

				self:cast(v);
				used = true;
			end
		end
	else
		self:checkPotions();
	end

	return used;
end

-- Check if you need to use any potions, and use them.
function CPlayer:checkPotions()
-- only one potion type could be used, so we return after using one type

	--=== If rogue is hidden then don't use potions as it breaks hide ===--
	if self.Class1 == 3 and self:hasBuff(500675) then return false end

	if settings.profile.options.USE_PHIRIUS_POTION == true then
		-- If we need to use a health potion
		if( (self.HP/self.MaxHP*100) < settings.profile.options.PHIRIUS_HP_LOW  and
			os.difftime(os.time(), self.PhiriusLastUseTime) > 19 )  then
			item = inventory:bestAvailablePhirius("phirushealing");
			if( item ) then
				if self.Casting then self:waitTillCastingEnds() end -- wait if still casting minus undercut
				local checkItemName = item.Name;
				item:update();
				if( checkItemName ~= item.Name ) then
					cprintf(cli.yellow, language[18], tostring(checkItemName), tostring(item.Name));
					item:update();
				else
					item:use();
					self.PhiriusHpUsed = self.PhiriusHpUsed + 1;			-- counts use of HP potions

					cprintf(cli.green, language[10], 		-- Using HP potion
					   self.HP, self.MaxHP, self.HP/self.MaxHP*100,
					   item.Name, item.ItemCount);
					   RestWhileCheckingForWaypoint(1000)
					if( self.Fighting ) then
						yrest(1000);
					end

					self.PhiriusLastUseTime = os.time();
				end

				return true;
			else		-- potions empty
				if( os.difftime(os.time(), self.PhiriusLastHpEmptyTime) > 16 ) then
					cprintf(cli.yellow, "No more usable HP Phirius pots\n");
					self.PhiriusLastHpEmptyTime = os.time();
					-- full inventory update if potions empty
					if( os.difftime(os.time(), self.InventoryLastUpdate) >
					  settings.profile.options.INV_UPDATE_INTERVAL ) then
						self.InventoryDoUpdate = true;
					end
				end;
			end
		end

		-- If we need to use a mana potion(if we even have mana)
		if( self.MaxMana > 0 ) then
			if( (self.Mana/self.MaxMana*100) < settings.profile.options.PHIRIUS_MP_LOW  and
				os.difftime(os.time(), self.PhiriusLastUseTime) > 19 )  then
				item = inventory:bestAvailablePhirius("phirusmana");
				if( item ) then
					if self.Casting then self:waitTillCastingEnds() end -- wait if still casting minus undercut
					local checkItemName = item.Name;
					item:update();
					if( checkItemName ~= item.Name ) then
						cprintf(cli.yellow, language[18], tostring(checkItemName), tostring(item.Name));
						item:update();
					else
						item:use();
						self.PhiriusManaUsed = self.PhiriusManaUsed + 1;		-- counts use of mana potions

						cprintf(cli.green, language[11], 		-- Using MP potion
							self.Mana, self.MaxMana, self.Mana/self.MaxMana*100,
							item.Name, item.ItemCount);
							RestWhileCheckingForWaypoint(1000)
						if( self.Fighting ) then
							yrest(1000);
						end

						self.PhiriusLastUseTime = os.time();
					end

					return true;		-- avoid invalid/use count of
				else	-- potions empty
					if( os.difftime(os.time(), self.PhiriusLastManaEmptyTime) > 16 ) then
						cprintf(cli.yellow, "No more usable MP Phirius pots\n");
						self.PhiriusLastManaEmptyTime = os.time();
						-- full inventory update if potions empty
						if( os.difftime(os.time(), self.InventoryLastUpdate) >
						  settings.profile.options.INV_UPDATE_INTERVAL ) then
							self.InventoryDoUpdate = true;
						end
					end;
				end;
			end
		end
	end

	self:update()

	--== Normal Potions after checking for phirius ==--
--=== Lisa to add in hot and one time heal potion usage. ===--

	-- If we need to use a heal over time potion
	if( (self.HP/self.MaxHP*100) < settings.profile.options.HP_LOW_POTION  and
		os.difftime(os.time(), self.PotionLastUseTime) > 15 )  then
		item = inventory:bestAvailableConsumable("hot");
		if( item ) then
			if self.Casting then self:waitTillCastingEnds() end -- wait if still casting minus undercut
			local checkItemName = item.Name;
			item:update();
			if( checkItemName ~= item.Name ) then
				cprintf(cli.yellow, language[18], tostring(checkItemName), tostring(item.Name));
				item:update();
			else
				item:use();
				self.PotionHpUsed = self.PotionHpUsed + 1;			-- counts use of HP potions

				cprintf(cli.green, language[10], 		-- Using HP potion
				   self.HP, self.MaxHP, self.HP/self.MaxHP*100,
				   item.Name, item.ItemCount);
				   RestWhileCheckingForWaypoint(1000)
				if( self.Fighting ) then
					yrest(1000);
				end

				self.PotionLastUseTime = os.time();
			end

			return true;
		else		-- potions empty
			if( os.difftime(os.time(), self.PotionLastHpEmptyTime) > 16 ) then
				cprintf(cli.yellow, language[17], inventory.MaxSlots); 		-- No more (usable) hp potions
				self.PotionLastHpEmptyTime = os.time();
				-- full inventory update if potions empty
				if( os.difftime(os.time(), self.InventoryLastUpdate) >
				  settings.profile.options.INV_UPDATE_INTERVAL ) then
					self.InventoryDoUpdate = true;
				end
			end;
		end
	end

	-- If we need to use a mana over time potion(if we even have mana)
	if( self.MaxMana > 0 ) then
		if( (self.Mana/self.MaxMana*100) < settings.profile.options.MP_LOW_POTION  and
			os.difftime(os.time(), self.PotionLastUseTime) > 15 )  then
			item = inventory:bestAvailableConsumable("mot");
			if( item ) then
				-- yrest(settings.profile.options.SKILL_USE_PRIOR);	-- potions can be drubk before cast/skill is finished
				if self.Casting then self:waitTillCastingEnds() end -- wait if still casting minus undercut
				--local unused,unused,checkItemName = RoMScript("GetBagItemInfo(" .. item.SlotNumber .. ")");
				-- I think this check here is useless now
				local checkItemName = item.Name;
				item:update();
				if( checkItemName ~= item.Name ) then
					cprintf(cli.yellow, language[18], tostring(checkItemName), tostring(item.Name));
					item:update();
				else
					item:use();
					self.PotionManaUsed = self.PotionManaUsed + 1;		-- counts use of mana potions

					cprintf(cli.green, language[11], 		-- Using MP potion
						self.Mana, self.MaxMana, self.Mana/self.MaxMana*100,
						item.Name, item.ItemCount);
						RestWhileCheckingForWaypoint(1000)
					if( self.Fighting ) then
						yrest(1000);
					end

					self.PotionLastUseTime = os.time();
				end

				return true;		-- avoid invalid/use count of
			else	-- potions empty
				if( os.difftime(os.time(), self.PotionLastManaEmptyTime) > 16 ) then
					cprintf(cli.yellow, language[16], inventory.MaxSlots); 		-- No more (usable) mana potions
					self.PotionLastManaEmptyTime = os.time();
					-- full inventory update if potions empty
					if( os.difftime(os.time(), self.InventoryLastUpdate) >
					  settings.profile.options.INV_UPDATE_INTERVAL ) then
						self.InventoryDoUpdate = true;
					end
				end;
			end;
		end
	end

	-- If we need to use a heal potion
	if( (self.HP/self.MaxHP*100) < settings.profile.options.HP_LOW_POTION  and
		os.difftime(os.time(), self.PotionLastOnceUseTime) > 60 )  then
		item = inventory:bestAvailablepotion("heal");
		if( item ) then
			if self.Casting then self:waitTillCastingEnds() end -- wait if still casting minus undercut
			local checkItemName = item.Name;
			item:update();
			if( checkItemName ~= item.Name ) then
				cprintf(cli.yellow, language[18], tostring(checkItemName), tostring(item.Name));
				item:update();
			else
				item:use();
				self.PotionHpOnceUsed = self.PotionHpOnceUsed + 1;			-- counts use of HP potions

				cprintf(cli.green, language[10], 		-- Using HP potion
				   self.HP, self.MaxHP, self.HP/self.MaxHP*100,
				   item.Name, item.ItemCount);
				if( self.Fighting ) then
					yrest(1000);
				end

				self.PotionLastOnceUseTime = os.time();
			end

			return true;
		else		-- potions empty
			if( os.difftime(os.time(), self.PotionLastHpOnceEmptyTime) > 16 ) then
				--cprintf(cli.yellow, language[17], inventory.MaxSlots); 		-- No more (usable) hp potions
				self.PotionLastHpOnceEmptyTime = os.time();
				-- full inventory update if potions empty
				if( os.difftime(os.time(), self.InventoryLastUpdate) >
				  settings.profile.options.INV_UPDATE_INTERVAL ) then
					self.InventoryDoUpdate = true;
				end
			end;
		end
	end

	-- If we need to use a mana potion(if we even have mana)
	if( self.MaxMana > 0 ) then
		if( (self.Mana/self.MaxMana*100) < settings.profile.options.MP_LOW_POTION  and
			os.difftime(os.time(), self.PotionLastOnceUseTime) > 60 )  then
			item = inventory:bestAvailablepotion("mana");
			if( item ) then
				-- yrest(settings.profile.options.SKILL_USE_PRIOR);	-- potions can be drubk before cast/skill is finished
				if self.Casting then self:waitTillCastingEnds() end -- wait if still casting minus undercut
				--local unused,unused,checkItemName = RoMScript("GetBagItemInfo(" .. item.SlotNumber .. ")");
				-- I think this check here is useless now
				local checkItemName = item.Name;
				item:update();
				if( checkItemName ~= item.Name ) then
					cprintf(cli.yellow, language[18], tostring(checkItemName), tostring(item.Name));
					item:update();
				else
					item:use();
					self.PotionManaOnceUsed = self.PotionManaOnceUsed + 1;		-- counts use of mana potions

					cprintf(cli.green, language[11], 		-- Using MP potion
						self.Mana, self.MaxMana, self.Mana/self.MaxMana*100,
						item.Name, item.ItemCount);
					if( self.Fighting ) then
						yrest(1000);
					end

					self.PotionLastOnceUseTime = os.time();
				end

				return true;		-- avoid invalid/use count of
			else	-- potions empty
				if( os.difftime(os.time(), self.PotionLastManaOnceEmptyTime) > 16 ) then
					--cprintf(cli.yellow, language[16], inventory.MaxSlots); 		-- No more (usable) mana potions
					self.PotionLastManaOnceEmptyTime = os.time();
					-- full inventory update if potions empty
					if( os.difftime(os.time(), self.InventoryLastUpdate) >
					  settings.profile.options.INV_UPDATE_INTERVAL ) then
						self.InventoryDoUpdate = true;
					end
				end;
			end;
		end
	end

	return false

end

function CPlayer:fight()
	self:update();
	if( not self:haveTarget() ) then
		return false;
	end
	if self.Mounted then
		self:dismount()
	end
	keyboardRelease( settings.hotkeys.MOVE_FORWARD.key);

	if ( settings.profile.options.PARTY == true ) and (settings.profile.options.PARTY_ICONS == true) then
		sendMacro('SetRaidTarget("target", 1);')
		if (settings.profile.options.PARTY_ICONS ~= true) then printf("Raid Icons not set in character profile.\n") end
	end

	if self.Class1 == CLASS_WARDEN then -- if warden let pet start fight.
		petupdate()
		if pet.Name == GetIdName(102297) or
		pet.Name == GetIdName(102324) or
		pet.Name == GetIdName(102803)
		then
			petstartcombat()
		end
	end

	local target = self:getTarget();
	self.IgnoreTarget = target.Address;
	self.Fighting = true;

	cprintf(cli.green, language[22], target.Name);	-- engagin x in combat

	-- Keep tapping the attack button once every few seconds
	-- just in case the first one didn't go through
	local function timedAttack()
		self:update();
		-- Obsolete. Interferes with undercutting skills
		--[[if( self.Casting ) then
			-- Don't interupt casting
			return;
		end;]]

		-- Prevents looting when looting is turned off
		-- (target is dead, or about to be dead)
		if( self.Target ~= 0 ) then
			local target = self:getTarget();
			if( (target.HP/target.MaxHP) <= 0.1 ) then
				return;
			end
		end;

		Attack()
	end

	-- Prep for battle, if needed.
	--self:checkSkills();

--	local target = self:getTarget();  / double
	self.lastHitTime = os.time();
	local lastTargetHP = target.HP;
	local move_closer_counter = 0;	-- count move closer trys
	self.Cast_to_target = 0;		-- reset counter cast at enemy target
	self.ranged_pull = false;		-- flag for timed ranged pull for melees
	local hf_start_dist = 0;		-- distance to mob where we start the fight

	-- check if timed ranged pull for melee
	if(settings.profile.options.COMBAT_TYPE == "melee"  and
	   settings.profile.options.COMBAT_RANGED_PULL == true and
	   self.Battling ~= true ) then
		self.ranged_pull = true;
		cprintf(cli.green, language[96]);	-- we start with ranged pulling
	end

	-- normal melee attack only if ranged pull isn't used
	if( settings.profile.options.COMBAT_TYPE == "melee" and
	    self.ranged_pull ~= true ) then
		registerTimer("timedAttack", secondsToTimer(2), timedAttack);

		-- start melee attack (even if out of range)
		timedAttack();
	end

	local break_fight = false;	-- flag to avoid kill counts for breaked fights
	BreakFromFight = false -- For users to manually break from fight using player:breakFight()
	while( self:haveTarget() ) do
		self:update();
		-- If we die, break
		if( self.HP < 1 or self.Alive == false ) then
			if( settings.profile.options.COMBAT_TYPE == "melee" ) then
				unregisterTimer("timedAttack");
			end
			self.Fighting = false;
			break_fight = true;
--			return;
			break;
		end;

		if BreakFromFight == true then
			break_fight = true;
			break;
		end

		local target = self:getTarget();

		if( target.HP ~= lastTargetHP ) then
			self.lastHitTime = os.time();
			lastTargetHP = target.HP;
		end

		-- Long time break: Exceeded max fight time (without hurting enemy) so break fighting
		if( os.difftime(os.time(), self.lastHitTime) > settings.profile.options.MAX_FIGHT_TIME ) then
			printf(language[83]);			-- Taking too long to damage target
			self.Last_ignore_target_ptr = self.TargetPtr;	-- remember break target
			self.Last_ignore_target_time = os.time();		-- and the time we break the fight
			self:clearTarget();

			if( self.Battling ) then
				yrest(1000);
			   keyboardHold( settings.hotkeys.MOVE_BACKWARD.key);
			   yrest(1000);
			   keyboardRelease( settings.hotkeys.MOVE_BACKWARD.key);
			   self:update();
			end

			break_fight = true;
			break;
		end

		local dist = distance(self.X, self.Z, target.X, target.Z);
		if( hf_start_dist == 0 ) then		-- remember distance we start the fight
			hf_start_dist = dist;
		end

		-- check if pulling phase should be finished
		if( self.ranged_pull == true ) then
			if( dist <= settings.options.MELEE_DISTANCE ) then
				cprintf(cli.green, language[97]); -- Ranged pulling finished, mob in melee distance
				self.ranged_pull = false;
			elseif( os.difftime(os.time(), self.aggro_start_time) > 3 and
			  self.aggro_start_time ~= 0 ) then
				cprintf(cli.green, language[98]); -- Ranged pulling after 3 sec wait finished
				self.ranged_pull = false;
			elseif( dist >=  hf_start_dist-45 and	-- mob not really coming closer
			  os.difftime(os.time(), self.aggro_start_time) > 1  and
			  self.aggro_start_time ~= 0 ) then
				cprintf(cli.green, language[99]); -- Ranged pulling finished. Mob not really moving
				self.ranged_pull = false;
			end;

			if self.ranged_pull == false and settings.profile.options.COMBAT_TYPE == "melee" then
				registerTimer("timedAttack", secondsToTimer(2), timedAttack);
				timedAttack();
			end
		end

		-- We're a bit TOO close...
		if( dist < 5.0 and not self.Casting ) then
			printf(language[24]);
			keyboardHold( settings.hotkeys.MOVE_BACKWARD.key);
			yrest(200);
			keyboardRelease( settings.hotkeys.MOVE_BACKWARD.key);
			self:update();
			dist = distance(self.X, self.Z, target.X, target.Z);
		end

		-- Move closer to the target if needed
		local suggestedRange = settings.options.MELEE_DISTANCE;
		if( suggestedRange == nil ) then suggestedRange = 45; end;
		if( settings.profile.options.COMBAT_TYPE == "ranged" or
		  self.ranged_pull == true ) then
			if( settings.profile.options.COMBAT_DISTANCE ~= nil ) then
				suggestedRange = settings.profile.options.COMBAT_DISTANCE;
			else
				suggestedRange = 155;
			end
		end

		-- check if aggro before attacking
		if( self.Battling == true  and				-- we have aggro
		    target.HP/target.MaxHP*100 > 90 and		-- target is alive and no attacking us
	-- Fix: there is a special dog mob 'Tatus', he switch from red to green at about 90%
	-- there seems to be a bug, so that sometimes Tatus don't have us into the target but still attacking us
	-- to prevent from skipping him while he is still attacking us, we do that special fix
			target.Name ~= "Tatus"	and
		    target.TargetPtr ~= self.Address and
			target.TargetPtr ~= self.Pet.Address and
			CPawn(target.TargetPtr).InParty ~= true ) then	-- but not from that mob
			cprintf(cli.green, language[36], target.Name);
			self:clearTarget();
			break_fight = true;
			break;
		end;

		if( dist > suggestedRange and not self.Casting ) then

			-- count move closer and break if to much
			move_closer_counter = move_closer_counter + 1;		-- count our move tries
			if( move_closer_counter > 3  and
			  (settings.profile.options.COMBAT_TYPE == "ranged" or
			  self.ranged_pull == true) ) then
				cprintf(cli.green, language[84]);	-- To much tries to come closer
				self:clearTarget();
				break_fight = true;
				break;
			end

			printf(language[25], suggestedRange, dist);
			-- move into distance
			local success, reason;

			if( settings.profile.options.COMBAT_TYPE == "ranged" or
			  self.ranged_pull == true ) then		-- melees with timed ranged pull
				if dist > suggestedRange then -- move closer
					success, reason = self:moveTo(target, true, nil, suggestedRange);
				end
			else 	-- normal melee
				success, reason = self:moveTo(target, true);
				-- Start melee attacking
				if( settings.profile.options.COMBAT_TYPE == "melee" ) then
					timedAttack();
				end
			end

			if( not success ) then
				self:unstick();
			end

			yrest(500);
		end

		if( settings.profile.options.QUICK_TURN ) then
			local angle = math.atan2(target.Z - self.Z, target.X - self.X);
			local yangle = math.atan2(target.Y - self.Y, ((target.X - self.X)^2 + (target.Z - self.Z)^2)^.5 );
			self:faceDirection(angle, yangle);

			camera:setRotation(angle);
			yrest(50);
		elseif( settings.options.ENABLE_FIGHT_SLOW_TURN ) then
			-- Make sure we're facing the enemy
			local angle = math.atan2(target.Z - self.Z, target.X - self.X);
			local yangle = math.atan2(target.Y - self.Y, ((target.X - self.X)^2 + (target.Z - self.Z)^2)^.5 );
			self:faceDirection(self.Direction, yangle); -- change only 'Y' angle with 'faceDirection'.
			local angleDif = angleDifference(angle, self.Direction);
			local correctingAngle = false;
			local startTime = os.time();

			while( angleDif > math.rad(15) ) do
				if( self.HP < 1 or self.Alive == false ) then
					self.Fighting = false;
					return;
				end;

				if( os.difftime(os.time(), startTime) > 5 ) then
					printf(language[26]);
					break;
				end;

				correctingAngle = true;
				if( angleDifference(angle, self.Direction + 0.01) < angleDif ) then
					-- rotate left
					keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );
					keyboardHold( settings.hotkeys.ROTATE_LEFT.key );
				else
					-- rotate right
					keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
					keyboardHold( settings.hotkeys.ROTATE_RIGHT.key );
				end

				yrest(100);
				self:update();
				target:update();
				angle = math.atan2(target.Z - self.Z, target.X - self.X);
				angleDif = angleDifference(angle, self.Direction);
			end

			if( correctingAngle ) then
				keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
				keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );
			end
		end

		if( self:checkPotions() or self:checkSkills() ) then
			-- If we used a potion or a skill, reset our last dist improvement
			-- to prevent unsticking
			self.LastDistImprove = os.time();
		elseif self.Cast_to_target == 0 then
			self.ranged_pull = false
		end

		yrest(100);
		self:update();
		local target = self:getTarget();


		-- do we need that? Because the DO statement is allready a
		-- while( self:haveTarget() statement / I will comment it out and see
		-- what happens (d003232, 18.9.09)
--		if( not self:haveTarget() ) then
--			break;
--		end
	end

	self:resetSkills();
	self.Cast_to_target = 0;	-- reset cast to target counter

	if( settings.profile.options.COMBAT_TYPE == "melee" ) then
		unregisterTimer("timedAttack");
	end


	if( not break_fight) then
		-- count kills per target name
		local target_Name = target.Name;
		if(target_Name == nil) then  target_Name = "<UNKNOWN>"; end;
		if(self.mobs[target_Name] == nil) then  self.mobs[target_Name] = 0; end;
		self.mobs[target_Name] = self.mobs[target_Name] + 1;

		self.Fights = self.Fights + 1;		-- count our fights

		cprintf(cli.green, language[27], 	-- Fight finished. Target dead/lost
		  self.mobs[target_Name],
		  target_Name,
		  self.Fights,
		  os.difftime(os.time(),
		  self.BotStartTime_nr)/60);
	else
		cprintf(cli.green, language[177]); 	-- Fight aborted
	end


	-- check if onLeaveCombat event is used in profile
	if( type(settings.profile.events.onLeaveCombat) == "function" ) then
		local status,err = pcall(settings.profile.events.onLeaveCombat);
		if( status == false ) then
			local msg = sprintf(language[85], err);
			error(msg);
		end
	end


	-- give client a little time to update battle flag (to come out of combat),
	-- if we loot even at combat we don't need the time
	--[[if( settings.profile.options.LOOT == true  and
		settings.profile.options.LOOT_IN_COMBAT ~= true ) then
--		yrest(800);
		inventory:updateSlotsByTime(800);

	end;]]
	-- Monster is dead (0 HP) but still targeted.
	-- Loot and clear target.
	self:update();
	if( not break_fight ) then
		self:loot();
	end

	-- Loot any other dead monsters nearby
	self:update()
	if not self.Battling or not self:findEnemy(true,nil,evalTargetDefault) then
		self:lootAll()
	end

	if( self.TargetPtr ~= 0 ) then
		self:clearTarget();
	end

	self.Fighting = false;

	yrest(200);
end

function CPlayer:breakFight()
	BreakFromFight = true
end

function CPlayer:loot()

	if( settings.profile.options.LOOT ~= true and settings.profile.options.LOOT_SIGILS ~= true) then
		if( settings.profile.options.DEBUG_LOOT) then
			cprintf(cli.yellow, "[DEBUG] don't loot reason: settings.profile.options.LOOT ~= true and settings.profile.options.LOOT_SIGILS ~= true\n");
		end;
		return
	end

	if settings.profile.options.LOOT == true then repeat -- 'repeat' block to 'break' from 'if' statement
		if( self.TargetPtr == 0 ) then
			if( settings.profile.options.DEBUG_LOOT) then
				cprintf(cli.yellow, "[DEBUG] don't loot reason: self.TargetPtr == 0\n");
			end;
			break
		end

		-- aggro and not loot in combat
		if( self.Battling  and
			settings.profile.options.LOOT_IN_COMBAT ~= true ) and
			self:findEnemy(true, nil, evalTargetDefault) then
			self:clearTarget()
			cprintf(cli.green, language[178]); 	-- Loot skiped because of aggro
			return
		end

		self:update();
		local target = self:getTarget();

		if( target == nil or target.Address == 0 ) then
			if( settings.profile.options.DEBUG_LOOT) then
				cprintf(cli.yellow, "[DEBUG] don't loot reason: target == nil or target.Address == 0\n");
			end;
			break;
		end

		local dist = distance(self.X, self.Z, target.X, target.Z);
		local hf_x = self.X
		local hf_z = self.Z;
		local lootdist = 100;

		-- Set to combat distance; update later if loot distance is set
		if( settings.profile.options.COMBAT_TYPE == "ranged" ) then
			lootdist = settings.profile.options.COMBAT_DISTANCE;
		end

		if( settings.profile.options.LOOT_DISTANCE ) then
			lootdist = settings.profile.options.LOOT_DISTANCE;
		end

		if( dist > lootdist ) then 	-- only loot when close by
			cprintf(cli.green, language[32]);	-- Target too far away; not looting.
			break
		end


		local function looten()
			-- "attack" is also the hotkey to loot, strangely.
			--[[local hf_attack_key;
			if( settings.profile.hotkeys.MACRO ) then
				hf_attack_key = "MACRO";
				cprintf(cli.green, language[31],
				   hf_attack_key , dist);	-- looting target.
				RoMScript("UseSkill(1,1);");
			else
				hf_attack_key = getKeyName(settings.profile.hotkeys.ATTACK.key);
				cprintf(cli.green, language[31],
				   hf_attack_key , dist);	-- looting target.
				keyboardPress(settings.profile.hotkeys.ATTACK.key);
			end]]
			Attack()

		--	yrest(settings.profile.options.LOOT_TIME + dist*15); -- dist*15 = rough calculation of how long it takes to walk there
		--	inventory:updateSlotsByTime(settings.profile.options.LOOT_TIME + dist*15);
			local maxWaitTime = settings.profile.options.LOOT_TIME + dist*15 -- dist*15 = rough calculation of how long it takes to walk there
			local startWait = getTime()
			while target.Lootable == true and deltaTime(getTime(), startWait) < maxWaitTime do
				yrest(100)
				target:update()
			end

			-- Wait for character to finish standing
			local starttime = os.clock()
			self:update()
			while self.Stance ~= 0 and 2 > (os.clock() - starttime) do
				yrest(50)
				self:update()
			end
		end

		--yrest(1000);
		self:update();
		target:update();
		if target.Lootable then
			looten();
		end;

		-- check for loot problems to give a noob mesassage
		self:update();
		local target = self:getTarget();
		dist = distance(self.X, self.Z, target.X, target.Z);
		if( dist > 50 and -- We would need to be further away to be able to move to the target
			--self.X == hf_x  and	-- we didn't move, seems attack key is not defined
			--self.Z == hf_z  and
			( target ~= nil or target.Address ~= 0 ) )  then	-- death mob disapeared?
			cprintf(cli.green, language[100]); -- We didn't move to the loot!?

			-- second loot try?
			if( type(settings.profile.options.LOOT_AGAIN) == "number" and settings.profile.options.LOOT_AGAIN > 0 and target.Lootable ) then
				yrest(settings.profile.options.LOOT_AGAIN);
				looten();	-- try it again
			end

		end;

		-- rnd pause from 2-6 sec after loot to look more human
		if( settings.profile.options.LOOT_PAUSE_AFTER > 0 ) then
			self:restrnd( settings.profile.options.LOOT_PAUSE_AFTER,2,6);
		end;

		-- Close the booty bag.
		RoMScript("BootyFrame:Hide()");
	until true end -- 'end' ends the 'if' statement

	local function sigilNameMatch(_name)
		if settings.profile.options.SIGILS_IGNORE_LIST == nil then
			return true -- collect all sigils
		end

		for sigil in string.gmatch(";"..settings.profile.options.SIGILS_IGNORE_LIST,"[,;]([^,;]*)") do
			if string.match(sigil,"^'.*'$") then sigil = string.match(sigil,"^'(.*)'$") end
			if sigil == _name then
				return false -- ignore the sigil
			end
		end

		return true -- not in ignore list. Don't ignore.
	end

	local function getNearestSigil()
		local nearestSigil = nil;
		local obj = nil;
		local objectList = CObjectList();
		objectList:update();

		for i = 0,objectList:size() do
			obj = objectList:getObject(i);

			if( obj ~= nil ) and ( obj.Type == PT_SIGIL ) and sigilNameMatch(obj.Name) then

				local dist = distance(self.X, self.Z, obj.X, obj.Z);

				if( nearestSigil == nil and dist < settings.profile.options.LOOT_DISTANCE ) then
					nearestSigil = obj;
				else

					if( dist < settings.profile.options.LOOT_DISTANCE and
						dist < distance(self.X, self.Z, nearestSigil.X, nearestSigil.Z) ) then
						-- New nearest sigil found
						nearestSigil = obj;
					end
				end
			end
		end

		return nearestSigil;
	end

	if settings.profile.options.LOOT_SIGILS == true or (settings.profile.options.LOOT == true and settings.profile.options.LOOT_SIGILS == nil) then
		-- Pick up all nearby sigils
		self:clearTarget();
		self:update();
		local sigil = getNearestSigil();
		--while( sigil ) do
		if( sigil ) then
			local dist = distance(self.X, self.Z, self.Y, sigil.X, sigil.Z, sigil.Y);
			local angle = math.atan2(sigil.Z - self.Z, sigil.X - self.X);
			local yangle = math.atan2(sigil.Y - self.Y, ((sigil.X - self.X)^2 + (sigil.Z - self.Z)^2)^.5 );
			local nY = self.Y + math.sin(yangle) * (dist + 15);
			local hypotenuse = (1 - math.sin(yangle)^2)^.5
			local nX = self.X + math.cos(angle) * (dist + 15) * hypotenuse;
			local nZ = self.Z + math.sin(angle) * (dist + 15) * hypotenuse;
			printf("Picking up sigil \"%s\"\n",sigil.Name)

			self:moveTo( CWaypoint(nX, nZ, nY), true );
			yrest(500);
			self:update();
			sigil = getNearestSigil();
		end
	end
end

local lootIgnoreList = {}
local lootIgnoreListPos = 0

function evalTargetLootable(address, target)

	if not target then
		target = CPawn(address);
	end

	-- Check if lootable
	if not ( target.Lootable ) then
		return false;
	end

	-- Check if in lootIgnoreList
	for __, addr in pairs(lootIgnoreList) do
		if target.Address == addr then
			return false
		end
	end

	-- Check height difference
	if( math.abs(target.Y - player.Y) > 45 ) then
		return false;
	end

	-- check distance to target
	local dist = distance(player.X, player.Z, player.Y, target.X, target.Z, target.Y);
	local lootdist = 100;

	-- Set to combat distance; update later if loot distance is set
	if( settings.profile.options.COMBAT_TYPE == "ranged" ) then
		lootdist = settings.profile.options.COMBAT_DISTANCE;
	end

	if( settings.profile.options.LOOT_DISTANCE ) then
		lootdist = settings.profile.options.LOOT_DISTANCE;
	end

	if( dist > lootdist ) then 	-- only loot when close by
		return false
	end

	-- check target distance to path against MAX_TARGET_DIST
	local wpl; -- this is the waypoint list we're using
	local V; -- this is the point we will use for distance checking

	if( player.Returning ) then
		wpl = __RPL;
	else
		wpl = __WPL;
	end

	if (__WPL:getMode() == "waypoints") and #__WPL.Waypoints > 0 then
		local pA = wpl.Waypoints[wpl.LastWaypoint]
		local pB = wpl.Waypoints[wpl.CurrentWaypoint]

		V = getNearestSegmentPoint(player.X, player.Z, pA.X, pA.Z, pB.X, pB.Z);
	else
		V = CWaypoint(player.X, player.Z); -- Distance check from player in wander mode
	end

	-- use a bounding box first to avoid sqrt when not needed (sqrt is expensive)
	if( target.X > (V.X - lootdist) and
		target.X < (V.X + lootdist) and
		target.Z > (V.Z - lootdist) and
		target.Z < (V.Z + lootdist) ) then

		if( distance(V.X, V.Z, target.X, target.Z) > lootdist ) then
			if( settings.profile.options.DEBUG_LOOT) then
				cprintf(cli.yellow, "unlooted monster dist > lootdist")
			end
			return false;			-- he is not a valid target
		end;
	else
		-- must be too far away
		if( settings.profile.options.DEBUG_LOOT) then
			cprintf(cli.yellow, "unlooted monster dist > lootdist")
		end
		return false;
	end
	return true
end

function CPlayer:lootAll()
	if( settings.profile.options.LOOT ~= true ) then
		if( settings.profile.options.DEBUG_LOOT) then
			cprintf(cli.yellow, "[DEBUG] don't loot all reason: settings.profile.options.LOOT ~= true\n");
		end;
		return
	end

	if( settings.profile.options.LOOT_ALL ~= true ) then
		if( settings.profile.options.DEBUG_LOOT) then
			cprintf(cli.yellow, "[DEBUG] don't loot all reason: settings.profile.options.LOOT_ALL ~= true\n");
		end;
		return
	end

	-- Warn user if they still have 'lootbodies()' userfunction installed.
	if type(lootBodies) == "function" then
		cprintf(cli.yellow,"The userfunction 'lootBodies()' is obsolete and might interfere with the bots 'lootAll()' function. Please delete the 'addon_lootbodies.lua' file from the 'userfunctions' folder.\n")
	end


	while true do
		-- Check if inventory is full. We don't loot if inventory is full.
		if inventory:itemTotalCount(0) == 0 then
			if( settings.profile.options.DEBUG_LOOT) then
				cprintf(cli.yellow, "[DEBUG] don't loot all reason: inventory is full\n");
			end;
			return
		end

		self:update()
		if( self.Battling  and
			self:findEnemy(true,nil,evalTargetDefault)) then
			break
		end

		local Lootable = self:findEnemy(false, nil, evalTargetLootable)

		if Lootable == nil then
			break
		end

		self:target(Lootable)
		self:update()
		if self.TargetPtr ~= 0 then -- Target's still there.
			self:loot()
			if self:findEnemy(true, nil, evalTargetDefault) then
				-- not looting because of aggro
				return
			end
			yrest(50)
			Lootable:update();
			if Lootable.Lootable == true then
				-- Failed to loot. Add to ignore list
				lootIgnoreListPos = lootIgnoreListPos + 1
				if lootIgnoreListPos > settings.profile.options.LOOT_IGNORE_LIST_SIZE then lootIgnoreListPos = 1 end
				lootIgnoreList[lootIgnoreListPos] = Lootable.Address
			end
		end
	end
end

-- Basic target evaluation.
-- Returns true if a valid target, else false.
function evalTargetDefault(address, target)
	local function debug_target(_place)
		if( settings.profile.options.DEBUG_TARGET and
			player.TargetPtr ~= player.LastTargetPtr ) then
			cprintf(cli.yellow, "[DEBUG] "..player.TargetPtr.." ".._place.."\n");
			player.LastTargetPtr = player.TargetPtr;		-- remember target address to avoid msg spam
		end
	end

	local function printNotTargetReason(_reason)
		if( player.TargetPtr ~= player.LastTargetPtr ) then
			cprintf(cli.yellow, "%s\n", _reason);
			player.LastTargetPtr = player.TargetPtr;		-- remember target address to avoid msg spam
		end
	end

	if not target then
		target = CPawn(address);
	end

	-- Can't have self as target
	if( address == player.Address ) then
		return false;
	end

	-- Not attackable
	if( not target.Attackable ) then
		return false;
	end

	-- Dead
	if( target.HP < 1 ) then
		return false;
	end

	-- Also dead (and has loot)
	if( target.Lootable ) then
		return false;
	end

	if( not target.Alive ) then
		return false;
	end

	-- Check height difference
	if( math.abs(target.Y - player.Y) > 45 ) then
		return false;
	end

	-- check level of target against our leveldif settings
	if( ( target.Level - player.Level ) > tonumber(settings.profile.options.TARGET_LEVELDIF_ABOVE)  or
	( player.Level - target.Level ) > tonumber(settings.profile.options.TARGET_LEVELDIF_BELOW)  ) then
		if ( player.Battling == false ) then	-- if we don't have aggro then
			debug_target("target lvl above/below profile settings without battling")
			return false;			-- he is not a valid target
		end;

		if( player.Battling == true  and		-- we have aggro
		target.TargetPtr ~= player.Address ) then	-- but not from that mob
			debug_target("target lvl above/below profile settings with battling from other mob")
			return false;
		end;
	end;

	-- check if we just ignored that target / ignore it for 10 sec
	if(address == player.Last_ignore_target_ptr  and
	   os.difftime(os.time(), player.Last_ignore_target_time)  < 10 )then
		if ( player.Battling == false ) then	-- if we don't have aggro then
			cprintf(cli.green, language[87], target.Name, 	-- We ignore %s for %s seconds.
			   10-os.difftime(os.time(), player.Last_ignore_target_time ) );
			debug_target("ignore that target for 10 sec (e.g. after doing no damage")
			return false;			-- he is not a valid target
		end;

		if( player.Battling == true  and		-- we have aggro
		target.TargetPtr ~= player.Address ) then	-- but not from that mob
			debug_target("we have aggro from another mob")
			return false;
		end;
	end

	-- check distance to target against MAX_TARGET_DIST
	if( distance(player.X, player.Z, target.X, target.Z) > settings.profile.options.MAX_TARGET_DIST ) then
		if ( player.Battling == false ) then	-- if we don't have aggro then
			debug_target("target dist > MAX_TARGET_DIST")
			return false;			-- he is not a valid target
		end;

		if( player.Battling == true  and		-- we have aggro
		target.TargetPtr ~= player.Address ) then	-- but not from that mob
			debug_target("target dist > MAX_TARGET_DIST with battling from other mob")
			return false;
		end;
	end;

	-- check if in assigned kill zone
	if (not player.Returning) and #__WPL.KillZone > 0 and not PointInPoly(__WPL.KillZone, target.X, target.Z) then
		if ( player.Battling == false ) then	-- if we don't have aggro then
			debug_target("target outside KillZone")
			return false;			-- he is not a valid target
		end;

		if( player.Battling == true  and		-- we have aggro
		target.TargetPtr ~= player.Address ) then	-- but not from that mob
			debug_target("target outside KillZone with battling from other mob")
			return false;
		end;
	end

	-- check if in one of the exclude zones
	if (not player.Returning) and next(__WPL.ExcludeZones) then
		local inazone = false
		for zonename,zone in pairs(__WPL.ExcludeZones) do
			if PointInPoly(zone, target.X, target.Z) then
				inazone = true
				break
			end
		end

		if inazone then
			if ( player.Battling == false ) then	-- if we don't have aggro then
				debug_target("target inside an exclude zone")
				return false;			-- he is not a valid target
			end;

			if( player.Battling == true  and		-- we have aggro
			target.TargetPtr ~= player.Address ) then	-- but not from that mob
				debug_target("target inside an exclude zone with battling from other mob")
				return false;
			end;
		end
	end

	-- check target distance to path against MAX_TARGET_DIST
	local wpl; -- this is the waypoint list we're using
	local V; -- this is the point we will use for distance checking

	if( player.Returning ) then
		wpl = __RPL;
	else
		wpl = __WPL;
	end

	if (__WPL:getMode() == "waypoints") and #__WPL.Waypoints > 0 then
		local pA = wpl.Waypoints[wpl.LastWaypoint]
		local pB = wpl.Waypoints[wpl.CurrentWaypoint]

		V = getNearestSegmentPoint(player.X, player.Z, pA.X, pA.Z, pB.X, pB.Z);
	else
		V = CWaypoint(player.X, player.Z); -- Distance check from player in wander mode
	end

	-- use a bounding box first to avoid sqrt when not needed (sqrt is expensive)
	if( target.X > (V.X - settings.profile.options.MAX_TARGET_DIST) and
		target.X < (V.X + settings.profile.options.MAX_TARGET_DIST) and
		target.Z > (V.Z - settings.profile.options.MAX_TARGET_DIST) and
		target.Z < (V.Z + settings.profile.options.MAX_TARGET_DIST) ) then

		if( distance(V.X, V.Z, target.X, target.Z) > settings.profile.options.MAX_TARGET_DIST ) then
			if ( player.Battling == false ) then	-- if we don't have aggro then
				debug_target("target dist > MAX_TARGET_DIST")
				return false;			-- he is not a valid target
			end;

			if( player.Battling == true  and		-- we have aggro
			target.TargetPtr ~= player.Address ) then	-- but not from that mob
				debug_target("target dist > MAX_TARGET_DIST with battling from other mob")
				return false;
			end;
		end;
	else
		-- must be too far away
		debug_target("target dist > MAX_TARGET_DIST")
		return false;
	end


	-- PK protect
	if settings.profile.options.PVP ~= true then
		if( target.Type == PT_PLAYER ) then      -- Player are type == 1
			if ( player.Battling == false ) then   -- if we don't have aggro then
				debug_target("PK player, but not fighting us")
				return false;         -- he is not a valid target
			end;

			if( player.Battling == true  and         -- we have aggro
				target.TargetPtr ~= player.Address ) then   -- but not from the PK player
				debug_target("PK player, aggro, but he don't target us")
				return false;
			end;
		end;
	end
	-- Friends aren't enemies
	if( player:isFriend(target) ) then
		if ( player.Battling == false ) then   -- if we don't have aggro then
			debug_target("target is in friends")
			return false;		-- he is not a valid target
		end;

		if( player.Battling == true  and         -- we have aggro, check if the 'friend' is targeting us
			target.TargetPtr ~= player.Address ) then   -- but not from that target
			debug_target("target is in friends, aggro, but not from that target")
			return false;
		end;
	end;

	-- Pets aren't enemies
	if( target.Address == player.Pet.Address ) then
		return false;
	end

	-- Mob limitations defined?
	if( #settings.profile.mobs > 0 ) then
		if( player:isInMobs(target) == false ) then
			if ( player.Battling == false ) then   -- if we don't have aggro then
				debug_target("mob limitation is set, mob is not a valid target")
				return false;		-- he is not a valid target
			end;

			if( player.Battling == true  and         -- we have aggro, check if the 'friend' is targeting us
				target.TargetPtr ~= player.Address ) then   -- but not from that target
				debug_target("mob limitation is set, mob is not a valid target, aggro, but not from that target")
				return false;
			end;
		end;
	end;

	-- target is to strong for us
	if (settings.profile.options.PARTY_INSTANCE ~= true ) then
		if( target.MaxHP > player.MaxHP * settings.profile.options.AUTO_ELITE_FACTOR ) then
			if ( player.Battling == false ) then	-- if we don't have aggro then
	--				debug_target("target is to strong. More HP then self.MaxHP * settings.profile.options.AUTO_ELITE_FACTOR")
				printNotTargetReason("Target is to strong. More HP then player.MaxHP * settings.profile.options.AUTO_ELITE_FACTOR")
				return false;		-- he is not a valid target
			end;

			if( player.Battling == true  and		-- we have aggro, check if the 'friend' is targeting us
				target.TargetPtr ~= player.Address ) then		-- but not from that target
	--				debug_target("target is to strong. More HP then self.MaxHP * settings.profile.options.AUTO_ELITE_FACTOR, aggro, but not from that target")
				printNotTargetReason("Target is to strong. More HP then player.MaxHP * settings.profile.options.AUTO_ELITE_FACTOR, aggro, but not from that target")
				return false;
			end;
		end;
	end

	-- don't target NPCs
	if( target.Type == PT_NPC ) then      -- NPCs are type == 4
		debug_target("thats a NPC, he should be friendly and not attackable")
		return false;         -- he is not a valid target
	end;

	if( settings.profile.options.ANTI_KS ) then
		if( target.TargetPtr ~= player.Address ) then
			-- If the target's TargetPtr is 0,
			-- that doesn't necessarily mean they don't
			-- have a target (game bug, not a bug in the bot)
			if( target.TargetPtr == 0 ) then
				if( target.HP < target.MaxHP ) then
					debug_target("anti kill steal: target not fighting us: target not targeting us")
					return false;
				end
			else
				-- They definitely have a target.
				-- If it is a friend, we can help.
				-- Otherwise, leave it alone.

				local targetOfTarget = CPawn(target.TargetPtr);

				if( not player:isFriend(targetOfTarget) ) then
					debug_target("anti kill steal: target not fighting us: target don't targeting a friend")
					return false;
				end
			end
		end
	end

	return true;
end

function CPlayer:moveTo(waypoint, ignoreCycleTargets, dontStopAtEnd, range)

	local function passed_point(lastpos, point)
		point.X = tonumber(point.X)
		point.Z = tonumber(point.Z)

		local posbuffer = 5

		local passed = true
		if lastpos.X < point.X and self.X < point.X - posbuffer then
			return false
		end
		if lastpos.X > point.X and self.X > point.X + posbuffer then
			return false
		end
		if lastpos.Z < point.Z and self.Z < point.Z - posbuffer then
			return false
		end
		if lastpos.Z > point.Z and self.Z > point.Z + posbuffer then
			return false
		end

		return true
	end

	self:update();
	local lastpos = {X=self.X, Z=self.Z, Y=self.Y}

	local angle = math.atan2(waypoint.Z - self.Z, waypoint.X - self.X);
	local yangle = 0
	if waypoint.Y ~= nil then
		yangle = math.atan2(waypoint.Y - self.Y, ((waypoint.X - self.X)^2 + (waypoint.Z - self.Z)^2)^.5 );
	end
	local angleDif = angleDifference(angle, self.Direction);
	local startTime = os.time();
	ignoreTargets = ignoreTargets or false;

	if( ignoreCycleTargets == nil ) then
		ignoreCycleTargets = false;
	end;

	if( waypoint.Type == WPT_TRAVEL or waypoint.Type == WPT_RUN ) then
		if( settings.profile.options.DEBUG_TARGET ) then
			cprintf(cli.yellow, "[DEBUG] waypoint type RUN or TRAVEL. We don't target mobs.\n");
		end
		ignoreCycleTargets = true;	-- don't target mobs
	end;

	-- Make sure we don't have a garbage (dead) target
	if( self.TargetPtr ~= 0 ) then
		local target = CPawn(self.TargetPtr);
		if( target.HP <= 1 ) then
			self:clearTarget();
		end
	end

	-- no active turning and moving if wander and radius = 0
	-- self direction has values from 0 til Pi and -Pi til 0
	-- angle has values from 0 til 2*Pi
	if(__WPL:getMode()   == "wander"  and
	   __WPL:getRadius() == 0     )   then
	   	self:restrnd(100, 1, 4);	-- wait 3 sec
		if( self.Direction < 0 ) then
			angle = (math.pi * 2) - math.abs(self.Direction);
		else
			angle = self.Direction;
		end;

		-- we will not move back to WP if wander and radius = 0
		-- so one can move the character manual and use the bot only as fight support
		-- there we set the WP to the actual player position
		waypoint.Z = self.Z;
		waypoint.X = self.X;

	end;

	-- QUICK_TURN only
	if( settings.profile.options.QUICK_TURN == true ) then
		self:faceDirection(angle, yangle);
		camera:setRotation(angle);
		self:update();
		angleDif = angleDifference(angle, self.Direction);
	else
		self:faceDirection(self.Direction, yangle); -- change only 'Y' angle with 'faceDirection'.
	end

	-- If more than X degrees off, correct before moving.
	local rotateStartTime = os.time();
	local turningDir = -1; -- 0 = left, 1 = right
	while( angleDif > math.rad(65) ) do
		if( self.HP < 1 or self.Alive == false ) then
			return false, WF_NONE;
		end;

		if( os.difftime(os.time(), rotateStartTime) > 3.0 ) then
			-- Sometimes both left and right rotate get stuck down.
			-- Press them both to make sure they are fully released.
			keyboardPress(settings.hotkeys.ROTATE_LEFT.key);
			keyboardPress(settings.hotkeys.ROTATE_RIGHT.key);

			-- we seem to have been distracted, take a step back.
			keyboardPress(settings.hotkeys.MOVE_BACKWARD.key);
			rotateStartTime = os.time();
		end

		if( angleDifference(angle, self.Direction + 0.01) < angleDif ) then
			-- rotate left
			keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );
			keyboardHold( settings.hotkeys.ROTATE_LEFT.key );

			--self:faceDirection( angle );
		else
			-- rotate right
			keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
			keyboardHold( settings.hotkeys.ROTATE_RIGHT.key );

			--self:faceDirection( angle );
		end

		yrest(50);
		self:update();
		angleDif = angleDifference(angle, self.Direction);
	end

	keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
	keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );

	-- look for a target before start movig
	if( (not ignoreCycleTargets) and (not self.Battling) ) then
		local newTarget = self:findEnemy(false, nil, evalTargetDefault, self.IgnoreTarget);
		if( newTarget ) then			-- find a new target
			self:target(newTarget.Address);
			local atkMask = memoryReadRepeat("int", getProc(), newTarget.Address + addresses.pawnAttackable_offset);
			cprintf(cli.turquoise, language[86]);	-- stopping waypoint::target acquired before moving
			success = false;
			failreason = WF_TARGET;
			return success, failreason;
		end;
	end;

	-- Direction ok, start moving forward
	local success, failreason = true, WF_NONE;
	local dist = distance(self.X, self.Z, self.Y, waypoint.X, waypoint.Z, waypoint.Y);
	local lastDist = dist;
	self.LastDistImprove = os.time();	-- global, because we reset it whil skill use

	local turning = false

	local loopstart
	local loopduration = 100 -- The duration we want the loop to take
	local successdist = 10
	repeat
		loopstart = os.clock()

		if( self.HP < 1 or self.Alive == false ) then
			return false, WF_NONE;
		end;

		-- stop moving if aggro, bot will stand and wait until to get the target from the client
	 	-- only if not in the fight stuff coding (means self.Fighting == false )
	 	if( self.Battling and 				-- we have aggro
	 	    self.Fighting == false  and		-- we are not coming from the fight routines (bec. as melee we should move in fight)
			waypoint.Type ~= WPT_TRAVEL ) then	-- only stop if not waypoint type TRAVEL
			if self:findEnemy(true, nil, evalTargetDefault) then
				keyboardRelease( settings.hotkeys.MOVE_FORWARD.key );
				keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
				keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );
				success = false;
				failreason = WF_COMBAT;
				break;
			end
		end;

		-- look for a new target while moving
		if((not ignoreCycleTargets) and (not self.Battling) and (not turning)) then
			local newTarget = self:findEnemy(false, nil, evalTargetDefault, self.IgnoreTarget);
			if( newTarget ) then	-- find a new target
				self:target(newTarget);
				cprintf(cli.turquoise, language[28]);	-- stopping waypoint::target acquired
				success = false;
				failreason = WF_TARGET;
				break;
			end;
		end

		-- We're still making progress
		if( dist < lastDist ) then
			self.LastDistImprove = os.time();
			lastDist = dist;
		elseif(  dist > lastDist + 40 ) then
			-- Make sure we didn't pass it up
			printf(language[29]);
			success = false;
			failreason = WF_DIST;
			break;
		end;

		if( os.difftime(os.time(), self.LastDistImprove) > 3 ) then
			-- We haven't improved for 3 seconds, assume stuck
			success = false;
			failreason = WF_STUCK;
			break;
		end

		-- while moving without target: check potions / friendly skills
		if not self.Mounted and ( self:checkPotions() or self:checkSkills(ONLY_FRIENDLY) ) then	-- only cast friendly spells to ourselfe
			-- If we used a potion or a skill, reset our last dist improvement
			-- to prevent unsticking
			self.LastDistImprove = os.time();

			-- Wait for casting to finish if still casting last skill
			while self.Casting do
				yrest(50)
				self:update()
			end

		end

		dist = distance(self.X, self.Z, self.Y, waypoint.X, waypoint.Z, waypoint.Y);
		angle = math.atan2(waypoint.Z - self.Z, waypoint.X - self.X);

		-- Check if within range if range specified
		if range and range > dist then
			-- within range
			break
		end

		-- Check if past waypoint
		if passed_point(lastpos, waypoint) then
		   -- waypoint reached
		   break
		end

		-- Check if close to waypoint.
		if dist < successdist then
			break
		end

		lastpos = {X=self.X, Z=self.Z, Y=self.Y}

		if waypoint.Y ~= nil then
			yangle = math.atan2(waypoint.Y - self.Y, ((waypoint.X - self.X)^2 + (waypoint.Z - self.Z)^2)^.5 );
		end
		angleDif = angleDifference(angle, self.Direction);

		-- Continue to make sure we're facing the right direction
		if( settings.profile.options.QUICK_TURN and angleDif > math.rad(1) ) then
			self:faceDirection(angle, yangle);
			camera:setRotation(angle);
			self:update()
			angleDif = angleDifference(angle, self.Direction);
			keyboardHold( settings.hotkeys.MOVE_FORWARD.key );
		else
			self:faceDirection(self.Direction, yangle); -- change only 'Y' angle with 'faceDirection'.

			if( angleDif > math.rad(15) ) then
				--keyboardRelease( settings.hotkeys.MOVE_FORWARD.key );
				--keyboardRelease( settings.hotkeys.MOVE_BACKWARD.key );

				if( angleDifference(angle, self.Direction + 0.01) < angleDif ) then
						keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );
						keyboardHold( settings.hotkeys.ROTATE_LEFT.key );
						yrest(100);
				else
						keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
						keyboardHold( settings.hotkeys.ROTATE_RIGHT.key );
						yrest(100);
				end
				turning = true
			elseif( angleDif > math.rad(1) ) then
				if( settings.profile.options.QUICK_TURN ) then
					camera:setRotation(angle);
				end

				self:faceDirection(angle, yangle);
				keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
				keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );
				keyboardHold( settings.hotkeys.MOVE_FORWARD.key );
				turning = false
			else
				keyboardHold( settings.hotkeys.MOVE_FORWARD.key );
			end
		end


		--keyboardHold( settings.hotkeys.MOVE_FORWARD.key );
		local pausetime = loopduration - (os.clock() - loopstart) -- minus the time already elapsed.
		if pausetime < 1 then pausetime = 1 end
		yrest(pausetime);
		self:update();
		waypoint:update();

	until false

	if (settings.profile.options.WP_NO_STOP ~= false) then
		if (success == false) or (dontStopAtEnd ~= true) or (settings.profile.options.QUICK_TURN == false) then
			keyboardRelease( settings.hotkeys.MOVE_FORWARD.key );
		end
	else
		keyboardRelease( settings.hotkeys.MOVE_FORWARD.key );
	end

	keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
	keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );

	return success, failreason;
end

function CPlayer:moveInRange(target, range, ignoreCycleTargets)
	self:moveTo(target, ignoreCycleTargets, nil, range)
end

function CPlayer:waitForAggro()
	local startTime = os.time();

	while( self.Battling and self.TargetPtr == 0 ) do
		yrest(100);
		self:update();

		if( os.difftime(os.time(), startTime) > 5 ) then
			-- Wait no more than 5 seconds
			break;
		end
	end

	if( self.TargetPtr ) then
		self:fight();
	end
end

-- Forces the player to face a direction.
-- 'dir' should be in radians
function CPlayer:faceDirection(dir,diry)
	local Vec3 = 0
	if diry then
		Vec3 = math.sin(diry);
	else
		Vec3 = memoryReadRepeat("float", getProc(), self.Address + addresses.pawnDirYUVec_offset);
	end
	local hypotenuse = (1 - Vec3^2)^.5
	local Vec1 = math.cos(dir) * hypotenuse;
	local Vec2 = math.sin(dir) * hypotenuse;

	self.Direction = math.atan2(Vec2, Vec1);
	self.DirectionY = math.atan2(Vec3, (Vec1^2 + Vec2^2)^.5 );

	local tmpMountAddress = memoryReadRepeat("int", getProc(), self.Address + addresses.charPtrMounted_offset);
	if self.Mounted and tmpMountAddress and tmpMountAddress ~= 0 then
		memoryWriteFloat(getProc(), tmpMountAddress + addresses.pawnDirXUVec_offset, Vec1);
		memoryWriteFloat(getProc(), tmpMountAddress + addresses.pawnDirZUVec_offset, Vec2);
		memoryWriteFloat(getProc(), tmpMountAddress + addresses.pawnDirYUVec_offset, Vec3);
	else
		memoryWriteFloat(getProc(), self.Address + addresses.pawnDirXUVec_offset, Vec1);
		memoryWriteFloat(getProc(), self.Address + addresses.pawnDirZUVec_offset, Vec2);
		memoryWriteFloat(getProc(), self.Address + addresses.pawnDirYUVec_offset, Vec3);
	end
end

-- turns the player at a given angel in grad
function CPlayer:turnDirection(_angle)
-- negative values means 'turn' left
-- positive values means 'turn' right
-- self.Direction values are from 0 til Pi and -Pi til 0 / 0 is at East

	local hf_new_direction;
	if( _angle < 0 ) then
		hf_new_direction = self.Direction-math.rad(_angle);	-- neg angle value result in neg rad values
	elseif ( _angle > 0 ) then
		hf_new_direction = self.Direction-math.rad(_angle);
	else
		hf_new_direction = self.Direction;
	end;

	if(hf_new_direction > math.pi) then 		-- values gt 3,14
		hf_new_direction = hf_new_direction - 2* math.pi;
	elseif (hf_new_direction < -math.pi) then 	-- value lt -3,14
		hf_new_direction = hf_new_direction + 2* math.pi;
	end

	self:faceDirection(hf_new_direction);	-- turn character
	camera:setRotation(hf_new_direction);	-- turn camera view behind character
end


-- Attempt to unstick the player
function CPlayer:unstick()
-- after 2x unsuccesfull unsticks try to reach last waypoint
	if( self.Unstick_counter == 3 ) then
	if unStick3 then
  			unStick3()
	elseif( self.Returning ) then
			__RPL:backward();
		else
			__WPL:backward();
		end;
		return;

	end


-- after 5x unsuccesfull unsticks try to reach next waypoint after sticky one
	if( self.Unstick_counter == 6 ) then
	if unStick6 then
  			unStick6()
	elseif( self.Returning ) then
			__RPL:advance();	-- forward to sticky wp
			__RPL:advance();	-- and one more
		else
			__WPL:advance();	-- forward to sticky wp
			__WPL:advance();	-- and one more
		end;
		return;

	end


-- after 8x unstick try to run away a little and then go to the nearest waypoint
	if( self.Unstick_counter == 9 ) then
	if unStick9 then
  			unStick9()
	else
	 	-- turn and move back for 10 seconds
		keyboardHold(settings.hotkeys.ROTATE_RIGHT.key);
		yrest(1900);
		keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );
		keyboardHold(settings.hotkeys.MOVE_FORWARD.key);
		yrest(10000);
		keyboardRelease(settings.hotkeys.MOVE_FORWARD.key);
		self:update();
		if( self.Returning ) then
			__RPL:setWaypointIndex(__RPL:getNearestWaypoint(self.X, self.Z));
		else
			__WPL:setWaypointIndex(__WPL:getNearestWaypoint(self.X, self.Z));
		end;
		return;
	end;
	end

 	-- Move back for x seconds
	keyboardHold(settings.hotkeys.MOVE_BACKWARD.key);
	yrest(1000);
	keyboardRelease(settings.hotkeys.MOVE_BACKWARD.key);

	-- Straff either left or right now
	local straffkey = 0;
	if( math.random(100) < 50 ) then
		straffkey = settings.hotkeys.STRAFF_LEFT.key;
	else
		straffkey = settings.hotkeys.STRAFF_RIGHT.key;
	end

	local straff_bonus = self.Unstick_counter * 120;
	keyboardHold(straffkey);
	yrest(500 + math.random(500) + straff_bonus);
	keyboardRelease(straffkey);

	-- try to jump over a obstacle
	if( self.Unstick_counter > 1 ) then
		if( self.Unstick_counter == 2 ) then
			keyboardHold(settings.hotkeys.MOVE_FORWARD.key);
			yrest(550);
			keyboardPress(settings.hotkeys.JUMP.key);
			yrest(400);
			keyboardRelease(settings.hotkeys.MOVE_FORWARD.key);
		elseif( math.random(100) < 80 ) then
			keyboardHold(settings.hotkeys.MOVE_FORWARD.key);
			yrest(600);
			keyboardPress(settings.hotkeys.JUMP.key);
			yrest(400);
			keyboardRelease(settings.hotkeys.MOVE_FORWARD.key);
		end;
	end;

end

function CPlayer:haveTarget()

	if( CPawn.haveTarget(self) ) then
		local target = self:getTarget();
			 local targettarget = CPawn(target.TargetPtr)
		local function debug_target(_place)
			if( settings.profile.options.DEBUG_TARGET and
				self.TargetPtr ~= self.LastTargetPtr ) then
				cprintf(cli.yellow, "[DEBUG] "..self.TargetPtr.." ".._place.."\n");
				self.LastTargetPtr = self.TargetPtr;		-- remember target address to avoid msg spam
			end
		end

		local function printNotTargetReason(_reason)
			if( self.TargetPtr ~= self.LastTargetPtr ) then
				cprintf(cli.yellow, "%s\n", _reason);
				self.LastTargetPtr = self.TargetPtr;		-- remember target address to avoid msg spam
			end
		end




		if( target == nil ) then
			return false;
		end;

		-- check level of target against our leveldif settings
		if( ( target.Level - self.Level ) > tonumber(settings.profile.options.TARGET_LEVELDIF_ABOVE)  or
		( self.Level - target.Level ) > tonumber(settings.profile.options.TARGET_LEVELDIF_BELOW)  ) then
			if ( self.Battling == false ) then	-- if we don't have aggro then
				debug_target("target lvl above/below profile settings without battling")
				return false;			-- he is not a valid target
			end;

			if( self.Battling == true  and		-- we have aggro
			target.TargetPtr ~= self.Address and  targettarget.InParty ~= true ) then	-- but not from that mob
				debug_target("target lvl above/below profile settings with battling from other mob")
				return false;
			end;
		end;

		-- check if we just ignored that target / ignore it for 10 sec
		if(self.TargetPtr == self.Last_ignore_target_ptr  and
		   os.difftime(os.time(), self.Last_ignore_target_time)  < 10 )then
			if ( self.Battling == false ) then	-- if we don't have aggro then
				cprintf(cli.green, language[87], target.Name, 	-- We ignore %s for %s seconds.
				   10-os.difftime(os.time(), self.Last_ignore_target_time ) );
				debug_target("ignore that target for 10 sec (e.g. after doing no damage")
				return false;			-- he is not a valid target
			end;

			if( self.Battling == true  and		-- we have aggro
			target.TargetPtr ~= self.Address and targettarget.InParty ~= true ) then	-- but not from that mob
				debug_target("we have aggro from another mob")
				return false;
			end;
		end

		-- check distance to target against MAX_TARGET_DIST
		if( distance(self.X, self.Z, target.X, target.Z) > settings.profile.options.MAX_TARGET_DIST ) then
			if ( self.Battling == false ) then	-- if we don't have aggro then
				debug_target("target dist > MAX_TARGET_DIST")
				return false;			-- he is not a valid target
			end;

			if( self.Battling == true  and		-- we have aggro
			target.TargetPtr ~= self.Address and targettarget.InParty ~= true ) then	-- but not from that mob
				debug_target("target dist > MAX_TARGET_DIST with battling from other mob")
				return false;
			end;
		end;


		-- PK protect
		if settings.profile.options.PVP ~= true then
			if( target.Type == PT_PLAYER ) then      -- Player are type == 1
				if ( self.Battling == false ) then   -- if we don't have aggro then
					debug_target("PK player, but not fighting us")
					return false;         -- he is not a valid target
				end;

				if( self.Battling == true  and         -- we have aggro
					target.TargetPtr ~= self.Address and targettarget.InParty ~= true ) then   -- but not from the PK player
					debug_target("PK player, aggro, but he don't target us")
					return false;
				end;
			end;
		end
		-- Friends aren't enemies
		if( self:isFriend(target) ) then
			if ( self.Battling == false ) then   -- if we don't have aggro then
				debug_target("target is in friends")
				return false;		-- he is not a valid target
			end;

			if( self.Battling == true  and         -- we have aggro, check if the 'friend' is targeting us
				target.TargetPtr ~= self.Address and targettarget.InParty ~= true ) then   -- but not from that target
				debug_target("target is in friends, aggro, but not from that target")
				return false;
			end;
		end;

		-- Pets aren't enemies
		if( target.Address == self.Pet.Address ) then
			printf("Pet is not an enemy\n");
			return false;
		end

		-- Mob limitations defined?
		if( #settings.profile.mobs > 0 ) then
			if( self:isInMobs(target) == false ) then
				if ( self.Battling == false ) then   -- if we don't have aggro then
					debug_target("mob limitation is set, mob is not a valid target")
					return false;		-- he is not a valid target
				end;

				if( self.Battling == true  and         -- we have aggro, check if the 'friend' is targeting us
					target.TargetPtr ~= self.Address and targettarget.InParty ~= true ) then   -- but not from that target
					debug_target("mob limitation is set, mob is not a valid target, aggro, but not from that target")
					return false;
				end;
			end;
		end;

		-- target is to strong for us
	if  (settings.profile.options.PARTY_INSTANCE ~= true) then
		if( target.MaxHP > self.MaxHP * settings.profile.options.AUTO_ELITE_FACTOR ) then
			if ( self.Battling == false ) then	-- if we don't have aggro then
--				debug_target("target is to strong. More HP then self.MaxHP * settings.profile.options.AUTO_ELITE_FACTOR")
				printNotTargetReason("Target is to strong. More HP then self.MaxHP * settings.profile.options.AUTO_ELITE_FACTOR")
				return false;		-- he is not a valid target
			end;

			if( self.Battling == true  and		-- we have aggro, check if the 'friend' is targeting us
				target.TargetPtr ~= self.Address and targettarget.InParty ~= true ) then		-- but not from that target
--				debug_target("target is to strong. More HP then self.MaxHP * settings.profile.options.AUTO_ELITE_FACTOR, aggro, but not from that target")
				printNotTargetReason("Target is to strong. More HP then self.MaxHP * settings.profile.options.AUTO_ELITE_FACTOR, aggro, but not from that target")
				return false;
			end;
		end;
	end

		-- don't target NPCs
		if( target.Type == PT_NPC ) then      -- NPCs are type == 4
			debug_target("thats a NPC, he should be friendly and not attackable")
			return false;         -- he is not a valid target
		end;
			local targettarget = CPawn(target.TargetPtr)
		if( settings.profile.options.ANTI_KS ) then
-- why do we check the attackable flag only within the ANTI_KS?
-- I delete it because of the PK player bug (not attackable) / d003232 17.10.09
			-- Not a valid enemy
--			if( not target.Attackable ) then
--				printf(language[30], target.Name);
--				debug_target("anti kill steal: target not attackable")
--				return false;
--			end


			-- If they aren't targeting us, and they have less than full HP
			-- then they must be fighting somebody else.
			-- If it's a friend, then it is a valid target; help them.
			if( target.TargetPtr ~= self.Address and targettarget.InParty ~= true ) then

				-- If the target's TargetPtr is 0,
				-- that doesn't necessarily mean they don't
				-- have a target (game bug, not a bug in the bot)
				if( target.TargetPtr == 0 ) then
					if( target.HP < target.MaxHP ) then
						debug_target("anti kill steal: target not fighting us: target not targeting us")
						return false;
					end
				else
					-- They definitely have a target.
					-- If it is a friend, we can help.
					-- Otherwise, leave it alone.

					local targetOfTarget = CPawn(target.TargetPtr);

					if( not self:isFriend(targetOfTarget) ) then
						debug_target("anti kill steal: target not fighting us: target don't targeting a friend")
						return false;
					end
				end
			end

			return true;
		else
			return true;
		end
	else
		return false;
	end
end

function CPlayer:clearTarget()
	cprintf(cli.green, language[33]);
	memoryWriteInt(getProc(), self.Address + addresses.pawnTargetPtr_offset, 0);
	self.TargetPtr = 0;
	self.Cast_to_target = 0;

	RoMScript("TargetFrame:Hide()");
end

-- returns true if this CPawn is registered as a friend
function CPlayer:isFriend(pawn)
	if( not pawn ) then
		error("CPlayer:isFriend() received nil\n", 2);
	end;

	-- Pets are friends
	if( pawn.Address == self.PetPtr ) then
		return true;
	end

	if( not settings ) then
		return false;
	end;

	pawn:update();

	for i,v in pairs(settings.profile.friends) do
		if( string.find( string.lower(pawn.Name), string.lower(v), 1, true) ) or tonumber(v) == pawn.Id then
			return true;
		end
	end

	return false;
end


-- returns true if target is in mobs
function CPlayer:isInMobs(pawn)
	if( not pawn ) then
		error("CPlayer:isInMobs() received nil\n", 2);
	end;

	for i,v in pairs(settings.profile.mobs) do
		mobs_defined = true;
		if( string.find( string.lower(pawn.Name), string.lower(v), 1, true) ) or tonumber(v) == pawn.Id then
			return true;
		end
	end

	return false;
end


function CPlayer:logoutCheck()
-- timed logout check

	if(self.Battling == true) then
		return;
	end;

	if( settings.profile.options.LOGOUT_TIME > 0 ) then
		local elapsed = os.difftime(os.time(), self.BotStartTime);

		if( elapsed >= settings.profile.options.LOGOUT_TIME * 60 ) then
			cprintf(cli.yellow, language[53], math.ceil(elapsed/60), settings.profile.options.LOGOUT_TIME );	-- Logout elapsed > planned
			self:logout();
		end
	end
end

function CPlayer:logout(fc_shutdown, logout_close)
-- importing:
--   fc_shutdown true/false/nil
--   if nil, profile option 'settings.profile.options.LOGOUT_SHUTDOWN'
--   will decide if shutdown or not occurs

-- If logout_close is 'true' it will close the client
--   otherwise it will just logout to character selection.

	cprintf(cli.yellow, language[50], os.date() );	-- Logout at %time%

	if( fc_shutdown == nil  and  settings.profile.options.LOGOUT_SHUTDOWN == true ) then
		fc_shutdown = true;
	end;

	if logout_close == true then
		local PID = findProcessByWindow(getWin()); -- Get process ID
		os.execute("TASKKILL /PID " .. PID .. " /F");
		while(true) do
			-- Wait for process to close...
			if( findProcessByWindow(__WIN) ~= PID ) then
				printf(language[88]);
				break;
			end;
			yrest(100);
		end
	else
		-- Close all windows to avoid problems when relogging.
		RoMScript("CloseAllWindows()") yrest(500)

		RoMScript("Logout();");
		yrest(30000); -- Wait for the log out to process
	end

	if( fc_shutdown ) then
		cprintf(cli.yellow, language[51]);
		os.execute("\"%windir%\\system32\\shutdown.exe -s -t 30\" "); --Shutdown in 30 seconds.
	end

	error("Exiting: Auto-logout", 0); -- Not really an error, but it will drop us back to shell.

end

function CPlayer:check_aggro_before_cast(_jump, _skill_type)
-- break cast in last moment / works not for groups, because you get battling flag from your groupmembers  !!!
-- works also if target is not visible and we get aggro from another mob
-- _jump = true       abort cast with jump hotkey

	self:update();
	local target = self:getTarget();
	local targettarget = CPawn(target.TargetPtr)

	if( self.Battling == false )  then		-- no aggro
		return false;
	end;

		-- don't break friendly skills
	if( _skill_type == STYPE_HEAL  or
	    _skill_type == STYPE_BUFF  or
	    _skill_type == STYPE_HOT ) then
		return false;
	end

	if target.TargetPtr == self.Address or
	targettarget.InParty == true then
		return false;
	end

	local target = self:getTarget();
	if( self.TargetPtr ~= 0 ) then  target:update(); end;

	-- don't break if no target or self targeting
	if( target.Name == "<UNKNOWN>"  or
	    self.TargetPtr == self.Address) then
		return false;
	end


	-- check if the target is attacking us, if not we can break and take the other mob

	if( target.TargetPtr ~= self.Address and	-- check HP, because death targets also have not target
	-- Fix: there is aspecial dog mob 'Tatus', he switch from red to green at about 90%
	-- there seems to be a bug, so that sometimes Tatus don't have us into the target but still attacking us
	-- to prevent from skipping him while he is still attacking us, we do that special fix
		target.Name ~= "Tatus"	and
		-- even he is attacking us
		target.TargetPtr ~= self.PetPtr and
	    target.HP/target.MaxHP*100 > 90	) then
		-- target is alive and not attacking us
-- there is a bug in client. Sometimes target is death and so it is not targeting us anymore
-- and at the same time the target HP are above 0
-- so we say > 90% life is alive :-)

		cprintf(cli.green, language[36], target.Name);	-- Aggro during first strike/cast
		self:clearTarget();

		-- try fo find the aggressore a little faster by targeting it itselfe instead of waiting from the client
		if( self:findTarget() ) then	-- we found a target
			local target = self:getTarget();
			if( target.TargetPtr == self.Address or target.TargetPtr == self.PetPtr ) then	-- it is the right aggressor
				cprintf(cli.green, "%s is attacking us, we take that target.\n", target.Name);	-- attacking us
			else
				cprintf(cli.green, "%s is not attacking us, we clear that target.\n", target.Name);	-- not attacking us
				self:clearTarget();
			end
		end
	end

	if self.Class1 == CLASS_WARDEN then -- has issues with pet as target, temp fix.
		return false
	end

	return true;

end

-- find a target with the ingame target key
-- is used while moving and could also used before moving or after fight
function CPlayer:findTarget()

	-- check if automatic targeting is active
	if( settings.profile.options.AUTO_TARGET == false ) then
		return false;
	end

	keyboardPress(settings.hotkeys.TARGET.key, settings.hotkeys.TARGET.modifier);

	yrest(10);

	-- We've got a target, fight it instead of worrying about our waypoint.

	if( self:haveTarget() ) then
	-- all other checks are within the self:haveTarget(), so the target should be ok

		local target = self:getTarget();
		local dist = distance(self.X, self.Z, target.X, target.Z);
		cprintf(cli.green, language[37], target.Name, dist);	-- Select new target %s in distance

		return true;
	else
		return false;
	end;

end


function CPlayer:rest(_restmin, _restmax, _resttype, _restaddrnd)
-- rest to restore mana and healthpoint if under a certain level
-- this function could also be used, if you want to rest in a waypoint file, it will
-- detect aggro while resting and fight back
--
--  player:rest( _restfix,[ _restrnd[, time|full[, _restaddrnd]]])
--
-- _restmin  ( minimum rest time in sec)
-- _restmax  ( maximum rest time sec)
-- _resttype ( time / full )  time = rest the given time  full = stop resting after being full   default = time
-- _restaddrnd  ( max random addition after being full in sec)
--
--
-- e.g.
-- player:rest(20)                 will rest for 20 seconds.
-- player:rest(60, 80)             will rest between 60 and 80 seconds.
-- player:rest(90, 130, "full")     will rest up to between 90 and 130 seconds, and stop resting
--                                 if being full
-- player:rest(20, 60, "full, 20") will rest up to between 20 and 60 seconds, and stop resting
--                                 if being full, and wait after that between 1-20 seconds
--
-- to look not so bottish, please use the random time options!!!
--
	self:update();
	if( self.Battling == true) then return; end;		-- if aggro, go back

	-- Stop if moving
	keyboardRelease( settings.hotkeys.MOVE_FORWARD.key );

	local hf_resttime;

	-- setting default values
	if( _restmin     == nil  or  _restmin  == 0 )   then _restmin     = 10; end;
	if( _restmax     == nil  or  _restmax  == 0 )   then _restmax     = _restmin; end;
	if( _resttype    == nil )                       then _resttype    = "time"; end;	-- default restype is 'time"

	if ( _restmax >  _restmin ) then
		hf_resttime = _restmin + math.random( _restmax - _restmin );
	else
		hf_resttime = _restmin;
	end;

	if( _restaddrnd  == nil  or  _restaddrnd == 0 ) then _restaddrnd  = 0;
	else _restaddrnd  = math.random( _restaddrnd ); end;

	-- some classes dont have mana, in that cases Player.mana = 0
	local hf_mana_rest = (self.MaxMana * settings.profile.options.MP_REST / 100);	-- rest if mana is lower then
	local hf_hp_rest   = (self.MaxHP   * settings.profile.options.HP_REST / 100);	-- rest if HP is lower then

	local restStart = os.time();		-- set start timer

	if( _resttype == "full") then
		cprintf(cli.green, language[38], ( hf_resttime ) );		-- Resting up to %s to fill up mana and HP
	else
		cprintf(cli.green, language[71], ( hf_resttime ) );		-- Resting for %s seconds.
	end;

	-- check before we perhaps sit down
	self:checkPotions();
	self:checkSkills( ONLY_FRIENDLY ); 		-- only cast friendly spells to ourselfe

	-- sit option is false as default and the option is not promoted
	-- simply because if you misconfigure the rest option / don't use potions you will
	-- rest and sit after every fight and that looks really bottish
	local we_sit = false;
	if( _resttype == "full" and			-- only sit for full rest, not for times restings
		settings.profile.options.SIT_WHILE_RESTING ) then
		RoMScript("SitOrStand()");
		we_sit = true;
	end;

	while ( true ) do

		self:update();

		if( self.Battling ) then          -- we get aggro,
			self:clearTarget();      -- get rid of mob to be able to target attackers
			cprintf(cli.green, language[39] );   -- get aggro
			break;
		end;

		-- check if resttime finished
		if( os.difftime(os.time(), restStart ) > ( hf_resttime ) ) then
			cprintf(cli.green, language[70], ( hf_resttime ) );   -- Resting finished after %s seconds
			break;
		end;

		-- check if HP/Mana full
		if( self.Mana == self.MaxMana  and		-- some chars have MaxMana = 0
 	 	    self.HP   == self.MaxHP    and
 	 	    _resttype   == "full" ) then		-- Mana and HP are full
			local restAddStart = os.time();		-- set additional rest timer
			while ( true ) do	-- rnd addition
				self:update();
				if( os.difftime(os.time(), restAddStart ) > _restaddrnd ) then
					break;
				end;
				if( self.Battling ) then          -- we get aggro,
					self:clearTarget();      -- get rid of mob to be able to target attackers
					cprintf(cli.green, language[39] );   -- Stop resting because of aggro
					break;
				end;
				self:checkPotions();
				self:checkSkills( ONLY_FRIENDLY ); 		-- only cast friendly spells to ourselfe
				yrest(100);
			end;

			cprintf(cli.green, language[70], os.difftime(os.time(), restStart ) );   -- full after x sec
			break;
		end;

		if( we_sit == false) then		-- can't cast while sitting
			self:checkPotions();
			self:checkSkills( ONLY_FRIENDLY ); 		-- only cast friendly spells to ourselfe
		end

		yrest(100);

	end;			-- end of while

	if( we_sit == true  and
		not self.Battling ) then	-- if aggro the char will standup automaticly
		RoMScript("SitOrStand()");
		yrest(1500);					-- give time to standup
	end;


end

function CPlayer:restrnd(_probability, _restmin, _restmax)
-- call the rest function with a given probability

	if( math.random( 100 ) < _probability ) then
		self:rest(_restmin, _restmax, "time", 0 )
	end;

end

function CPlayer:sleep()
-- the bot will sleep but still fight back attackers

	local sleep_start = os.time();		-- calculate the sleep time
	self.Sleeping = true;	-- we are sleeping

	cprintf(cli.yellow, language[89], os.date(), getKeyName(getStartKey())  );

	local hf_key = "";
	while(true) do

		local hf_key_pressed = false;

		if( keyPressedLocal(getStartKey()) ) then	-- start key pressed
			hf_key_pressed = true;
			hf_key = "AWAKE";
		end;

		if( hf_key_pressed == false ) then	-- key released, do the work

			-- START Key: wake up
			if( hf_key == "AWAKE" ) then
				hf_key = " ";	-- clear last pressed key

				cprintf(cli.yellow, language[90], getKeyName(getStartKey()),  os.date() );
				self.Sleeping = false;	-- we are awake
				break;
			end;

			hf_key = " ";	-- clear last pressed key
		end;

		self:update();
		-- wake up if aggro, but we don't clear the sleeping flag
		if( self.Battling ) then          -- we get aggro,
			self:clearTarget();       -- get rid of mob to be able to target attackers
			cprintf(cli.yellow, language[91], os.date() );  -- Awake from sleep because of aggro
			break;
		end;

		yrest(10);
		self:logoutCheck(); 		-- check logout timer
	end					-- end of while

	-- count the sleeping time
	self.Sleeping_time = self.Sleeping_time + os.difftime(os.time(), sleep_start);

end

function CPlayer:scan_for_NPC(_npcname)

	local msg = "Function player:scan_for_NPC() is not anymore available. Use function player:target_NPC(_npcname) instead. That function will also work in background mode.";
	error(msg, 0);

	if( foregroundWindow() ~= getWin() ) then
		return;
	end

	local function scan()
		local mousePawn;
		-- Screen dimension variables
		local wx, wy, ww, wh = windowRect(getWin());
		local halfWidth = ww/2;
		local halfHeight = wh/2;

		-- Scan rect variables
		local scanWidth = settings.profile.options.HARVEST_SCAN_WIDTH; -- Width, in 'steps', of the area to scan
		local scanHeight = settings.profile.options.HARVEST_SCAN_HEIGHT; -- Height, in 'steps', of area to scan
		local scanXMultiplier = settings.profile.options.HARVEST_SCAN_XMULTIPLIER;	-- multiplier for scan width
		local scanYMultiplier = settings.profile.options.HARVEST_SCAN_YMULTIPLIER;	-- multiplier for scan line height
		local scanStepSize = settings.profile.options.HARVEST_SCAN_STEPSIZE; -- Distance, in pixels, between 'steps'

		local mx, my; -- Mouse x/y temp values

		mouseSet(wx + (halfWidth*scanXMultiplier - (scanWidth/2*scanStepSize)),
		wy  + (halfHeight*scanYMultiplier - (scanHeight/2*scanStepSize)));
		yrest(200);

		local scanstart, scanende, scanstep;
		-- define scan direction top/down  or   bottom/up
		if( settings.profile.options.HARVEST_SCAN_TOPDOWN == true ) then
			scanstart = 0;
			scanende = scanHeight-1;
			scanstep = 1;
		else
			scanstart = scanHeight;
			scanende = 0;
			scanstep = -1;
		end;

		-- Scan nearby area for a node
		keyboardHold(key.VK_SHIFT);	-- press shift so you can scan trough players
		for y = scanstart, scanende, scanstep do
			my = math.ceil(halfHeight * scanYMultiplier - (scanHeight / 2 * scanStepSize) + ( y * scanStepSize ));

			for x = 0,scanWidth-1 do
				mx = math.ceil(halfWidth * scanXMultiplier - (scanWidth / 2 * scanStepSize) + ( x * scanStepSize ));

				mouseSet(wx + mx, wy + my);
				yrest(settings.profile.options.HARVEST_SCAN_YREST+3);
				mousePawn = CPawn(memoryReadRepeat("intptr", getProc(),
				addresses.staticbase_char, addresses.mousePtr_offset));

				-- id 110504 Waffenhersteller Dimar
				-- id 110502 Dan (Gemischtwarenh�ndler
				-- id 1000, 1001 Player
				if( mousePawn.Address ~= 0 and mousePawn.Type == PT_NPC
					and distance(self.X, self.Z, mousePawn.X, mousePawn.Z) < 150
  					and mousePawn.Id > 100000 ) then
					local target = CPawn(mousePawn.Address);
					if( _npcname and			-- check ncp name
					    not string.find(target.Name, _npcname ) ) then
					    local dummy = 1;			-- do nothing
					else
						cprintf(cli.green, "We found NPC: %s\n", target.Name);
						return mousePawn.Address, mx, my;
					end;
				end
			end
		end
		keyboardRelease(key.VK_SHIFT);


		return 0, nil, nil;
	end


	detach(); -- Remove attach bindings
	local mouseOrigX, mouseOrigY = mouseGetPos();
	local foundHarvestNode, nodeMouseX, nodeMouseY = scan();

	if( foundHarvestNode ~= 0 and nodeMouseX and nodeMouseY ) then

		-- If out of distance, move and rescan
		local mousePawn = CPawn(foundHarvestNode);
		local dist = distance(self.X, self.Z, mousePawn.X, mousePawn.Z)

		if( dist > 35 and dist < 150 ) then
			printf(language[80]);	-- Move in
			self:moveTo( CWaypoint(mousePawn.X, mousePawn.Z), true );
			yrest(200);
			foundHarvestNode, nodeMouseX, nodeMouseY = scan();
		end

		self:update();

		local wx,wy = windowRect(getWin());
		--mouseSet(wx + nodeMouseX, wy + nodeMouseY);
		mouseSet(wx + nodeMouseX, wy + nodeMouseY);
		yrest(3000);		-- wait for zoom in / out movement bug

		-- click NPC
		keyboardHold(key.VK_SHIFT);
		mouseLClick();		-- one click to target npc
		yrest(500);
		mouseLClick();		-- one click to open dialog
		yrest(500);
		mouseLClick();		-- one click to be really sure
		keyboardRelease(key.VK_SHIFT);

		self:update();

		yrest(2000);

	end

	mouseSet(mouseOrigX, mouseOrigY);
	attach(getWin()); -- Re-attach bindings
end

function CPlayer:mouseclick(_x, _y, _wwide, _whigh, _type)
	if( foregroundWindow() ~= getWin() ) then
		cprintf(cli.yellow, language[139]);	-- RoM window has to be in the foreground
		return;
	end

	detach(); -- Remove attach bindings

	local wx,wy,wwide,whigh  = windowRect(getWin());
	local hf_x, hf_y;

	-- recalulate clickpoints depending from the actual RoM windows size
	-- only if we know the original windows size from the clickpoints
	if(_wwide  and _whigh) then
		hf_x = wwide * _x / _wwide;
		hf_y = whigh * _y / _whigh;
		cprintf(cli.green, language[92], -- Mouseclick Left at %d,%d in %dx%d (recalculated
			_type, hf_x, hf_y, wwide, whigh, _x, _y, _wwide, _whigh);
	else
		hf_x = _x;
		hf_y = _y;
		cprintf(cli.green, language[93],	 -- Clicking mouseL at %d,%d in %dx%d\n
			_type, hf_x, hf_y, wwide, whigh);
	end;

	mouseSet(wx + hf_x, wy + hf_y);
	yrest(100);

	if( string.lower(_type) == "l"  or  string.lower(_type) == "left" ) then
		mouseLClick();
	elseif( string.lower(_type) == "r"  or  string.lower(_type) == "right" ) then
		mouseRClick();
	elseif( string.lower(_type) == "m"  or  string.lower(_type) == "middle" ) then
		mouseMClick();
	else
		cprintf(cli.yellow, "Unknow option %s for function CPlayer:mouseclick()\n", _type);
	end
	yrest(100);

	attach(getWin()); -- Re-attach bindings
end

function CPlayer:mouseclickL(_x, _y, _wwide, _whigh)
	self:mouseclick(_x, _y, _wwide, _whigh, "left")
end

function CPlayer:mouseclickR(_x, _y, _wwide, _whigh)
	self:mouseclick(_x, _y, _wwide, _whigh, "right")
end

function CPlayer:mouseclickM(_x, _y, _wwide, _whigh)
	self:mouseclick(_x, _y, _wwide, _whigh, "middle")
end

-- open an npc store
function CPlayer:openStore(_npcname, _option)
	_option = _option or 1
	if self:target_NPC(_npcname) then
		yrest(1000);
		RoMScript("ChoiceOption(".._option..")");
		yrest(1000);
		if RoMScript("StoreFrame:IsVisible()") then
			return true
		end
	end

	return false
end

-- auto interact with a merchant
function CPlayer:merchant(_npcname, _option)
	if self:openStore(_npcname, _option) then
		RoMScript("ClickRepairAllButton()");
		yrest(1000);

		inventory:update();
		if ( inventory:autoSell() ) then
			inventory:update();
		end
		store:buyConsumable("hot", settings.profile.options.HEALING_POTION);
		store:buyConsumable("mot", settings.profile.options.MANA_POTION);
		store:buyConsumable("arrow_quiver", settings.profile.options.ARROW_QUIVER);
		store:buyConsumable("thrown_bag", settings.profile.options.THROWN_BAG);
		store:buyConsumable("poison", settings.profile.options.POISON);
		if settings.profile.options.EGGPET_ENABLE_CRAFT then
			if settings.profile.options.EGGPET_CRAFT_RATIO then
				local mRatio, wRatio, hRatio = string.match(settings.profile.options.EGGPET_CRAFT_RATIO,"(%d*)%s*:%s*(%d*)%s*:%s*(%d*)")
				if tonumber(mRatio) > 0 then
					store:buyConsumable("eggpet_hoe", settings.profile.options.EGGPET_HOE);
				end
				if tonumber(wRatio) > 0 then
					store:buyConsumable("eggpet_hatchet", settings.profile.options.EGGPET_HATCHET);
				end
				if tonumber(hRatio) > 0 then
					store:buyConsumable("eggpet_spade", settings.profile.options.EGGPET_SPADE);
				end
			else
				store:buyConsumable("eggpet_hoe", settings.profile.options.EGGPET_HOE);
				store:buyConsumable("eggpet_hatchet", settings.profile.options.EGGPET_HATCHET);
				store:buyConsumable("eggpet_spade", settings.profile.options.EGGPET_SPADE);
			end
		end
		inventory:update();
	end

	RoMScript("CloseWindows()");

end

-- trys to target a friendly NPC/player with the ingame targetnearestfriend key
-- if after some tries we don't find the target, the character will turn around
-- in steps and tries again to find the target
function CPlayer:target_NPC(_npcname)
	if( not _npcname ) then
		cprintf(cli.yellow, language[133]);	-- Please give a NPC name
		return
	end

	cprintf(cli.green, language[135], _npcname);	-- We try to find NPC

	if type(_npcname) == "string" and
		bot.ClientLanguage == "RU" then
		_npcname = utf82oem_russian(_npcname);		-- language conversations for Russian Client
	end

	local npc = self:findNearestNameOrId(_npcname)
	if npc then	-- we successfully found NPC
		cprintf(cli.green, language[136], npc.Name);	-- we successfully target NPC
		if( distance(self.X, self.Z, npc.X, npc.Z) > 39 ) then
			self:moveInRange(CWaypoint(npc.X, npc.Z), 39, true);
		end
		-- target NPC
		self:target(npc.Address)
		Attack(); yrest(50); Attack(); -- 'click' again to be sure
		yrest(500);
		return true
	else
		cprintf(cli.green, language[137], _npcname);	-- we can't find NPC
		return false
	end
end


--[[function CPlayer:target_NPC(_npcname)

	if( not _npcname ) then
		cprintf(cli.yellow, language[133]);	-- Please give a NPC name
		return
	end

	cprintf(cli.green, language[135], _npcname);	-- We try to find NPC

	local found_npc = false;
	local counter = 0;
	local scanDirection = self.Direction;

	while(true) do
		counter = counter + 1;

		-- turn character if first try wasn't successfull
		if( counter == 2 ) then
			scanDirection=scanDirection - math.pi/4
		elseif( counter == 3 ) then
			scanDirection=scanDirection + math.pi/2
		elseif( counter > 3 and  counter < 9) then
			scanDirection=scanDirection + math.pi/4
		elseif( counter > 8 ) then
			break;
		end
		camera:setRotation(scanDirection)

		local target = self:getTarget();
		local _precheck = (string.find(string.lower(target.Name), string.lower(_npcname), 1, true));

		for i = 1, 6 do
			if( not _precheck ) then
				keyboardPress(settings.hotkeys.TARGET_FRIEND.key, settings.hotkeys.TARGET_FRIEND.modifier);
			end

			yrest(100);
			player:update();

			if(player.TargetPtr ~= 0) then
				found_npc = true;				-- we found something
				local target = self:getTarget();		-- read target informations
				cprintf(cli.green, "%s, ", target.Name);	-- print name

				if( string.find(string.lower(target.Name), string.lower(_npcname), 1, true ) ) then

					cprintf(cli.green, language[136], _npcname);	-- we successfully target NPC
					if( settings.profile.hotkeys.MACRO ) then
						RoMScript("UseSkill(1,1);");				-- general attack key = open dialog window
					else
						keyboardPress(settings.profile.hotkeys.ATTACK.key, settings.profile.hotkeys.ATTACK.modifier);
					end

					-- repair all with macro script
					-- we do that at all NPC's
					-- we cant use ChoiceOption(1) by default because of transport NPC and so on
					if( settings.profile.hotkeys.MACRO ) then
						RoMScript("ClickRepairAllButton();");
					end

					return true;
				end
			end;

			yrest(100);
		end

	end

	cprintf(cli.green, language[137], _npcname);	-- we can't find NPC
	if( not found_npc) then
		cprintf(cli.yellow, language[138], 	-- We didn't found any NPC
		  getKeyName(settings.hotkeys.TARGET_FRIEND.key) );
	end

	return false;

end]]

function CPlayer:findNearestNameOrId(_objtable, ignore, evalFunc)
	if type(_objtable) == "number" or type(_objtable) == "string" then
		_objtable = {_objtable}
	end

	ignore = ignore or 0;
	local closestObject = nil;
	local obj = nil;
	local objectList = CObjectList();
	objectList:update();

	if( type(evalFunc) ~= "function" ) then
		evalFunc = function (unused) return true; end;
	end

	for i = 0,objectList:size() do
		obj = objectList:getObject(i);

		if( obj ~= nil ) then
			for __, _objnameorid in pairs(_objtable) do
				if( obj.Address ~= ignore and (obj.Id == tonumber(_objnameorid) or string.find(obj.Name, _objnameorid, 1, true) )) then
					if( evalFunc(obj.Address,obj) == true ) then
						local dist = distance(self.X, self.Z, self.Y, obj.X, obj.Z, obj.Y);
						if( closestObject == nil ) then
							closestObject = obj;
						else
							if( distance(self.X, self.Z, self.Y, obj.X, obj.Z, obj.Y) <
								distance(self.X, self.Z, self.Y, closestObject.X, closestObject.Z, closestObject.Y) ) then
								-- this node is closer
								closestObject = obj;
							end
						end
					end
				end
			end
		end
	end

   return closestObject;
end

function CPlayer:target_Object(_objname, _waittime, _harvestall, _donotignore, evalFunc)
	_waittime = _waittime or 0
	local minWaitTime = 1000 -- minimum time to wait for castbar to come up.
	_harvestall = (_harvestall == true)
	if type(_donotignore) ~= "boolean" then _donotignore = (_harvestall == false) end -- default value depends on _harvestall
	if( not _objname ) then
		cprintf(cli.yellow, language[181]);	-- Please give an Object name
		return
	end

	yrest(200); -- Make sure we come to a stop before attempting to harvest.
	local objFound = false;

	while(true) do
		repeat
			interrupted = false
			if _donotignore == false then
				obj = self:findNearestNameOrId(_objname, self.LastTargetPtr, evalFunc)
			else
				obj = self:findNearestNameOrId(_objname, nil, evalFunc)
			end

			-- Check if too far
			if obj and ( distance(self.X, self.Z, self.Y, obj.X, obj.Z, obj.Y ) > settings.profile.options.HARVEST_DISTANCE ) then
				obj = nil
			end

			if obj then -- object found, target
				if self.LastTargetPtr ~= obj.Address then
					cprintf(cli.yellow, language[95], obj.Name); -- We found object and will harvest it
					self.LastTargetPtr = obj.Address;		-- remember target address to avoid msg spam
				end
				objFound = true
				self:target(obj.Address);
				if( distance(self.X, self.Z, obj.X, obj.Z) > 39 ) then
					self:moveInRange(CWaypoint(obj.X, obj.Z), 39, true);
				end
				yrest(100)
				Attack()
				local timeStart = getTime()

				--Wait minimum time
				repeat
					yrest(100)
					self:update()
					if self.Casting or self.Battling then break end
				until deltaTime(getTime(),timeStart) >= minWaitTime

				if self.Casting == false and _waittime > 0 then -- Was expecting castingbar so try again, 2nd try.
					Attack(); yrest(50);
					timeStart = getTime()
				end

				repeat
					yrest(100);
					self:update();
					while( self.Battling ) do
						self:target(self:findEnemy(true, nil, evalTargetDefault, self.IgnoreTarget));
						self:update();
						if( self:haveTarget() ) then
							self:fight();
							interrupted = true
						end
					end
				until deltaTime(getTime(),timeStart) > _waittime and self.Casting == false
			end
		until interrupted == false

		if obj then -- harvest again
			if _donotignore ~= true then
				self.LastTargetPtr = obj.Address -- Default ignore this address in next search
			end
			if _harvestall == false then -- No more harvesting
				return objFound
			end
		else
			return objFound
		end
	end
end

function CPlayer:mount(_dismount)
	if( (not _dismount) and self.Mounted ) then
		printf("Already mounted.\n");
		return;
	end

	if( _dismount and (not self.Mounted) ) then
		printf("Already dismounted.\n");
		return;
	end

	if self.Swimming then
		printf("Swimming. Can't mount.\n")
		return
	end

	local mountMethod = false
	local mount

	-- Find mount
	if RoMScript("PartnerFrame_GetPartnerCount(2)") > 0 then
		-- There is a mount in the partner bag. Assign the mountmethod.
		mountMethod = "partner"
	elseif inventory then -- Make sure inventory has been mapped.
		mount = inventory:getMount();
		if mount then
			mountMethod = "inventory"
		end
	end

	-- Mount found?
	if(not mountMethod ) then
		return
	end

	-- Make sure we are not battling before trying to mount
	if not _dismount and not (self.Current_waypoint_type == WPT_TRAVEL) then
		while( self.Battling ) do
			self:target(self:findEnemy(true, nil, nil, nil));
			self:update();
			if( self:haveTarget() ) then
				self:fight();
			else
				break
			end
		end
	end

	-- if _dismount and mountmethod is inventory then assume buff name equals item name and cancel buff if exists. Mainly needed for 15m and 2h mounts
	if _dismount and mountMethod == "inventory" then
		for index, buff in pairs(self.Buffs) do
			if string.find(mount.Name,buff.Name,1, true) then
				sendMacro("CancelPlayerBuff("..index..");")
				return
			end
		end
	end

	-- mount/dismount
	if mountMethod == "partner" then
		RoMScript("PartnerFrame_CallPartner(2,1)")
	else
		mount:use()
	end

	yrest(500)
	repeat
		yrest(100);
		self:update();
	until self.Casting == false

	-- Just in case you mounted a different mount instead of dismounting
	if _dismount == true and self.Mounted then
		-- second try dismount
		yrest(1000)
		if mountMethod == "partner" then
			RoMScript("PartnerFrame_CallPartner(2,1)")
		else
			mount:use()
		end
	end
	yrest(500)
end

function CPlayer:dismount()
	self:mount(true)
end

-- Waits till casting ends minus SKILL_USE_PRIOR.
function CPlayer:waitTillCastingEnds()
	self:update()
	while(self.Casting) do
		-- break cast with jump if aggro before casting finished
		if( self:check_aggro_before_cast(JUMP_TRUE, self.LastSkillType)) then	--  with jump
			printf(language[82]);	-- close print 'Casting ..."
			return;
		end;
		-- Waiting for casting to finish...
		yrest(50);
		self:update();

		-- leave before Casting flag is gone, so we can cast faster
		local prior = getSkillUsePrior();

		if( deltaTime(getTime(), self.LastSkillStartTime) > self.LastSkillCastTime - prior ) then
			--				end of waiting
			break;
		end
	end
end

function CPlayer:aimAt(target)
	if target.Address then target:update() end -- only update if a pawn
	camera:update()

	-- camera distance to camera focus
	local cameraDistance = distance(camera.XFocus,camera.ZFocus,camera.YFocus,camera.X,camera.Z,camera.Y)
	if cameraDistance > 150 then cameraDistance = 150 end

	-- Target distance to camera focus
	local targetDistance = distance(camera.XFocus,camera.ZFocus,camera.YFocus,target.X,target.Z,target.Y)

	-- Ratio
	local ratio = cameraDistance/targetDistance

	-- Vectors
	local vec1 = (camera.XFocus - target.X) * ratio
	local vec2 = (camera.ZFocus - target.Z) * ratio
	local vec3 = (camera.YFocus - (target.Y or camera.YFocus)) * ratio

	-- New Camera coordinates
	local nx = camera.XFocus + vec1
	local nz = camera.ZFocus + vec2
	local ny = camera.YFocus + vec3

	-- write camera coordinates
	memoryWriteFloat(getProc(), camera.Address + addresses.camX_offset, nx);
	memoryWriteFloat(getProc(), camera.Address + addresses.camZ_offset, nz);
	memoryWriteFloat(getProc(), camera.Address + addresses.camY_offset, ny);
end

function CPlayer:getCraftLevel(craft)
	if string.lower(craft) == "blacksmithing" then craft = CRAFT_BLACKSMITHING
	elseif string.lower(craft) == "carpentry" then craft = CRAFT_CARPENTRY
	elseif string.lower(craft) == "armorcrafting" then craft = CRAFT_ARMORCRAFTING
	elseif string.lower(craft) == "tailoring" then craft = CRAFT_TAILORING
	elseif string.lower(craft) == "cooking" then craft = CRAFT_COOKING
	elseif string.lower(craft) == "alchemy" then craft = CRAFT_ALCHEMY
	elseif string.lower(craft) == "mining" then craft = CRAFT_MINING
	elseif string.lower(craft) == "woodcutting" then craft = CRAFT_WOODCUTTING
	elseif string.lower(craft) == "herbalism" then craft = CRAFT_HERBALISM
	end

	if type(craft) ~= "number" or craft < 0 or craft > 8 then
		cprintf(cli.yellow, language[77])
		return
	end

	local lvl = memoryReadFloat(getProc(),addresses.playerCraftLevelBase + addresses.playerCraftLevel_offset + craft*4)

	return lvl
end
