include("pawn.lua");
include("skill.lua");

WF_NONE = 0;   -- We didn't fail
WF_TARGET = 1; -- Failed waypoint because we have a target
WF_DIST = 2;   -- Broke because our distance somehow increased. It happens.
WF_STUCK = 3;  -- Failed waypoint because we are stuck on something.



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
		local scanWidth = 10; -- Width, in 'steps', of the area to scan
		local scanHeight = 8; -- Height, in 'steps', of area to scan
		local scanXMultiplier = 1.0;
		local scanYMultiplier = 1.1;
		local scanStepSize = 35; -- Distance, in pixels, between 'steps'


		local mx, my; -- Mouse x/y temp values

		mouseSet(wx + (halfWidth*scanXMultiplier - (scanWidth/2*scanStepSize)),
		wy  + (halfHeight*scanYMultiplier - (scanHeight/2*scanStepSize)));
		yrest(100);

		-- Scan nearby area for a node
		for y = 0,scanHeight-1 do
			my = math.ceil(halfHeight * scanYMultiplier - (scanHeight / 2 * scanStepSize) + ( y * scanStepSize ));

			for x = 0,scanWidth-1 do
				mx = math.ceil(halfWidth * scanXMultiplier - (scanWidth / 2 * scanStepSize) + ( x * scanStepSize ));

				mouseSet(wx + mx, wy + my);
				yrest(10);
				mousePawn = CPawn(memoryReadIntPtr(getProc(), staticcharbase_address, mousePtr_offset));

				if( mousePawn.Address ~= 0 and mousePawn.Type == PT_NODE
					and distance(self.X, self.Z, mousePawn.X, mousePawn.Z) < 150
					and database.nodes[mousePawn.Id] ) then
					return mousePawn.Address, mx, my;
				end
			end
		end

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
			if( self.Battling ) then
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
				mouseLClick();
				yrest(100);
				mouseLClick();

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
function CPlayer:checkSkills()
	for i,v in pairs(settings.profile.skills) do
		if( v:canUse() ) then
			keyboardRelease( settings.hotkeys.MOVE_FORWARD.key );
			if( v.CastTime > 0 ) then
				yrest(200); -- Wait to stop only if not an instant cast spell
			end

			-- Make sure we aren't already busy casting something else
			while(self.Casting) do
				-- Waiting for casting to finish...
				yrest(100);
				self:update();
			end

			v:use();
			yrest(100);
			self:update();

			-- Wait for casting to start (if it has a decent cast time)
			
			if( v.CastTime > 0 ) then
				local startTime = os.time();
				while( not self.Casting ) do
					yrest(50);
					self:update();
					if( os.difftime(os.time(), startTime) > v.CastTime ) then
						self.Casting = true; -- force it.
						break;
					end
				end;

				while(self.Casting) do
					-- Waiting for casting to finish...
					yrest(10);
					self:update();
				end
				printf(language[20]);
			else
				yrest(500); -- assume 0.5 second yrest
			end

			if( v.CastTime == 0 ) then
				yrest(500);
			else
				yrest(100);
			end;
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

	cprintf(cli.green, language[22], target.Name);

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

		if( settings.options.ENABLE_FIGHT_SLOW_TURN ) then
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

	yrest(500);

	-- Monster is dead (0 HP) but still targeted.
	-- Loot and clear target.
	self:update();
	if( self.TargetPtr ~= 0 ) then
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


	cprintf(cli.green, language[27]);
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

		-- now take a 'step' backward (closes loot bag if full inventory)
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

	if( waypoint.Type == WPT_TRAVEL ) then
		ignoreCycleTargets = true;
	end;

	-- Make sure we don't have a garbage (dead) target
	if( self.TargetPtr ~= 0 ) then
		local target = CPawn(self.TargetPtr);
		if( target.HP <= 1 ) then
			self:clearTarget();
		end
	end


	-- If more than X degrees off, correct before moving.
	local rotateStartTime = os.time();
	local turningDir = -1; -- 0 = left, 1 = right
	while( angleDif > math.rad(65) ) do
		if( self.HP < 1 or self.Alive == false ) then
			return false, WF_NONE;
		end;

		if( settings.profile.options.QUICK_TURN == true ) then
			self:faceDirection(angle);
			angleDif = angleDifference(angle, self.Direction);
			break;
		end

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

	local success, failreason = true, WF_NONE;
	local dist = distance(self.X, self.Z, waypoint.X, waypoint.Z);
	local lastDist = dist;
	local lastDistImprove = os.time();
	keyboardHold( settings.hotkeys.MOVE_FORWARD.key );
	while( dist > 15.0 ) do
		if( self.HP < 1 or self.Alive == false ) then
			return false, WF_NONE;
		end;

		if( canTarget == false and os.difftime(os.time(), startTime) > 1 ) then
			canTarget = true;
		end

		if( canTarget and (not ignoreCycleTargets) and (not self.Battling) ) then
			if(settings.hotkeys.TARGET.modifier) then
				keyboardHold(settings.hotkeys.TARGET.modifier);
			end
			keyboardPress(settings.hotkeys.TARGET.key);
			if(settings.hotkeys.TARGET.modifier) then
				keyboardRelease(settings.hotkeys.TARGET.modifier);
			end

			yrest(10);
		end


		-- We've got a target, fight it instead of worrying about our waypoint.
		if( self:haveTarget() and self.Fighting == false ) then
			local target = self:getTarget();
			if( not target:haveTarget() ) then
				-- Target is free, attack it.
				cprintf(cli.turquoise, "Stopping waypoint::target acquired\n");
				success = false;
				failreason = WF_TARGET;
				break;
			end;

			if( target:getTarget().Address == self.Address ) then
				cprintf(cli.turquoise, language[28]);
				success = false;
				failreason = WF_TARGET;
				break;
			end
		end


		self:checkPotions();

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
		if( angleDif > math.rad(15) ) then
			keyboardRelease( settings.hotkeys.MOVE_FORWARD.key );
			keyboardRelease( settings.hotkeys.MOVE_BACKWARD.key );

			if( angleDifference(angle, self.Direction + 0.01) < angleDif ) then
					keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );
					keyboardHold( settings.hotkeys.ROTATE_LEFT.key );
					yrest(100);
			else
					keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
					keyboardHold( settings.hotkeys.ROTATE_RIGHT.key );
					yrest(100);
			end
		elseif( angleDif > 0.0 ) then
			keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
			keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );
			self:faceDirection(angle);

			keyboardHold( settings.hotkeys.MOVE_FORWARD.key );
		else
			keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
			keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );	
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

	--local pVec1 = debugAssert(memoryReadFloat(getProc(), self.Address + camUVec1_offset), language[41]);
	--local pVec2 = debugAssert(memoryReadFloat(getProc(), self.Address + camUVec2_offset), language[41]);

	memoryWriteFloat(getProc(), self.Address + camUVec1_offset, Vec1);
	memoryWriteFloat(getProc(), self.Address + camUVec2_offset, Vec2);

