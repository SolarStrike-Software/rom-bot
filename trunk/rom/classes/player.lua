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

CPlayer = class(CPawn);

function CPlayer:harvest( _second_try )
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

				mouseSet(wx + mx, wy + my);
				yrest(settings.profile.options.HARVEST_SCAN_YREST);
				mousePawn = CPawn(memoryReadIntPtr(getProc(), staticcharbase_address, mousePtr_offset));

				if( mousePawn.Address ~= 0 and mousePawn.Type == PT_NODE
					and distance(self.X, self.Z, mousePawn.X, mousePawn.Z) < 150
					and database.nodes[mousePawn.Id] ) then
					return mousePawn.Address, mx, my, mousePawn.Id;
				end
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
		-- We found something. Lets harvest it.
		hf_found = true;
		cprintf(cli.green, language[95], database.nodes[hf_node_id].Name);		-- we found ...
		
		-- If out of distance, move and rescan
		local mousePawn = CPawn(foundHarvestNode);
		local dist = distance(self.X, self.Z, mousePawn.X, mousePawn.Z)

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

			if( os.difftime(os.time(), startHarvestTime) > 45 ) then
				break;
			end

			local wx,wy = windowRect(getWin());
			--mouseSet(wx + nodeMouseX, wy + nodeMouseY);
			mouseSet(wx + nodeMouseX, wy + nodeMouseY);
			yrest(50);
			mousePawn = CPawn(memoryReadIntPtr(getProc(), staticcharbase_address, mousePtr_offset));
			yrest(50);

			if( mousePawn.Address ~= 0 and mousePawn.Type == PT_NODE
			and database.nodes[mousePawn.Id] ~= nil ) then
				-- Node is still here

				-- Begin gathering
				keyboardHold(key.VK_SHIFT);
				mouseLClick();
				yrest(100);
				mouseLClick();
				keyboardRelease(key.VK_SHIFT);

				-- Wait for a few seconds... constantly check for aggro
				local startWaitTime = os.time();
				while( os.difftime(os.time(), startWaitTime) < 2 ) do
					yrest(100);
					self:update();

					-- Make sure it didn't disapear
					mousePawn = CPawn(memoryReadIntPtr(getProc(), staticcharbase_address, mousePtr_offset));
					if( mousePawn.Address == 0 ) then
						break;
					end;

					if( self.Battling ) then
						break;
					end
				end

				self:update();

			else
				-- Node is gone
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
		player:harvest( true );
	end

end


function CPlayer:initialize()
	memoryWriteInt(getProc(), self.Address + castbar_offset, 0);
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

function CPlayer:cast(skill)
	-- If given a string, look it up.
	-- If given a skill object, use it natively.
	if( type(skill) == "string" ) then
		for i,v in pairs(settings.profile.skills) do
			if( v.Name == skill ) then
				skill = v; break;
			end
		end
	end

	local hf_temp;
	if( skill.hotkey == "MACRO" ) then
		hf_temp = "MACRO";
	else
		hf_temp = getKeyName(skill.hotkey);
	end
	
	printf(language[21], hf_temp, string.sub(skill.Name.."                      ", 1, 20));	-- first part of 'casting ...'
	skill:use();
	yrest(100);
	self:update();

	-- Wait for casting to start (if it has a decent cast time)
	if( skill.CastTime > 0 ) then
		local startTime = os.time();
		while( not self.Casting ) do
			-- break cast with jump if aggro before casting finished
			if( self:check_aggro_before_cast(JUMP_TRUE, skill.Type) and
			   ( skill.Type == STYPE_DAMAGE or
				 skill.Type == STYPE_DOT ) ) then	-- with jump
				printf(language[82]);	-- close print 'Casting ..." / aborted
				return;
			end;
			yrest(50);
			self:update();
			if( os.difftime(os.time(), startTime) > skill.CastTime ) then
				self.Casting = true; -- force it.
				break;
			end
		end;

		while(self.Casting) do
			-- break cast with jump if aggro before casting finished
			if( self:check_aggro_before_cast(JUMP_TRUE, skill.Type) and
			   ( skill.Type == STYPE_DAMAGE or
				 skill.Type == STYPE_DOT ) ) then	--  with jump
				printf(language[82]);	-- close print 'Casting ..."
				return;
			end;
			-- Waiting for casting to finish...
			yrest(10);
			self:update();
		end
