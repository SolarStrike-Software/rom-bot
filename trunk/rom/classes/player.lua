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

function CPlayer:harvest()
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
			my = math.ceil(halfHeight * scanYMultiplier - (scanHeight / 2 * scanStepSize) + ( y * scanStepSize ));

			for x = 0,scanWidth-1 do
				mx = math.ceil(halfWidth * scanXMultiplier - (scanWidth / 2 * scanStepSize) + ( x * scanStepSize ));

				mouseSet(wx + mx, wy + my);
				yrest(settings.profile.options.HARVEST_SCAN_YREST);
				mousePawn = CPawn(memoryReadIntPtr(getProc(), staticcharbase_address, mousePtr_offset));

				if( mousePawn.Address ~= 0 and mousePawn.Type == PT_NODE
					and distance(self.X, self.Z, mousePawn.X, mousePawn.Z) < 150
					and database.nodes[mousePawn.Id] ) then
					return mousePawn.Address, mx, my;
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
		-- We found something. Lets harvest it.

		-- If out of distance, move and rescan
		local mousePawn = CPawn(foundHarvestNode);
		local dist = distance(self.X, self.Z, mousePawn.X, mousePawn.Z)

		if( dist > 35 and dist < 150 ) then
			printf("Move in\n");
			self:moveTo( CWaypoint(mousePawn.X, mousePawn.Z), true );
			yrest(200);
			foundHarvestNode, nodeMouseX, nodeMouseY = scan();
		end

		local startHarvestTime = os.time();
		while( foundHarvestNode ~= 0 and nodeMouseX and nodeMouseY ) do

			self:update();

			if( self.Battling ) then	-- we get aggro, stop harversting
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
end


function CPlayer:initialize()
	memoryWriteInt(getProc(), self.Address + castbar_offset, 0);
end

-- Resets "toggled" skills to off
function CPlayer:resetSkills()
	for i,v in pairs(settings.profile.skills) do
		if( v.Toggled ) then
			v.Toggled = false;
		end
	end
end

-- Check if you can use any skills, and use them
-- if they are needed.
function CPlayer:checkSkills(_only_friendly)
	for i,v in pairs(settings.profile.skills) do
		if( v:canUse(_only_friendly) ) then
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
			if( self:check_aggro_before_cast(JUMP_FALSE) and
			   ( v.Type == STYPE_DAMAGE or
			     v.Type == STYPE_DOT )  ) then	-- without jump
				return;
			end;

			v:use();
			yrest(100);
			self:update();

			printf(language[21], string.sub(v.Name.."'                     ", 1, 20));	-- first part of 'casting ...'

			-- Wait for casting to start (if it has a decent cast time)
			if( v.CastTime > 0 ) then
				local startTime = os.time();
				while( not self.Casting ) do
					-- break cast with jump if aggro before casting finished
					if( self:check_aggro_before_cast(JUMP_TRUE) and
					   ( v.Type == STYPE_DAMAGE or
					     v.Type == STYPE_DOT ) ) then	-- with jump
						printf("=>   *** aborted ***\n");	-- close print 'Casting ..."
						return;
					end;
					yrest(50);
					self:update();
					if( os.difftime(os.time(), startTime) > v.CastTime ) then
						self.Casting = true; -- force it.
						break;
					end
				end;

				while(self.Casting) do
					-- break cast with jump if aggro before casting finished
					if( self:check_aggro_before_cast(JUMP_TRUE) and
					   ( v.Type == STYPE_DAMAGE or
					     v.Type == STYPE_DOT ) ) then	--  with jump
						printf("=>   *** aborted ***\n");	-- close print 'Casting ..."
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
			if( v.Target == 0 ) then	-- target is unfriendly
				self.Cast_to_target = self.Cast_to_target + 1;
			end;

			if( v.CastTime == 0 ) then
				yrest(500);
			else
				yrest(100);
			end;

			-- print HP of our target
			-- we do it later, because the client needs some time to change the values
			local target = player:getTarget();
			printf("=>   "..target.Name.." ("..target.HP.."/"..target.MaxHP..")\n");	-- second part of 'casting ...'
	
		end
	end
end

