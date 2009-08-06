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
		self.Returning = false;		-- Whether following the return path, or regular waypoints
		self.BotStartTime = os.time(); -- Records when the bot was started.
		self.Unstick_counter = 0;	-- counts unstick tries, resets if waypoint reached
		self.Success_waypoints = 0; -- count consecutively successfull reached waypoints 
		self.Cast_to_target = 0;	-- count casts to our enemy target
		self.LastAggroTimout = 0;	-- remeber last time we wait in vain for an aggro mob
		self.Sleeping = false;		-- sleep mode with fight back if attacked
		self.Sleeping_time = 0;		-- counts the sleeping time
		self.Fights = 0;			-- counts the fights
		self.Death_counter = 0;		-- counts deaths / automatic reanimation
		self.Current_waypoint_type = WPT_NORMAL;	-- remember current waypoint type global
		self.Last_ignore_target_ptr = 0;		-- last target to ignore
		self.Last_ignore_target_time = 0;		-- last target to ignore		

		
		if( self.Address ~= 0 and self.Address ~= nil ) then self:update(); end
	end
);

function CPawn:update()
	local proc = getProc();
	local memerrmsg = "Failed to read memory";
	local tmp;

	local function UTF8_to_ASCII(str)
--		str = string.gsub(str, string.char(195, 164), "\132");	-- replace for ä
--		str = string.gsub(str, string.char(195, 132), "\142");	-- replace for Ä
--		str = string.gsub(str, string.char(195, 182), "\148");	-- replace for ö
--		str = string.gsub(str, string.char(195, 150), "\153");	-- replace for Ö
--		str = string.gsub(str, string.char(195, 188), "\129");	-- replace for ü
--  	str = string.gsub(str, string.char(195, 156), "\154");	-- replace for Ü
--		str = string.gsub(str, string.char(195, 159), "\225");	-- replace for ß
		if(str == nil) then return ""; end;
		str = string.gsub(str, string.char(197,145), "\018");	-- replace for o
		str = string.gsub(str, string.char(197,177), "\019");	-- replace for u 
		str = string.gsub(str, string.char(197,179), "\022");	-- replace for u 
		str = string.gsub(str, string.char(196,159), "\023");	-- replace for g 
		str = string.gsub(str, string.char(196,155), "\127");	-- replace for e 
		str = string.gsub(str, string.char(195,135), "\128");	-- replace for Ç 
		str = string.gsub(str, string.char(195,188), "\129");	-- replace for ü 
		str = string.gsub(str, string.char(195,169), "\130");	-- replace for é 
		str = string.gsub(str, string.char(195,162), "\131");	-- replace for â 
		str = string.gsub(str, string.char(195,164), "\132");	-- replace for ä 
		str = string.gsub(str, string.char(195,160), "\133");	-- replace for à 
		str = string.gsub(str, string.char(195,165), "\134");	-- replace for å 
		str = string.gsub(str, string.char(195,167), "\135");	-- replace for ç 
		str = string.gsub(str, string.char(195,170), "\136");	-- replace for ê 
		str = string.gsub(str, string.char(195,171), "\137");	-- replace for ë 
		str = string.gsub(str, string.char(195,168), "\138");	-- replace for è 
		str = string.gsub(str, string.char(195,175), "\139");	-- replace for ï 
		str = string.gsub(str, string.char(195,174), "\140");	-- replace for î 
		str = string.gsub(str, string.char(195,172), "\141");	-- replace for ì 
		str = string.gsub(str, string.char(195,132), "\142");	-- replace for Ä 
		str = string.gsub(str, string.char(195,133), "\143");	-- replace for Å 
		str = string.gsub(str, string.char(195,137), "\144");	-- replace for É 
		str = string.gsub(str, string.char(195,166), "\145");	-- replace for æ 
		str = string.gsub(str, string.char(195,134), "\146");	-- replace for Æ 
		str = string.gsub(str, string.char(195,180), "\147");	-- replace for ô 
		str = string.gsub(str, string.char(195,182), "\148");	-- replace for ö 
		str = string.gsub(str, string.char(195,178), "\149");	-- replace for ò 
		str = string.gsub(str, string.char(195,187), "\150");	-- replace for û 
		str = string.gsub(str, string.char(195,185), "\151");	-- replace for ù 
		str = string.gsub(str, string.char(195,191), "\152");	-- replace for ÿ 
		str = string.gsub(str, string.char(195,150), "\153");	-- replace for Ö 
		str = string.gsub(str, string.char(195,156), "\154");	-- replace for Ü 
		str = string.gsub(str, string.char(197,165), "\155");	-- replace for t 
		str = string.gsub(str, string.char(194,163), "\156");	-- replace for £ 
		str = string.gsub(str, string.char(197,159), "\157");	-- replace for s 
		str = string.gsub(str, string.char(197,175), "\158");	-- replace for u 
		str = string.gsub(str, string.char(197,174), "\159");	-- replace for U 
		str = string.gsub(str, string.char(195,161), "\160");	-- replace for á 
		str = string.gsub(str, string.char(195,173), "\161");	-- replace for í 
		str = string.gsub(str, string.char(195,179), "\162");	-- replace for ó 
		str = string.gsub(str, string.char(195,186), "\163");	-- replace for ú 
		str = string.gsub(str, string.char(195,177), "\164");	-- replace for ñ 
		str = string.gsub(str, string.char(195,145), "\165");	-- replace for Ñ 
		str = string.gsub(str, string.char(196,140), "\166");	-- replace for C 
		str = string.gsub(str, string.char(196,141), "\167");	-- replace for c 
		str = string.gsub(str, string.char(197,153), "\168");	-- replace for r 
		str = string.gsub(str, string.char(197,152), "\169");	-- replace for R 
		str = string.gsub(str, string.char(194,172), "\170");	-- replace for ¬ 
		str = string.gsub(str, string.char(197,160), "\171");	-- replace for Š 
		str = string.gsub(str, string.char(197,161), "\172");	-- replace for š 
		str = string.gsub(str, string.char(195,189), "\173");	-- replace for ý 
		str = string.gsub(str, string.char(197,189), "\174");	-- replace for Ž 
		str = string.gsub(str, string.char(197,190), "\175");	-- replace for ž 
		str = string.gsub(str, string.char(196,177), "\176");	-- replace for i 
		str = string.gsub(str, string.char(195,158), "\177");	-- replace for Þ 
		str = string.gsub(str, string.char(195,190), "\178");	-- replace for þ 
		str = string.gsub(str, string.char(194,169), "\214");	-- replace for © 
		str = string.gsub(str, string.char(195,152), "\215");	-- replace for Ø 
		str = string.gsub(str, string.char(194,164), "\216");	-- replace for ¤ 
		str = string.gsub(str, string.char(206,177), "\224");	-- replace for a 
		str = string.gsub(str, string.char(195,159), "\225");	-- replace for ß 
		str = string.gsub(str, string.char(206,147), "\226");	-- replace for G 
		str = string.gsub(str, string.char(207,128), "\227");	-- replace for p 
		str = string.gsub(str, string.char(196,131), "\228");	-- replace for a 
		str = string.gsub(str, string.char(207,131), "\229");	-- replace for s 
		str = string.gsub(str, string.char(194,181), "\230");	-- replace for µ 
		str = string.gsub(str, string.char(206,179), "\231");	-- replace for ? 
		str = string.gsub(str, string.char(204,131), "\232");	-- replace for ~ 
		str = string.gsub(str, string.char(196,176), "\233");	-- replace for I 
		str = string.gsub(str, string.char(197,163), "\234");	-- replace for t 
		str = string.gsub(str, string.char(206,180), "\235");	-- replace for d 
		str = string.gsub(str, string.char(195,184), "\237");	-- replace for ø 
		str = string.gsub(str, string.char(196,133), "\238");	-- replace for a 
		str = string.gsub(str, string.char(196,153), "\239");	-- replace for e 
		str = string.gsub(str, string.char(196,134), "\240");	-- replace for C 
		str = string.gsub(str, string.char(196,135), "\241");	-- replace for c 
		str = string.gsub(str, string.char(197,129), "\242");	-- replace for L 
		str = string.gsub(str, string.char(197,130), "\243");	-- replace for l 
		str = string.gsub(str, string.char(197,131), "\244");	-- replace for N 
		str = string.gsub(str, string.char(197,132), "\245");	-- replace for n 
		str = string.gsub(str, string.char(195,147), "\246");	-- replace for Ó 
		str = string.gsub(str, string.char(197,154), "\247");	-- replace for S 
		str = string.gsub(str, string.char(194,176), "\248");	-- replace for ° 
		str = string.gsub(str, string.char(197,155), "\249");	-- replace for s 
		str = string.gsub(str, string.char(194,183), "\250");	-- replace for · 
		str = string.gsub(str, string.char(197,185), "\251");	-- replace for Z 
		str = string.gsub(str, string.char(197,186), "\252");	-- replace for z 
		str = string.gsub(str, string.char(197,187), "\253");	-- replace for Z 
		str = string.gsub(str, string.char(197,188), "\254");	-- replace for z 
		return str;
	end

	tmp = debugAssert(memoryReadByte(proc, self.Address + charAlive_offset), memerrmsg);
	self.Alive = not(tmp == 9 or tmp == 8);
	self.HP = debugAssert(memoryReadInt(proc, self.Address + charHP_offset), memerrmsg);

	self.MaxHP = debugAssert(memoryReadInt(proc, self.Address + charMaxHP_offset), memerrmsg);
	self.MP = debugAssert(memoryReadInt(proc, self.Address + charMP_offset), memerrmsg);
	self.MaxMP = debugAssert(memoryReadInt(proc, self.Address + charMaxMP_offset), memerrmsg);
	self.MP2 = debugAssert(memoryReadInt(proc, self.Address + charMP2_offset), memerrmsg);
	self.MaxMP2 = debugAssert(memoryReadInt(proc, self.Address + charMaxMP2_offset), memerrmsg);

	local namePtr = debugAssert(memoryReadUInt(proc, self.Address + charName_offset), memerrmsg);
--	self.Name = debugAssert(memoryReadString(proc, namePtr), memerrmsg);

	-- Disable memory warnings for name reading only
	showWarnings(false);
	tmp = debugAssert(memoryReadString(proc, namePtr));
	showWarnings(true); -- Re-enable warnings after reading

	if( tmp == nil ) then
		self.Name = "<UNKNOWN>";
	else
		self.Name = UTF8_to_ASCII(tmp);
	end

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