end

-- Attempt to unstick the player
function CPlayer:unstick()
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

	keyboardHold(straffkey);
	yrest(500 + math.random(500));
	keyboardRelease(straffkey);
end

function CPlayer:haveTarget()
	if( CPawn.haveTarget(self) ) then
		local target = self:getTarget();

		if( target == nil ) then
			return false;
		end;

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
			return false;
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

	local Vec1 = debugAssert(memoryReadFloat(getProc(), self.Address + camUVec1_offset), language[41]);
	local Vec2 = debugAssert(memoryReadFloat(getProc(), self.Address + camUVec2_offset), language[41]);

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
	if(self.Battling == true) then
		return;
	end;

	if( settings.profile.options.LOGOUT_TIME > 0 ) then
		local elapsed = os.difftime(os.time(), self.BotStartTime);

		if( elapsed >= settings.profile.options.LOGOUT_TIME * 60 ) then
			cprintf(cli.yellow, language[50]);

			if( settings.profile.hotkeys.LOGOUT_MACRO ) then
				keyboardPress(settings.profile.hotkeys.LOGOUT_MACRO.key);
				yrest(12000); -- Wait for the log out to process
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

			if( settings.profile.options.LOGOUT_SHUTDOWN ) then
				cprintf(cli.yellow, language[51]);
				os.execute("\"%windir%\\system32\\shutdown.exe -s -t 30\" "); --Shutdown in 30 seconds.
			end

			error("Exiting: Auto-logout", 0); -- Not really an error, but it will drop us back to shell.
		end
	end
end