--				printf(language[20]);		-- finished casting
	else
		yrest(500); -- assume 0.5 second yrest
	end

	-- count cast to enemy targets
	if( skill.Target == 0 ) then	-- target is unfriendly
		self.Cast_to_target = self.Cast_to_target + 1;
	end;

	if( skill.CastTime == 0 ) then
		yrest(500);
	else
		yrest(100);
	end;

	-- print HP of our target
	-- we do it later, because the client needs some time to change the values
	local target = player:getTarget();
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
end

-- Check if you can use any skills, and use them
-- if they are needed.
function CPlayer:checkSkills(_only_friendly)
	local used = false;

	for i,v in pairs(settings.profile.skills) do
		if( v.AutoUse and v:canUse(_only_friendly) ) then
			if( v.CastTime > 0 ) then
				keyboardRelease( settings.hotkeys.MOVE_FORWARD.key );
				yrest(200); -- Wait to stop only if not an instant cast spell
			end

			-- Make sure we aren't already busy casting something else
			while(self.Casting) do
				-- Waiting for casting to finish...
				yrest(100);
				self:update();
			end

			-- break cast if aggro before casting
			if( self:check_aggro_before_cast(JUMP_FALSE, v.Type) and
			   ( v.Type == STYPE_DAMAGE or
			     v.Type == STYPE_DOT )  ) then	-- without jump
				return false;
			end;

			self:cast(v);
			--self.LastDistImprove = os.time();	-- reset unstick timer (dist improvement timer)
			used = true;
		end
	end

	return used;
end

-- Check if you need to use any potions, and use them.
function CPlayer:checkPotions()
	local used = false;

	-- Still cooling down, don't use.
	-- if( os.difftime(os.time(), self.PotionLastUseTime) < settings.profile.options.POTION_COOLDOWN+1 ) then
	if( os.difftime(os.time(), self.PotionLastUseTime) < 15+1 ) then
		return false;
	end 

	-- If we need to use a mana potion(if we even have mana)
	if( self.MaxMana > 0 ) then 
		if( (self.Mana/self.MaxMana*100) < settings.profile.options.MP_LOW_POTION ) then  
			item = inventory:bestAvailableConsumable("mana");
			if( item ) then
				hf_itemcount = item:use();
					
				cprintf(cli.green, language[11], 		-- Using MP potion
				   	settings.profile.hotkeys.MACRO.key, self.Mana, self.MaxMana, self.Mana/self.MaxMana*100, 
				   	item.Name, item.ItemCount); 
				if( self.Fighting ) then
					yrest(1000);
				end
				
				self.PotionLastUseTime = os.time();
				used = true;
			end;
		end
	end

	-- If we need to use a health potion
	if( (self.HP/self.MaxHP*100) < settings.profile.options.HP_LOW_POTION ) then
		item = inventory:bestAvailableConsumable("healing");
		if( item ) then
			hf_itemcount = item:use();
			
			cprintf(cli.green, language[10], 		-- Using HP potion
			   settings.profile.hotkeys.MACRO.key, self.HP, self.MaxHP, self.HP/self.MaxHP*100, 
			   item.Name, item.ItemCount);
			if( self.Fighting ) then
				yrest(1000);
			end 
			  
			self.PotionLastUseTime = os.time();
			used = true;
		end 
	end

	return used;
end

function CPlayer:fight()
	self:update();
	if( not self:haveTarget() ) then
		return false;
	end

	local target = self:getTarget();
	self.Fighting = true;

	cprintf(cli.green, language[22], target.Name);	-- engagin x in combat

	-- Keep tapping the attack button once every few seconds
	-- just in case the first one didn't go through
	local function timedAttack()
		self:update();
		if( self.Casting ) then
			-- Don't interupt casting
			return;
		end;

		-- Prevents looting when looting is turned off
		-- (target is dead, or about to be dead)
		if( self.Target ~= 0 ) then
			local target = self:getTarget();
			if( (target.HP/target.MaxHP) <= 0.1 ) then
				return;
			end
		end;

		if( settings.profile.hotkeys.MACRO ) then
			RoMScript("UseSkill(1,1);");
		else
			keyboardPress(settings.profile.hotkeys.ATTACK.key);
		end
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
	while( self:haveTarget() ) do
		-- If we die, break
		if( self.HP < 1 or self.Alive == false ) then
			if( settings.profile.options.COMBAT_TYPE == "melee" ) then
				unregisterTimer("timedAttack");
			end
			self.Fighting = false;
			return;
		end;

		target = self:getTarget();

		-- Exceeded max fight time (without hurting enemy) so break fighting
		if( os.difftime(os.time(), self.lastHitTime) > settings.profile.options.MAX_FIGHT_TIME ) then
			printf(language[83]);			-- Taking too long to damage target
			player.Last_ignore_target_ptr = player.TargetPtr;	-- remember break target
			player.Last_ignore_target_time = os.time();		-- and the time we break the fight
			self:clearTarget();
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
		end

		-- We're a bit TOO close...
		if( dist < 5.0 ) then
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
		    target.TargetPtr ~= self.Address ) then	-- but not from that mob
			cprintf(cli.green, language[36], target.Name);	
			self:clearTarget();
			break_fight = true;
			break;
		end;

		if( dist > suggestedRange ) then
			
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
			local angle = math.atan2(target.Z - self.Z, target.X - self.X);
			local posX, posZ;
			local success, reason;

			if( settings.profile.options.COMBAT_TYPE == "ranged" or
			  self.ranged_pull == true ) then		-- melees with timed ranged pull
				-- Move closer in increments
				local movedist = dist/10; if( dist < 50 ) then movedist = dist - 5; end;
				if( dist > 50 and movedist < 50 ) then movedist = 50 end;

				posX = self.X + math.cos(angle) * (movedist);
				posZ = self.Z + math.sin(angle) * (movedist);
				success, reason = player:moveTo(CWaypoint(posX, posZ), true);
			else 	-- normal melee