-- Check if you need to use any potions, and use them.
function CPlayer:checkPotions()
	-- Still cooling down, don't use.
	if( os.difftime(os.time(), self.PotionLastUseTime) < settings.profile.options.POTION_COOLDOWN ) then
		return;
	end


	-- If we need to use a health potion
	if( (self.HP/self.MaxHP*100) < settings.profile.options.HP_LOW_POTION ) then
		local modifier = settings.profile.hotkeys.HP_POTION.modifier
		if( modifier ) then keyboardHold(modifier); end
		keyboardPress(settings.profile.hotkeys.HP_POTION.key);
		if( modifier ) then keyboardRelease(modifier); end

		self.PotionLastUseTime = os.time();
		cprintf(cli.green, language[10]);

		if( self.Fighting ) then
			yrest(1000);
		end
	end

	-- If we need to use a mana potion(if we even have mana)
	if( self.MaxMana > 0 ) then
		if( (self.Mana/self.MaxMana*100) < settings.profile.options.MP_LOW_POTION ) then
			local modifier = settings.profile.hotkeys.MP_POTION.modifier
			if( modifier ) then keyboardHold(modifier); end
			keyboardPress(settings.profile.hotkeys.MP_POTION.key);
			if( modifier ) then keyboardRelease(modifier); end

			self.PotionLastUseTime = os.time();
			cprintf(cli.green, language[11]);

			if( self.Fighting ) then
				yrest(1000);
			end
		end
	end
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

		if( settings.profile.hotkeys.ATTACK.modifier ) then
			keyboardHold(settings.hotkeys.ATTACK.modifier);
		end
		keyboardPress(settings.profile.hotkeys.ATTACK.key);
		if( settings.profile.hotkeys.ATTACK.modifier ) then
			keyboardRelease(settings.profile.hotkeys.ATTACK.modifier);
		end
	end

	-- Prep for battle, if needed.
	--self:checkSkills();


	if( settings.profile.options.COMBAT_TYPE == "melee" ) then
		registerTimer("timedAttack", secondsToTimer(2), timedAttack);

		-- start melee attack (even if out of range)
		timedAttack();
	end

	local target = self:getTarget();
	local lastHitTime = os.time();
	local lastTargetHP = target.HP;
	local move_closer_counter = 0;		-- count move closer trys
	self.Cast_to_target = 0;				-- reset counter cast at enemy target

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
		if( os.difftime(os.time(), lastHitTime) > settings.profile.options.MAX_FIGHT_TIME ) then
			printf("Taking too long to damage target, breaking sequence...\n");
			player.Last_ignore_target_ptr = player.TargetPtr;	-- remember break target
			player.Last_ignore_target_time = os.time();		-- and the time we break the fight
			self:clearTarget();
			break;
		end


		if( target.HP ~= lastTargetHP ) then
			lastHitTime = os.time();
			lastTargetHP = target.HP;
			printf(language[23]);
		end

		local dist = distance(self.X, self.Z, target.X, target.Z);

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
		if( settings.profile.options.COMBAT_TYPE == "ranged" ) then
			if( settings.profile.options.COMBAT_DISTANCE ~= nil ) then
				suggestedRange = settings.profile.options.COMBAT_DISTANCE;
			else
				suggestedRange = 155;
			end
		end

		if( dist > suggestedRange ) then

			-- count move closer and break if to much
			move_closer_counter = move_closer_counter + 1;		-- count our move tries
			if( move_closer_counter > 3  and
			    settings.profile.options.COMBAT_TYPE == "ranged" ) then
				cprintf(cli.green, "To much tries to come closer. We stop attacking that target\n");
				self:clearTarget();
				break;
			end
			
			printf(language[25], suggestedRange, dist);
			-- move into distance
			local angle = math.atan2(target.Z - self.Z, target.X - self.X);
			local posX, posZ;
			local success, reason;


			if( settings.profile.options.COMBAT_TYPE == "ranged" ) then
				-- Move closer in increments
				local movedist = dist/10; if( dist < 50 ) then movedist = dist - 5; end;
				if( dist > 50 and movedist < 50 ) then movedist = 50 end;

				posX = self.X + math.cos(angle) * (movedist);
				posZ = self.Z + math.sin(angle) * (movedist);
				success, reason = player:moveTo(CWaypoint(posX, posZ), true);
			elseif( settings.profile.options.COMBAT_TYPE == "melee" ) then
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
		if( not self:haveTarget() ) then
			break;
		end
	end

	self:resetSkills();

	if( settings.profile.options.COMBAT_TYPE == "melee" ) then
		unregisterTimer("timedAttack");
	end

	if( type(settings.profile.events.onLeaveCombat) == "function" ) then
		local status,err = pcall(settings.profile.events.onLeaveCombat);
		if( status == false ) then
			local msg = sprintf("onLeaveCombat error: %s", err);
			error(msg);
		end
	end

	-- give client a little time to update battle flag, if we loot even at combat
	-- we don't need the time
	if( settings.profile.options.LOOT_IN_COMBAT ~= true ) then
		yrest(800);
	end;


	-- Monster is dead (0 HP) but still targeted.
	-- Loot and clear target.
	self:update();
	if( self.TargetPtr ~= 0 ) then
		local target = CPawn(self.TargetPtr);

		if( settings.profile.options.LOOT == true ) then
			if( settings.profile.options.LOOT_IN_COMBAT == true ) then
				self:loot();
			else
				if( not self.Battling ) then
					-- Skip looting when under attack
					self:loot();
				end
			end
		end

		self:clearTarget();
	end;

	self.Fights = self.Fights + 1;		-- count our fights
	cprintf(cli.green, language[27]);	-- Fight finished. Target dead/lost
	self.Fighting = false;
