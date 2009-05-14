CPawn = class(
	function (self, ptr)
		self.Address = ptr;
		self.Name = "<UNKNOWN>";
		self.Guild = "<UNKNOWN>";
		self.Level = 1;
		self.Level2 = 1;
		self.HP = 1000;
		self.MaxHP = 1000;
		self.MP = 1000;
		self.MaxMP = 1000;
		self.MP2 = 1000;
		self.MaxMP2 = 1000;
		self.X = 0.0;
		self.Y = 0.0;
		self.Z = 0.0;
		self.TargetPtr = 0;
		self.Direction = 0.0;
		self.Attackable = false;
		self.Alive = true;

		-- Directed more at player, but may be changed later.
		self.Battling = false; -- The actual "in combat" flag.
		self.Fighting = false; -- Internal use, does not depend on the client's battle flag
		self.Casting = false;
		self.Mana = 0;
		self.MaxMana = 0;
		self.Rage = 0;
		self.MaxRage = 0;
		self.Energy = 0;
		self.MaxEnergy = 0;
		self.Concentration = 0;
		self.MaxConcentration = 0;
		self.PotionLastUseTime = 0;
		self.Returning = false; -- Whether following the return path, or regular waypoints

		if( self.Address ~= 0 and self.Address ~= nil ) then self:update(); end
	end
);

function CPawn:update()
	local proc = getProc();
	local memerrmsg = "Failed to read memory";
	local tmp;

	tmp = debugAssert(memoryReadByte(proc, self.Address + charAlive_offset), memerrmsg);
	self.Alive = not(tmp == 9 or tmp == 8);
	self.HP = debugAssert(memoryReadInt(proc, self.Address + charHP_offset), memerrmsg);

	self.MaxHP = debugAssert(memoryReadInt(proc, self.Address + charMaxHP_offset), memerrmsg);
	self.MP = debugAssert(memoryReadInt(proc, self.Address + charMP_offset), memerrmsg);
	self.MaxMP = debugAssert(memoryReadInt(proc, self.Address + charMaxMP_offset), memerrmsg);
	self.MP2 = debugAssert(memoryReadInt(proc, self.Address + charMP2_offset), memerrmsg);
	self.MaxMP2 = debugAssert(memoryReadInt(proc, self.Address + charMaxMP2_offset), memerrmsg);
	self.Name = debugAssert(memoryReadString(proc, self.Address + charName_offset), memerrmsg);
	self.Level = debugAssert(memoryReadInt(proc, self.Address + charLevel_offset), memerrmsg);
	self.Level2 = debugAssert(memoryReadInt(proc, self.Address + charLevel2_offset), memerrmsg);

	self.TargetPtr = debugAssert(memoryReadInt(proc, self.Address + charTargetPtr_offset), memerrmsg);

	self.X = debugAssert(memoryReadFloat(proc, self.Address + charX_offset), memerrmsg);
	self.Y = debugAssert(memoryReadFloat(proc, self.Address + charY_offset), memerrmsg);
	self.Z = debugAssert(memoryReadFloat(proc, self.Address + charZ_offset), memerrmsg);

	self.Attackable = (memoryReadByte(proc, self.Address + pawnAttackable_offset) ~= 0);

	if( self.MaxMP == 0 ) then
		-- Prevent division by zero for entities that have no mana
		self.MP = 1;
		self.MaxMP = 1;
	end

	if( self.MaxMP2 == 0 ) then
		-- Prevent division by zero for entities that have no secondary mana
		self.MP2 = 1;
		self.MaxMP2 = 1;
	end

	if( self.Alive ==nil or self.HP == nil or self.MaxHP == nil or self.MP == nil or self.MaxMP == nil or
		self.MP2 == nil or self.MaxMP2 == nil or self.Name == nil or
		self.Level == nil or self.Level2 == nil or self.TargetPtr == nil or
		self.X == nil or self.Y == nil or self.Z == nil or self.Attackable == nil ) then

		error("Error reading memory in CPawn:update()");
	end
end

function CPawn:haveTarget()
	local proc = getProc();
	self.TargetPtr = memoryReadInt(proc, self.Address + charTargetPtr_offset);
	if( self.TargetPtr == nil ) then self.TargetPtr = 0; end;

	if( self.TargetPtr == 0 ) then
		return false;
	end;

	local tmp = CPawn(self.TargetPtr);

	-- You can't be your own target!
	if( self.TargetPtr == self.Address ) then
		return false;
	end

	if( tmp.HP < 1 ) then
		return false;
	end;

	return (tmp.Alive);
end

function CPawn:getTarget()
	if( self.TargetPtr) then
		return CPawn(self.TargetPtr);
	else
		return nil;
	end
end

function CPawn:alive()
	self:update();
	if( not self.Alive ) then
		return false;
	else
		return true;
	end
end

function CPawn:distanceToTarget()
	if( self.TargetPtr == 0 ) then return 0; end;

	local target = CPawn(self.TargetPtr);
	local tx,ty,tz = target.X, target.Y, target.Z;
	local px,py,pz = self.X, self.Y, self.Z;

	return math.sqrt( (tx-px)*(tx-px) + (ty-py)*(ty-py) + (tz-pz)*(tz-pz) );
end