--			elseif( settings.profile.options.COMBAT_TYPE == "melee" ) then
				success, reason = player:moveTo(target, true);
				-- Start melee attacking
				if( settings.profile.options.COMBAT_TYPE == "melee" ) then
					timedAttack();
				end
			end

			if( not success ) then
				player:unstick();
			end

			yrest(500);
		end

		if( settings.profile.options.QUICK_TURN ) then
			local angle = math.atan2(target.Z - self.Z, target.X - self.X);
			self:faceDirection(angle);
			camera:setRotation(angle);
			yrest(50);
		elseif( settings.options.ENABLE_FIGHT_SLOW_TURN ) then
			-- Make sure we're facing the enemy
			local angle = math.atan2(target.Z - self.Z, target.X - self.X);
			local angleDif = angleDifference(angle, self.Direction);
			local correctingAngle = false;
			local startTime = os.time();

			while( angleDif > math.rad(15) ) do
				if( self.HP < 1 or self.Alive == false ) then
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

		self:checkPotions();
		self:checkSkills();

		yrest(100);
		target:update();
		self:update();


		-- do we need that? Because the DO statement is allready a 
		-- while( self:haveTarget() statement / I will comment it out and see 
		-- what happens (d003232, 18.9.09)
--		if( not self:haveTarget() ) then
--			break;
--		end
	end

	self:resetSkills();

	if( settings.profile.options.COMBAT_TYPE == "melee" ) then
		unregisterTimer("timedAttack");
	end


	-- check if we need to reload ammunition
	--if not settings.profile.options.RELOAD_AMMUNITION == nil then
	--	if( string.lower(settings.profile.options.RELOAD_AMMUNITION) == "arrow" or string.lower(settings.profile.options.RELOAD_AMMUNITION) == "thrown" ) then
	--		if inventory:getAmmunitionCount() == 0 then
	--			inventory:reloadAmmunition(settings.profile.options.RELOAD_AMMUNITION);
	--		end
	--	end
	--end
	
	-- edit: too tired to fix this now..
	

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
	if( settings.profile.options.LOOT_IN_COMBAT ~= true ) then
		yrest(800);
	end;

	-- Monster is dead (0 HP) but still targeted.
	-- Loot and clear target.
	self:update();
	if( settings.profile.options.LOOT_IN_COMBAT == true ) then
		self:loot();
	elseif( not self.Battling ) then
		-- Skip looting when under attack
		self:loot();
	else
		cprintf(cli.green, language[178]); 	-- Loot skiped because of aggro
	end

	if( self.TargetPtr ~= 0 ) then
		self:clearTarget();
	end
	self.Fighting = false;
end

function CPlayer:loot()

	if( settings.profile.options.LOOT ~= true ) then
		if( settings.profile.options.DEBUG_LOOT) then	
			cprintf(cli.green, "[DEBUG] don't loot reason: settings.profile.options.LOOT ~= true\n");
		end;
		return
	end
	if( self.TargetPtr == 0 ) then
		if( settings.profile.options.DEBUG_LOOT) then	
			cprintf(cli.green, "[DEBUG] don't loot reason: self.TargetPtr == 0\n");
		end;
		return
	end

	local target = self:getTarget();

	if( target == nil or target.Address == 0 ) then
		if( settings.profile.options.DEBUG_LOOT) then	
			cprintf(cli.green, "[DEBUG] don't loot reason: target == nil or target.Address == 0\n");
		end;
		return;
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
		return false
	end

	yrest(500);	-- ?? 

	-- "attack" is also the hotkey to loot, strangely.
	local hf_attack_key;
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
	end
	
	yrest(settings.profile.options.LOOT_TIME + dist*15); -- dist*15 = rough calculation of how long it takes to walk there

	-- check for loot problems to give a noob mesassage
	self:update();
	if( self.X == hf_x  and	-- we didn't move, seems attack key is not defined
	    self.Z == hf_z  and
	    dist > 25 )  then
		cprintf(cli.green, language[100]); -- We didn't move to the loot!? 
	end;

	-- rnd pause from 3-6 sec after loot to look more human
	if( settings.profile.options.LOOT_PAUSE_AFTER > 0 ) then
		self:restrnd( settings.profile.options.LOOT_PAUSE_AFTER,3,6);
	end;

	-- Close the booty bag.
	RoMScript("CloseBooty()");

	-- Maybe take a step forward to pick up a buff.
	if( math.random(100) > 80 ) then
		keyboardHold(settings.hotkeys.MOVE_FORWARD.key);
		yrest(500);
		keyboardRelease(settings.hotkeys.MOVE_FORWARD.key);
	end

end

function CPlayer:moveTo(waypoint, ignoreCycleTargets)
	self:update();
	local angle = math.atan2(waypoint.Z - self.Z, waypoint.X - self.X);
	local angleDif = angleDifference(angle, self.Direction);
	local canTarget = false;
	local startTime = os.time();

	if( ignoreCycleTargets == nil ) then
		ignoreCycleTargets = false;
	end;

	if( waypoint.Type == WPT_TRAVEL or
	    waypoint.Type == WPT_RUN ) then
		if( settings.profile.options.DEBUG_TARGET ) then
			cprintf(cli.green, "[DEBUG] waypoint type RUN or TRAVEL. We don't target mobs.\n");
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

	-- no active turning if wander and radius = 0
	-- self direction has values from 0 til Pi and -Pi til 0
	-- angel has values from 0 til 2*Pi
	if(__WPL:getMode()   == "wander"  and
	   __WPL:getRadius() == 0     )   then
	   	self:restrnd(100, 1, 4);	-- wait 3 sec
		if( self.Direction < 0 ) then
			angle = (math.pi * 2) - math.abs(self.Direction);
		else
			angle = self.Direction;
		end;
	end;

	-- QUICK_TURN only
	if( settings.profile.options.QUICK_TURN == true ) then
		self:faceDirection(angle);
		camera:setRotation(angle);
		self:update();
		angleDif = angleDifference(angle, self.Direction);
		yrest(50);
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
			yrest(50);
			keyboardHold( settings.hotkeys.ROTATE_LEFT.key );
			yrest(50);

			--self:faceDirection( angle );
		else
			-- rotate right
			keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
			yrest(50);
			keyboardHold( settings.hotkeys.ROTATE_RIGHT.key );
			yrest(50);

			--self:faceDirection( angle );
		end

		yrest(50);
		self:update();
		angleDif = angleDifference(angle, self.Direction);
	end

	keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
	keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );
	yrest(50);

	-- direction ok, now look for a target before start movig
	if( (not ignoreCycleTargets) and (not self.Battling) ) then	
		if( self:findTarget() ) then			-- find a new target