end

function CPlayer:loot()
	local target = self:getTarget();

	if( target == nil or target.Address == 0 ) then
		return;
	end

	local dist = distance(self.X, self.Z, target.X, target.Z);
	local lootdist = 100;

	-- Set to combat distance; update later if loot distance is set
	if( settings.profile.options.COMBAT_TYPE == "ranged" ) then
		lootdist = settings.profile.options.COMBAT_DISTANCE;
	end

	if( settings.profile.options.LOOT_DISTANCE ) then
		lootdist = settings.profile.options.LOOT_DISTANCE;
	end


	if( dist < lootdist ) then -- only loot when close by
		cprintf(cli.green, language[31]);
		-- "attack" is also the hotkey to loot, strangely.
		yrest(500);
		keyboardPress(settings.profile.hotkeys.ATTACK.key);
		yrest(settings.profile.options.LOOT_TIME + dist*15); -- dist*15 = rough calculation of how long it takes to walk there

		-- rnd pause from 3-6 sec after loot to look more human
		if( settings.profile.options.LOOT_PAUSE_AFTER > 0 ) then
			self:restrnd( settings.profile.options.LOOT_PAUSE_AFTER,3,6);
		end;

		-- now take a 'step' forward (closes loot bag if full inventory)
		keyboardPress(settings.hotkeys.MOVE_FORWARD.key);

		-- Maybe take a step forward to pick up a buff.
		if( math.random(100) > 80 ) then
			keyboardHold(settings.hotkeys.MOVE_FORWARD.key);
			yrest(500);
			keyboardRelease(settings.hotkeys.MOVE_FORWARD.key);
		end
	else
		cprintf(cli.green, language[32]);
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

	-- direction ok, now look for a target before start movig
	if( (not ignoreCycleTargets) and (not self.Battling) ) then	
		if( self:findTarget() ) then			-- find a new target
