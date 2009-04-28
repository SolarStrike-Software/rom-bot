include("pawn.lua");
include("skill.lua");

WF_NONE = 0;   -- We didn't fail
WF_TARGET = 1; -- Failed waypoint because we have a target
WF_DIST = 2;   -- Broke because our distance somehow increased. It happens.
WF_STUCK = 3;  -- Failed waypoint because we are stuck on something.



CPlayer = class(CPawn);

function CPlayer:initialize()
	memoryWriteInt(getProc(), self.Address + castbar_offset, 0);
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

		yrest(1000);
	end

	-- If we need to use a mana potion(if we even have mana)
	if( self.MaxMana > 0 ) then
		if( (self.Mana/self.MaxMana*100) < settings.profile.options.MP_LOW_POTION ) then
			local modifier = settings.profile.hotkeys.MP_POTION.modifier
			if( modifier ) then keyboardHold(modifier); end
			keyboardPress(settings.profile.hotkeys.MP_POTION.key);
			if( modifier ) then keyboardRelease(modifier); end

			cprintf(cli.green, language[11]);

			yrest(1000);
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
			logMessage("Taking too long to damage target, breaking sequence...\n");
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
			end

			if( not success ) then
				player:unstick();
			end

			yrest(500);
		end

		-- Make sure we're facing the enemy
		local angle = math.atan2(target.Z - self.Z, target.X - self.X);
		local angleDif = angleDifference(angle, self.Direction);
		local correctingAngle = false;
		local startTime = os.time();
		-- TODO:
		while( angleDif > math.rad(15) ) do
			if( self.HP <= 0 or self.Alive == false ) then
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

		self:checkPotions();
		self:checkSkills();

		yrest(100);
		target:update();
		self:update();
		if( not self:haveTarget() ) then
			break;
		end
	end

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

	-- Monster is dead (0 HP) but still targeted.
	-- Loot and clear target.
	self:update();
	if( self.TargetPtr ~= 0 ) then
		if( settings.profile.options.LOOT == true ) then
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
				keyboardPress(settings.hotkeys.MOVE_BACKWARD.key);

				-- Maybe take a step forward to pick up a buff.
				if( math.random(100) > 20 ) then
					keyboardHold(settings.hotkeys.MOVE_FORWARD.key);
					yrest(500);
					keyboardRelease(settings.hotkeys.MOVE_FORWARD.key);
				end
			else
				cprintf(cli.green, language[32]);
			end
		end

		--self:clearTarget();
	end;


	cprintf(cli.green, language[27]);
	self.Fighting = false;
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

	-- Make sure we don't have a garbage (dead) target
	if( self.TargetPtr ~= 0 ) then
		local target = CPawn(self.TargetPtr);
		if( target.HP <= 1 ) then
			self:clearTarget();
		end
	end


	-- If more than X degrees off, correct before moving.
	local rotateStartTime = os.time();
	while( angleDif > math.rad(25) ) do
		if( self.HP <= 0 or self.Alive == false ) then
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
		else
			-- rotate right
			keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
			keyboardHold( settings.hotkeys.ROTATE_RIGHT.key );
		end

		yrest(100);
		self:update();
		angleDif = angleDifference(angle, self.Direction);
	end

	keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
	keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );

	yrest(100);

	local success, failreason = true, WF_NONE;
	local dist = distance(self.X, self.Z, waypoint.X, waypoint.Z);
	local lastDist = dist;
	local lastDistImprove = os.time();
	keyboardHold( settings.hotkeys.MOVE_FORWARD.key );
	while( dist > 25.0 ) do
		if( self.HP <= 0 or self.Alive == false ) then
			return false, WF_NONE;
		end;

		if( canTarget == false and os.difftime(os.time(), startTime) > 1 ) then
			canTarget = true;
		end

		if( canTarget and (not ignoreCycleTargets) ) then
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
		else
			keyboardRelease( settings.hotkeys.ROTATE_LEFT.key );
			keyboardRelease( settings.hotkeys.ROTATE_RIGHT.key );
		end

		keyboardHold( settings.hotkeys.MOVE_FORWARD.key );
		yrest(100);
		self:update();
		waypoint:update();
		dist = distance(self.X, self.Z, waypoint.X, waypoint.Z);
		angle = math.atan2(waypoint.Z - self.Z, waypoint.X - self.X);
		angleDif = angleDifference(angle, self.Direction);
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

		-- Friends aren't enemies
		if( self:isFriend(target) ) then
			return false;
		end;

		if( settings.profile.options.ANTI_KS ) then
			-- They must have 100% HP, unless you're helping a friend
			local targetOfTarget = CPawn(target.TargetPtr);

			if( target.TargetPtr ~= self.Address ) then
				if( (targetOfTarget.Address ~= 0) and
				(target.HP / target.MaxHP < 100) and
				(not self:isFriend(targetOfTarget)) ) then
					return false;
				end
			end

			if( target:haveTarget() and target.TargetPtr ~= player.Address ) then
				return false;
			end

			-- Not a valid enemy
			if( not target.Attackable ) then
				printf(language[30], target.Name);
				return false;
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
	if( tmpAddress ~= self.Address ) then
		self.Address = tmpAddress;
		cprintf(cli.green, language[40], self.Address);
	end;

	CPawn.update(self); -- run base function
	self.Casting = (debugAssert(memoryReadInt(getProc(), self.Address + castbar_offset), language[41]) ~= 0);

	self.Battling = debugAssert(memoryReadBytePtr(getProc(), staticcharbase_address, inBattle_offset), language[41]);

	--local Vec1 = debugAssert(memoryReadFloatPtr(getProc(), self.Address + charDirVectorPtr_offset, camUVec1_offset), language[41]);
	--local Vec2 = debugAssert(memoryReadFloatPtr(getProc(), self.Address + charDirVectorPtr_offset, camUVec2_offset), language[41]);

	local Vec1 = debugAssert(memoryReadFloat(getProc(), self.Address + camUVec1_offset), language[41]);
	local Vec2 = debugAssert(memoryReadFloat(getProc(), self.Address + camUVec2_offset), language[41]);

	if( Vec1 == nil ) then Vec1 = 0.0; end;
	if( Vec2 == nil ) then Vec2 = 0.0; end;

	self.Direction = math.atan2(Vec2, Vec1);


	if( self.Casting == nil or self.Battling == nil or self.Direction == nil ) then
		error("Error reading memory in CPlayer:update()");
	end


	-- If we were able to load our profile options...
	if( settings and settings.profile.options ) then
		local energyStorage1 = settings.profile.options.ENERGY_STORAGE_1;
		local energyStorage2 = settings.profile.options.ENERGY_STORAGE_2;

		if( energyStorage1 == "mana" ) then
			self.Mana = self.MP;
			self.MaxMana = self.MaxMP;
		elseif( energyStorage1 == "rage" ) then
			self.Rage = self.MP;
			self.MaxRage = self.MaxMP;
		elseif( energyStorage1 == "energy" ) then
			self.Energy = self.MP;
			self.MaxEnergy = self.MaxMP;
		elseif( energyStorage1 == "concentration" ) then
			self.Concentration = self.MP;
			self.MaxConcentration = self.MaxMP;
		end

		if( energyStorage2 == "mana" ) then
			self.Mana = self.MP2;
			self.MaxMana = self.MaxMP2;
		elseif( energyStorage2 == "rage" ) then
			self.Rage = self.MP2;
			self.MaxRage = self.MaxMP2;
		elseif( energyStorage2 == "energy" ) then
			self.Energy = self.MP2;
			self.MaxEnergy = self.MaxMP2;
		elseif( energyStorage2 == "concentration" ) then
			self.Concentration = self.MP2;
			self.MaxConcentration = self.MaxMP2;
		end
	end
end

function CPlayer:clearTarget()
	cprintf(cli.green, language[33]);
	memoryWriteInt(getProc(), self.Address + charTargetPtr_offset, 0);
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