--			cprintf(cli.turquoise, language[28]);	-- stopping waypoint::target acquired
			cprintf(cli.turquoise, language[86]);	-- stopping waypoint::target acquired before moving
			success = false;
			failreason = WF_TARGET;
			return success, failreason;
		end;
	end;

	yrest(50);

	local success, failreason = true, WF_NONE;
	local dist = distance(self.X, self.Z, waypoint.X, waypoint.Z);
	local lastDist = dist;
	self.LastDistImprove = os.time();	-- global, because we reset it while skill use
	local movingForward = false;
	while( dist > 20.0 ) do
		if( self.HP < 1 or self.Alive == false ) then
			return false, WF_NONE;
		end;

		if( canTarget == false and os.difftime(os.time(), startTime) > 1 ) then
			canTarget = true;
		end

		-- stop moving if aggro, bot will stand and wait until to get the target from the client
	 	-- only if not in the fight stuff coding (means self.Fighting == false )
	 	if( self.Battling and 				-- we have aggro
	 	    self.Fighting == false  and		-- we are not coming from the fight routines (bec. as melee we should move in fight)
	 	    waypoint.Type ~= WPT_RUN  and	-- only stop if not waypoint type RUN
	 	    os.difftime(os.time(), player.LastAggroTimout ) > 10 ) then		-- dont stop 10sec after last aggro wait timeout
			keyboardRelease( settings.hotkeys.MOVE_FORWARD.key );
			keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
			keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );
			movingForward = false;
			success = false;
			failreason = WF_COMBAT;
			break;
		end;


		-- look for a new target while moving
		if( canTarget and (not ignoreCycleTargets) and (not self.Battling) ) then
			if( self:findTarget() ) then	-- find a new target
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

		local usedPotion, usedSkill = false, false;
		usedPotion = self:checkPotions();
		usedSkill = self:checkSkills( ONLY_FRIENDLY ); -- only cast friendly spells to ourself

		if( usedPotion or usedSkill ) then
			-- If we used a skill or potion, reset our
			-- distance improvement time to prevent
			-- unsticking when not necessary
			self.LastDistImprove = os.time();
		end

		dist = distance(self.X, self.Z, waypoint.X, waypoint.Z);
		angle = math.atan2(waypoint.Z - self.Z, waypoint.X - self.X);
		angleDif = angleDifference(angle, self.Direction);

		-- Continue to make sure we're facing the right direction
		if( settings.profile.options.QUICK_TURN and angleDif > math.rad(1) ) then
			self:faceDirection(angle);
			camera:setRotation(angle);
			yrest(50);
		end

		if( angleDif > math.rad(15) ) then
			--keyboardRelease( settings.hotkeys.MOVE_FORWARD.key );
			--keyboardRelease( settings.hotkeys.MOVE_BACKWARD.key );

			if( angleDifference(angle, self.Direction + 0.01) < angleDif ) then
					keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );
					yrest(50);
					keyboardHold( settings.hotkeys.ROTATE_LEFT.key );
					yrest(100);
			else
					keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
					yrest(50);
					keyboardHold( settings.hotkeys.ROTATE_RIGHT.key );
					yrest(100);
			end
		elseif( angleDif > math.rad(1) ) then
			if( settings.profile.options.QUICK_TURN ) then
				camera:setRotation(angle);
				yrest(50);
			end

			self:faceDirection(angle);
			keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
			keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );

			yrest(50);
			keyboardHold( settings.hotkeys.MOVE_FORWARD.key );
			movingForward = true;
			yrest(50);
		else
			if( not movingForward ) then
				keyboardHold( settings.hotkeys.MOVE_FORWARD.key );
				movingForward = true;
				yrest(50);
			end
		end

		--keyboardHold( settings.hotkeys.MOVE_FORWARD.key );
		yrest(100);
		self:update();
		waypoint:update();

	end
	keyboardRelease( settings.hotkeys.MOVE_FORWARD.key );
	movingForward = false;
	keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
	keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );

	if( success ) then
		-- We successfully reached the waypoint.
		-- Execute it's action, if it has one.

		if( waypoint.Action and type(waypoint.Action) == "string" ) then
			local actionchunk = loadstring(waypoint.Action);
			assert( actionchunk,  sprintf(language[150], __WPL.CurrentWaypoint) );
			actionchunk();
		end
	end

	return success, failreason;