--			cprintf(cli.turquoise, language[28]);	-- stopping waypoint::target acquired
			cprintf(cli.turquoise, "Stopping waypoint: Target acquired before moving.\n");	-- stopping waypoint::target acquired
			success = false;
			failreason = WF_TARGET;
			return success, failreason;
		end;
	end;

	local success, failreason = true, WF_NONE;
	local dist = distance(self.X, self.Z, waypoint.X, waypoint.Z);
	local lastDist = dist;
	local lastDistImprove = os.time();
	while( dist > 15.0 ) do
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

		self:checkPotions();
		self:checkSkills( ONLY_FRIENDLY ); 		-- only cast friendly spells to ourselfe

		-- We're still making progress
		if( dist < lastDist ) then
			lastDistImprove = os.time();
			lastDist = dist;
		elseif(  dist > lastDist + 40 ) then
			-- Make sure we didn't pass it up
			printf(language[29]);
			success = false;
			failreason = WF_DIST;
			break;
		end;

		if( os.difftime(os.time(), lastDistImprove) > 3 ) then
			-- We haven't improved for 3 seconds, assume stuck
			success = false;
			failreason = WF_STUCK;
			break;
		end

		dist = distance(self.X, self.Z, waypoint.X, waypoint.Z);
		angle = math.atan2(waypoint.Z - self.Z, waypoint.X - self.X);
		angleDif = angleDifference(angle, self.Direction);

		-- Continue to make sure we're facing the right direction
		if( settings.profile.options.QUICK_TURN and angleDif > math.rad(1) ) then
			self:faceDirection(angle);
			camera:setRotation(angle);
		end

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
		elseif( angleDif > math.rad(1) ) then
			if( settings.profile.options.QUICK_TURN ) then
				camera:setRotation(angle);
			end

			self:faceDirection(angle);
			keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
			keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );
			keyboardHold( settings.hotkeys.MOVE_FORWARD.key );
		else
			keyboardHold( settings.hotkeys.MOVE_FORWARD.key );
		end

		--keyboardHold( settings.hotkeys.MOVE_FORWARD.key );
		yrest(100);
		self:update();
		waypoint:update();

	end
	keyboardRelease( settings.hotkeys.MOVE_FORWARD.key );
	keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
	keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );

	if( success ) then
		-- We successfully reached the waypoint.
		-- Execute it's action, if it has one.

		if( waypoint.Action and type(waypoint.Action) == "string" ) then
			local actionchunk = loadstring(waypoint.Action);
			assert( actionchunk );
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
			__RPL:setWaypointIndex(__RPL:getNearestWaypoint(player.X, player.Z));
		else
			__WPL:setWaypointIndex(__WPL:getNearestWaypoint(player.X, player.Z));
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
		local target = self:getTarget();

		if( target == nil ) then
			return false;
		end;

		-- check level of target against our leveldif settings
		if( ( target.Level - self.Level ) > settings.profile.options.TARGET_LEVELDIF_ABOVE  or
		( self.Level - target.Level ) > settings.profile.options.TARGET_LEVELDIF_BELOW ) then
			if ( self.Battling == false ) then	-- if we don't have aggro then
				return false;			-- he is not a valid target
			end;

			if( self.Battling == true  and		-- we have aggro
			target.TargetPtr ~= self.Address ) then	-- but not from that mob
				return false;         
			end;
		end;

		-- check if we just ignored that target / ignore it for 10 sec
		if(self.TargetPtr == player.Last_ignore_target_ptr  and
		   os.difftime(os.time(), player.Last_ignore_target_time)  < 10 )then	
			if ( self.Battling == false ) then	-- if we don't have aggro then
				cprintf(cli.green, "We ignore %s for %s seconds more\n", target.Name, 10-os.difftime(os.time(), player.Last_ignore_target_time ) );
				return false;			-- he is not a valid target
			end;

			if( self.Battling == true  and		-- we have aggro
			target.TargetPtr ~= self.Address ) then	-- but not from that mob
				return false;         
			end;
		end

		-- PK protect
		if( target.Type == PT_PLAYER ) then      -- Player are type == 1
			if ( self.Battling == false ) then   -- if we don't have aggro then
				return false;         -- he is not a valid target
			end;

			if( self.Battling == true  and         -- we have aggro
				target.TargetPtr ~= self.Address ) then   -- but not from the PK player
				return false;
			end;
		end;

		-- Friends aren't enemies
		if( self:isFriend(target) ) then
			if ( self.Battling == false ) then   -- if we don't have aggro then
				return false;         -- he is not a valid target
			end;

			if( self.Battling == true  and         -- we have aggro, check if the 'friend' is targeting us
				target.TargetPtr ~= self.Address ) then   -- but not from that target
				return false;         
			end;
		end;

		if( settings.profile.options.ANTI_KS ) then
			-- Not a valid enemy
			if( not target.Attackable ) then
				printf(language[30], target.Name);
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
						return false;
					end
				else
					-- They definitely have a target.
					-- If it is a friend, we can help.
					-- Otherwise, leave it alone.

					local targetOfTarget = CPawn(target.TargetPtr);

					if( not self:isFriend(targetOfTarget) ) then
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
		if(string.lower(pawn.Name) == string.lower(v)) then
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

	if( settings.profile.hotkeys.LOGOUT_MACRO ) then
		keyboardPress(settings.profile.hotkeys.LOGOUT_MACRO.key);
		yrest(30000);	-- Wait for the log out to process
	else
		local PID = findProcessByWindow(getWin()); -- Get process ID
		os.execute("TASKKILL /PID " .. PID .. " /F");
		while(true) do
			-- Wait for process to close...
			if( findProcessByWindow(__WIN) ~= PID ) then
				printf("Process successfully closed\n");
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

