PT_NONE = 0;
PT_PLAYER = 1;
PT_MONSTER = 2;
PT_NPC = 4;
PT_NODE = 4;

CLASS_NONE = -1;
CLASS_WARRIOR = 1;
CLASS_SCOUT = 2;
CLASS_ROGUE = 3;
CLASS_MAGE = 4;
CLASS_PRIEST = 5;
CLASS_KNIGHT = 6;
CLASS_RUNEDANCER = 7;
CLASS_DRUID = 8;

ATTACKABLE_MASK_PLAYER = 0x10000;
ATTACKABLE_MASK_MONSTER = 0xE0000;

local classEnergyMap = {
	[CLASS_NONE] = "none",
	[CLASS_WARRIOR] = "rage",
	[CLASS_SCOUT] = "concentration",
	[CLASS_ROGUE] = "energy",
	[CLASS_MAGE] = "mana",
	[CLASS_PRIEST] = "mana",
	[CLASS_KNIGHT] = "mana",
	[CLASS_RUNEDANCER] = "mana",
	[CLASS_DRUID] = "mana",
};

CPawn = class(
	function (self, ptr)
		self.Address = ptr;
		self.Name = "<UNKNOWN>";
		self.Id = 0;
		self.Type = PT_NONE;
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
		self.BotStartTime = os.time(); -- Records when the bot was started.
		self.unstick_counter = 0; -- counts unstick tries, resets if waypoint reached
		self.success_waypoints = 0; -- count consecutively successfull reached waypoints 
		self.Cast_to_target = 0; -- count casts to our enemy target
		self.LastAggroTimout = 0;	-- remeber last time we wait in vain for an aggro mob
		
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

	local namePtr = debugAssert(memoryReadUInt(proc, self.Address + charName_offset), memerrmsg);
	self.Name = debugAssert(memoryReadString(proc, namePtr), memerrmsg);
	self.Id = debugAssert(memoryReadUInt(proc, self.Address + pawnId_offset), memerrmsg);
	self.Type = debugAssert(memoryReadInt(proc, self.Address + pawnType_offset), memerrmsg);

	self.Level = debugAssert(memoryReadInt(proc, self.Address + charLevel_offset), memerrmsg);
	self.Level2 = debugAssert(memoryReadInt(proc, self.Address + charLevel2_offset), memerrmsg);

	self.TargetPtr = debugAssert(memoryReadInt(proc, self.Address + charTargetPtr_offset), memerrmsg);

	self.X = debugAssert(memoryReadFloat(proc, self.Address + charX_offset), memerrmsg);
	self.Y = debugAssert(memoryReadFloat(proc, self.Address + charY_offset), memerrmsg);
	self.Z = debugAssert(memoryReadFloat(proc, self.Address + charZ_offset), memerrmsg);

	local attackableFlag = debugAssert(memoryReadInt(proc, self.Address + pawnAttackable_offset), memerrmsg);
	--printf("attackableFlag: %d  (0x%X)\n", attackableFlag, self.Address + pawnAttackable_offset);

	if( self.Type == PT_MONSTER ) then
		self.Attackable = true;
	else
		if( bitAnd(attackableFlag, ATTACKABLE_MASK_PLAYER) ) then
			self.Attackable = true;
		else
			self.Attackable = false;
		end
	end

	self.Class1 = debugAssert(memoryReadInt(proc, self.Address + charClass1_offset), memerrmsg);
	self.Class2 = debugAssert(memoryReadInt(proc, self.Address + charClass2_offset), memerrmsg);

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


	-- Set the correct mana/rage/whatever
	local energyStorage1;
	local energyStorage2;

	energyStorage1 = classEnergyMap[self.Class1];
	energyStorage2 = classEnergyMap[self.Class2];
	if( energyStorage1 == energyStorage2 ) then
		energyStorage2 = "none";
	end;



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