end


-- Forces the player to face a direction.
-- 'dir' should be in radians
function CPlayer:faceDirection(dir)
	local Vec1 = math.cos(dir);
	local Vec2 = math.sin(dir);

	memoryWriteFloat(getProc(), self.Address + chardirXUVec_offset, Vec1);
	memoryWriteFloat(getProc(), self.Address + chardirYUVec_offset, Vec2);
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
		if( self.Returning ) then
			__RPL:backward();
		else
			__WPL:backward();
		end;
		return;	
	end;

-- after 5x unsuccesfull unsticks try to reach next waypoint after sticky one
	if( self.Unstick_counter == 6 ) then
		if( self.Returning ) then
			__RPL:advance();	-- forward to sticky wp
			__RPL:advance();	-- and one more
		else
			__WPL:advance();	-- forward to sticky wp
			__WPL:advance();	-- and one more
		end;
		return;	
	end;

-- after 8x unstick try to run away a little and then go to the nearest waypoint
	if( self.Unstick_counter == 9 ) then
	 	-- turn and move back for 10 seconds
		keyboardHold(settings.hotkeys.ROTATE_RIGHT.key);
		yrest(1900);
		keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );
		keyboardHold(settings.hotkeys.MOVE_FORWARD.key);
		yrest(10000);
		keyboardRelease(settings.hotkeys.MOVE_FORWARD.key);
		self:update();
		if( player.Returning ) then
			__RPL:setWaypointIndex(__RPL:getNearestWaypoint(self.X, self.Z));
		else
			__WPL:setWaypointIndex(__WPL:getNearestWaypoint(self.X, self.Z));
		end;
		return;
	end;

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
	
		local function debug_target(_place)
			if( settings.profile.options.DEBUG_TARGET and
				self.TargetPtr ~= self.free_debug1 ) then
				cprintf(cli.green, "[DEBUG] "..self.TargetPtr.." ".._place.."\n");
				self.free_debug1 = self.TargetPtr;		-- remeber target address to avoid msg spam
			end
		end
		
	
		local target = self:getTarget();

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
			target.TargetPtr ~= self.Address ) then	-- but not from that mob
				debug_target("target lvl above/below profile settings with battling from other mob")
				return false;         
			end;
		end;

		-- check if we just ignored that target / ignore it for 10 sec
		if(self.TargetPtr == player.Last_ignore_target_ptr  and
		   os.difftime(os.time(), player.Last_ignore_target_time)  < 10 )then	
			if ( self.Battling == false ) then	-- if we don't have aggro then
				cprintf(cli.green, language[87], target.Name, 	-- We ignore %s for %s seconds.
				   10-os.difftime(os.time(), player.Last_ignore_target_time ) );
				debug_target("ignore that target for 10 sec (e.g. after doing no damage")
				return false;			-- he is not a valid target
			end;

			if( self.Battling == true  and		-- we have aggro
			target.TargetPtr ~= self.Address ) then	-- but not from that mob
				debug_target("we have aggro from another mob")
				return false;         
			end;
		end

		-- PK protect
		if( target.Type == PT_PLAYER ) then      -- Player are type == 1
			if ( self.Battling == false ) then   -- if we don't have aggro then
				debug_target("PK player, but noone fighting us")
				return false;         -- he is not a valid target
			end;

			if( self.Battling == true  and         -- we have aggro
				target.TargetPtr ~= self.Address ) then   -- but not from the PK player
				debug_target("PK player, aggro, but he don't target us")
				return false;
			end;
		end;

		-- Friends aren't enemies
		if( self:isFriend(target) ) then
			if ( self.Battling == false ) then   -- if we don't have aggro then
				debug_target("target is in friends")
				return false;         -- he is not a valid target
			end;

			if( self.Battling == true  and         -- we have aggro, check if the 'friend' is targeting us
				target.TargetPtr ~= self.Address ) then   -- but not from that target
				debug_target("target is in friends, aggro, but not from that target")
				return false;         
			end;
		end;

		if( settings.profile.options.ANTI_KS ) then
			-- Not a valid enemy
			if( not target.Attackable ) then
				printf(language[30], target.Name);
				debug_target("anti kill steal: target not attackable")
				return false;
			end


			-- If they aren't targeting us, and they have less than full HP
			-- then they must be fighting somebody else.
			-- If it's a friend, then it is a valid target; help them.
			if( target.TargetPtr ~= self.Address ) then

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