function CPlayer:check_aggro_before_cast(_jump)
-- break cast in last moment / works not for groups, because you get battling flag from your groupmembers  !!!
-- works also if target is not visible and we get aggro from another mob
-- _jump = true       abort cast with jump hotkey

	self:update();
	if( self.Battling == false )  then		-- no aggro
		return false;
	end;
			
	local target = self:getTarget();
	if( self.TargetPtr ~= 0 ) then  target:update(); end;

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
--	if( self:haveTarget() and self.Fighting == false ) then
-- do we nee self.Fighting == false check?
-- not sure, so I just deleted it to see what happens

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

--	cprintf(cli.yellow, "Go to sleep at %s. Press %s to wake up or %s to really stop the bot.\n", os.date(), getKeyName(settings.hotkeys.START_BOT.key), getKeyName(settings.hotkeys.STOP_BOT.key) );  
	cprintf(cli.yellow, "Go to sleep at %s. Press %s to wake up.\n", os.date(), getKeyName(settings.hotkeys.START_BOT.key)  );  

	local hf_key = "";
	while(true) do

		local hf_key_pressed = false;

--		if( keyPressedLocal(settings.hotkeys.STOP_BOT.key) ) then	-- sleep/pause key pressed
--			hf_key_pressed = true;
--			hf_key = "STOP";
--		end;
		if( keyPressedLocal(settings.hotkeys.START_BOT.key) ) then	-- start key pressed
			hf_key_pressed = true;
			hf_key = "AWAKE";
		end;

		if( hf_key_pressed == false ) then	-- key released, do the work

			-- STOP Key: stop the bot really
			-- does not work proper becaus auf the pausecallback assigned to the
			-- top key
--			if( hf_key == "STOP" ) then
--				hf_key = " ";	-- clear last pressed key
--
--				-- now the stop work is done by the function pauseCallback()
--				-- but we clear the flag to be awake after restart
--				self.Sleeping = false;	-- we are awake
--				stopPE();		-- we now really stop the bot
--				return;			-- after stop, now go back
--			end;

			-- START Key: wake up
			if( hf_key == "AWAKE" ) then
				hf_key = " ";	-- clear last pressed key

				cprintf(cli.yellow, "Awake from sleep after pressing %s at %s\n", getKeyName(settings.hotkeys.START_BOT.key),  os.date() );  
				self.Sleeping = false;	-- we are awake
				break;
			end;

			hf_key = " ";	-- clear last pressed key
		end;

		self:update();
		-- wake up if aggro, but we don't clear the sleeping flag
		if( self.Battling ) then          -- we get aggro,
			self:clearTarget();       -- get rid of mob to be able to target attackers
			cprintf(cli.yellow, "Awake from sleep because of aggro at %s\n", os.date() );  
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
			my = math.ceil(halfHeight * scanYMultiplier - (scanHeight / 2 * scanStepSize) + ( y * scanStepSize ));

			for x = 0,scanWidth-1 do
				mx = math.ceil(halfWidth * scanXMultiplier - (scanWidth / 2 * scanStepSize) + ( x * scanStepSize ));

				mouseSet(wx + mx, wy + my);
				yrest(settings.profile.options.HARVEST_SCAN_YREST);
				mousePawn = CPawn(memoryReadIntPtr(getProc(), staticcharbase_address, mousePtr_offset));
--	printf("mousePawn.Adress; %s, mousePawn.Type %s id %s\n", mousePawn.Address, mousePawn.Type, mousePawn.Id);
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
			printf("Move in\n");
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

function CPlayer:mouseclickL(_x, _y, _wwide, _whigh)
	if( foregroundWindow() ~= getWin() ) then
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
		cprintf(cli.green, "Clicking mouseL at %d,%d in %dx%d (recalculated from %d,%d by %dx%d)\n", 
			hf_x, hf_y, wwide, whigh, _x, _y, _wwide, _whigh);
	else
		hf_x = _x;
		hf_y = _y;
		cprintf(cli.green, "Clicking mouseL at %d,%d in %dx%d\n", 
			hf_x, hf_y, wwide, whigh);
	end;
	
	mouseSet(wx + hf_x, wy + hf_y);
	yrest(100);

	mouseLClick();
	yrest(100);

	attach(getWin()); -- Re-attach bindings
end