function CPlayer:update()
	-- Ensure that our address hasn't changed. If it has, fix it.
	local tmpAddress = memoryReadIntPtr(getProc(), staticcharbase_address, charPtr_offset);
	if( tmpAddress ~= self.Address and tmpAddress ~= 0 ) then
		self.Address = tmpAddress;
		cprintf(cli.green, language[40], self.Address);
	end;


	CPawn.update(self); -- run base function
	self.Casting = (debugAssert(memoryReadInt(getProc(), self.Address + castbar_offset), language[41]) ~= 0);

	self.Battling = debugAssert(memoryReadBytePtr(getProc(), staticcharbase_address, inBattle_offset), language[41]) == 1;
	
	-- remember aggro start time, used for timed ranged pull
	if( self.Battling == true ) then
		if(self.aggro_start_time == 0) then
			self.aggro_start_time = os.time();
		end
	else
		self.aggro_start_time = 0;
	end

	local Vec1 = debugAssert(memoryReadFloat(getProc(), self.Address + chardirXUVec_offset), language[41]);
	local Vec2 = debugAssert(memoryReadFloat(getProc(), self.Address + chardirYUVec_offset), language[41]);

	if( Vec1 == nil ) then Vec1 = 0.0; end;
	if( Vec2 == nil ) then Vec2 = 0.0; end;

	self.Direction = math.atan2(Vec2, Vec1);


	if( self.Casting == nil or self.Battling == nil or self.Direction == nil ) then
		error("Error reading memory in CPlayer:update()");
	end
end

function CPlayer:clearTarget()
	cprintf(cli.green, language[33]);
	memoryWriteInt(getProc(), self.Address + charTargetPtr_offset, 0);
	self.TargetPtr = 0;
end

-- returns true if this CPawn is registered as a friend
function CPlayer:isFriend(pawn)
	if( not pawn ) then
		error("CPlayer:isFriend() received nil\n", 2);
	end;

	if( not settings ) then
		return false;
	end;

	pawn:update();

	for i,v in pairs(settings.profile.friends) do
		if( string.find( string.lower(pawn.Name), string.lower(v), 1, true) ) then
--		if(string.lower(pawn.Name) == string.lower(v)) then
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

function CPlayer:logout(fc_shutdown)
-- importing:
--   fc_shutdown true/false/nil
--   if nil, profile option 'settings.profile.options.LOGOUT_SHUTDOWN'
--   will decide if shutdown or not occurs

	cprintf(cli.yellow, language[50], os.date() );	-- Logout at %time%

	if( fc_shutdown == nil  and  settings.profile.options.LOGOUT_SHUTDOWN == true ) then
		fc_shutdown = true;
	end;

	if( settings.profile.hotkeys.MACRO ) then
		RoMScript("Logout();");
		yrest(30000); -- Wait for the log out to process
	-- DEPRECATED
	elseif( settings.profile.hotkeys.LOGOUT_MACRO ) then
		keyboardPress(settings.profile.hotkeys.LOGOUT_MACRO.key);
		yrest(30000);	-- Wait for the log out to process
	-- END DEPRECATED
	else
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
	if( self.Battling == false )  then		-- no aggro
		return false;
	end;
	
	-- don't break friendly skills
	if( _skill_type == STYPE_HEAL  or
	    _skill_type == STYPE_BUFF  or
	    _skill_type == STYPE_HOT ) then
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
	if( target.TargetPtr ~= self.Address  and	-- check HP, because death targets also have not target
	    target.HP/target.MaxHP*100 > 90 ) then			-- target is alive and no attacking us
-- there is a bug in client. Sometimes target is death and so it is not targeting us anymore
-- and at the same time the target HP are above 0
-- so we say > 90% life is alive :-)

		if( _jump == true ) then		-- jump to abort casting
			keyboardPress(settings.hotkeys.JUMP.key);
		end;
		cprintf(cli.green, language[36], target.Name);	-- Aggro during first strike/cast
		self:clearTarget();
		return true;
	end;
end

-- find a target with the ingame target key
-- is used while moving and could also used before moving or after fight
function CPlayer:findTarget()

	if(settings.hotkeys.TARGET.modifier) then
		keyboardHold(settings.hotkeys.TARGET.modifier);
	end
	keyboardPress(settings.hotkeys.TARGET.key);
	if(settings.hotkeys.TARGET.modifier) then
		keyboardRelease(settings.hotkeys.TARGET.modifier);
	end

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
-- if using type 'full', the bot will only rest if HP or MP is below a defined level 
-- you define that level in your profile with the options MP_REST and HP_REST
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
	local hf_mana_rest = (player.MaxMana * settings.profile.options.MP_REST / 100);	-- rest if mana is lower then
	local hf_hp_rest   = (player.MaxHP   * settings.profile.options.HP_REST / 100);	-- rest if HP is lower then

	if( player.Mana >= hf_mana_rest  and player.HP >= hf_hp_rest and
	    _resttype == 'full' ) then	-- nothing to do
		return;								-- go back
	end;
	
	local restStart = os.time();		-- set start timer

	if( _resttype == "full") then
		cprintf(cli.green, language[38], ( hf_resttime ) );		-- Resting up to %s to fill up mana and HP
	else
		cprintf(cli.green, language[71], ( hf_resttime ) );		-- Resting for %s seconds.
	end;

	while ( true ) do

		self:update();

		if( self.Battling ) then          -- we get aggro,
			self:clearTarget();       -- get rid of mob to be able to target attackers
			cprintf(cli.green, language[39] );   -- get aggro 
			return;
		end;
		
		-- check if resttime finished
		if( os.difftime(os.time(), restStart ) > ( hf_resttime ) ) then
			cprintf(cli.green, language[70], ( hf_resttime ) );   -- Resting finished after %s seconds
			return;
		end;

		-- check if HP/Mana full
		if( player.Mana == player.MaxMana  and		-- some chars have MaxMana = 0
 	 	    player.HP   == player.MaxHP    and
 	 	    _resttype   == "full" ) then		-- Mana and HP are full
			local restAddStart = os.time();		-- set additional rest timer
			while ( true ) do	-- rnd addition
				self:update();
				if( os.difftime(os.time(), restAddStart ) > _restaddrnd ) then
					break;
				end;
				if( self.Battling ) then          -- we get aggro,
					self:clearTarget();       -- get rid of mob to be able to target attackers
					cprintf(cli.green, language[39] );   -- Stop resting because of aggro
					return;
				end;
				self:checkPotions();   
				self:checkSkills( ONLY_FRIENDLY ); 		-- only cast friendly spells to ourselfe
				yrest(100);
			end;

			cprintf(cli.green, language[70], os.difftime(os.time(), restStart ) );   -- full after x sec
			return;
		end;

		self:checkPotions();   
		self:checkSkills( ONLY_FRIENDLY ); 		-- only cast friendly spells to ourselfe

		yrest(100);

	end;			-- end of while

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

	cprintf(cli.yellow, language[89], os.date(), getKeyName(settings.hotkeys.START_BOT.key)  );  

	local hf_key = "";
	while(true) do

		local hf_key_pressed = false;

		if( keyPressedLocal(settings.hotkeys.START_BOT.key) ) then	-- start key pressed
			hf_key_pressed = true;
			hf_key = "AWAKE";
		end;

		if( hf_key_pressed == false ) then	-- key released, do the work

			-- START Key: wake up
			if( hf_key == "AWAKE" ) then
				hf_key = " ";	-- clear last pressed key

				cprintf(cli.yellow, language[90], getKeyName(settings.hotkeys.START_BOT.key),  os.date() );  
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
				mousePawn = CPawn(memoryReadIntPtr(getProc(), staticcharbase_address, mousePtr_offset));
				-- id 110504 Waffenhersteller Dimar
				-- id 110502 Dan (Gemischtwarenhändler
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

-- auto interact with a merchant
function CPlayer:merchant(_npcname)
	if self:target_NPC(_npcname) then
		yrest(3000);
		RoMScript("ChoiceOption(1)");
		yrest(1000);
		RoMScript("ClickRepairAllButton()");
		yrest(1000);
		inventory:update();
		inventory:storeBuyConsumable("healing", settings.profile.options.HEALING_POTION);
		inventory:storeBuyConsumable("mana", settings.profile.options.MANA_POTION);
		inventory:storeBuyConsumable("arrow_quiver", settings.profile.options.ARROW_QUIVER);
		inventory:storeBuyConsumable("thrown_bag", settings.profile.options.THROWN_BAG);
		inventory:update();
	end
	
end

function CPlayer:target_NPC(_npcname)

	if( not _npcname ) then
		cprintf(cli.yellow, language[133]);	-- Please give a NPC name
		return
	end

	if(settings.hotkeys.TARGET_FRIEND.modifier) then
		cprintf(cli.yellow, language[134], 	-- we don't support modifiers
		   getKeyName(settings.hotkeys.TARGET_FRIEND.modifier), 
		   getKeyName(settings.hotkeys.TARGET_FRIEND.key) );
		return
	end

	cprintf(cli.green, language[135], _npcname);	-- We try to find NPC 

	local found_npc = false;
	local counter = 0;
	
	while(true) do
		counter = counter + 1;
		
		-- turn character if first try wasn't successfull
		if( counter == 2 ) then
			self:turnDirection(-45);
		elseif( counter == 3 ) then
			self:turnDirection(90);
		elseif( counter > 3 and  counter < 9) then
			self:turnDirection(45);
		elseif( counter > 8 ) then
			break;
		end

		for i = 1, 6 do
			keyboardPress(settings.hotkeys.TARGET_FRIEND.key);
			yrest(100);
			player:update();

			if(player.TargetPtr ~= 0) then
				found_npc = true;				-- we found something
				local target = self:getTarget();		-- read target informations
				cprintf(cli.green, "%s, ", target.Name);	-- print name

				if( string.find(string.lower(target.Name), string.lower(_npcname), 1, true ) ) then

					cprintf(cli.green, language[136], _npcname);	-- We successfully target NPC
					if( settings.profile.hotkeys.MACRO ) then
						RoMScript("UseSkill(1,1);");
					else
						if( settings.profile.hotkeys.ATTACK.modifier ) then
							keyboardHold(settings.hotkeys.ATTACK.modifier);
						end
						keyboardPress(settings.profile.hotkeys.ATTACK.key);
						if( settings.profile.hotkeys.ATTACK.modifier ) then
							keyboardRelease(settings.profile.hotkeys.ATTACK.modifier);
						end
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

			yrest(500);
		end
		
	end

	cprintf(cli.green, language[137], _npcname);	-- we can't find NPC
	if( not found_npc) then
		cprintf(cli.yellow, language[138], 	-- We didn't found any NPC
		  getKeyName(settings.hotkeys.TARGET_FRIEND.key) );	
	end
	
	return false;

end