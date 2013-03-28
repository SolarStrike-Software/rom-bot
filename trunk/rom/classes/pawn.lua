PT_NONE = 0;
PT_PLAYER = 1;
PT_MONSTER = 2;
PT_SIGIL = 3;
PT_NPC = 4;
PT_NODE = 4;

RACE_HUMAN = 0;
RACE_ELF = 1;
RACE_DWARF = 2;

CLASS_NONE = -1;
CLASS_WARRIOR = 1;
CLASS_SCOUT = 2;
CLASS_ROGUE = 3;
CLASS_MAGE = 4;
CLASS_PRIEST = 5;
CLASS_KNIGHT = 6;
CLASS_WARDEN = 7;
CLASS_DRUID = 8;
CLASS_WARLOCK = 9;
CLASS_CHAMPION = 10;

NTYPE_WOOD = 1
NTYPE_ORE = 2
NTYPE_HERB = 3

ATTACKABLE_MASK_PLAYER = 0x10000;
ATTACKABLE_MASK_MONSTER = 0x20000;
ATTACKABLE_MASK_CLICKABLE = 0x1000;

AGGRESSIVE_MASK_MONSTER = 0x100000;

-- used in function.lua for openGiftbag()
armorMap = {
	[CLASS_NONE] = "none",
	[CLASS_WARRIOR] = "chain",
	[CLASS_SCOUT] = "leather",
	[CLASS_ROGUE] = "leather",
	[CLASS_MAGE] = "cloth",
	[CLASS_PRIEST] = "cloth",
	[CLASS_KNIGHT] = "chain",
	[CLASS_WARDEN] = "chain",
	[CLASS_DRUID] = "cloth",
	[CLASS_WARLOCK] = "cloth",
	[CLASS_CHAMPION] = "chain",
	};

local classEnergyMap = {
	[CLASS_NONE] = "none",
	[CLASS_WARRIOR] = "rage",
	[CLASS_SCOUT] = "focus",
	[CLASS_ROGUE] = "energy",
	[CLASS_MAGE] = "mana",
	[CLASS_PRIEST] = "mana",
	[CLASS_KNIGHT] = "mana",
	[CLASS_WARDEN] = "mana",
	[CLASS_DRUID] = "mana",
	[CLASS_WARLOCK] = "focus",
	[CLASS_CHAMPION] = "rage",
};

CPawn = class(
	function (self, ptr)
		self.Address = ptr;
		self.Name = "<UNKNOWN>";
		self.Id = -1;
		self.GUID  = 0;
		self.Type = PT_NONE;
		self.Class1 = CLASS_NONE;
		self.Class2 = CLASS_NONE;
		self.Guild = "<UNKNOWN>";
		self.Level = 1;
		self.Level2 = 1;
		self.HP = 1000;
		self.LastDamage = 0;
		self.MaxHP = 1000;
		self.MP = 1000;
		self.MaxMP = 1000;
		self.MP2 = 1000;
		self.MaxMP2 = 1000;
		self.Mana = 0;
		self.MaxMana = 0;
		self.Rage = 0;
		self.MaxRage = 0;
		self.Energy = 0;
		self.MaxEnergy = 0;
		self.Focus = 0;
		self.MaxFocus = 0;
		self.Race = RACE_HUMAN;
		self.X = 0.0;
		self.Y = 0.0;
		self.Z = 0.0;
		self.TargetPtr = 0;
		self.Direction = 0.0;
		self.Attackable = false;
		self.Alive = true;
		self.Mounted = false;
		self.Lootable = false;
		self.Aggressive = false;
		self.Harvesting = false; -- Whether or not we are currently harvesting
		self.Casting = false;
		self.TargetIcon = true
		self.InParty = false
		self.Swimming = false
		self.Speed = 50
		self.IsPet = nil

		self.Buffs = {};

		if( self.Address ~= 0 and self.Address ~= nil ) then self:update(); end
	end
);

function memoryReadRepeat(_type, proc, address, offset)
	local readfunc;
	local ptr = false;
	local val;

	if( type(proc) ~= "userdata" ) then
		error("Invalid proc", 2);
	end

	if( type(address) ~= "number" ) then
		error("Invalid address", 2);
	end

	if( _type == "int" ) then
		readfunc = memoryReadInt;
	elseif( _type == "uint" ) then
		readfunc = memoryReadUInt;
	elseif( _type == "float" ) then
		readfunc = memoryReadFloat;
	elseif( _type == "byte" ) then
		readfunc = memoryReadByte;
	elseif( _type == "string" ) then
		readfunc = memoryReadString;
	elseif( _type == "intptr" ) then
		readfunc = memoryReadIntPtr;
		ptr = true;
	elseif( _type == "uintptr" ) then
		readfunc = memoryReadUIntPtr;
		ptr = true;
	elseif( _type == "byteptr" ) then
		readfunc = memoryReadBytePtr;
		ptr = true;

	else
		return nil;
	end

	for i = 1, 10 do
		if( ptr ) then
			val = readfunc(proc, address, offset);
		else
			val = readfunc(proc, address);
		end

		if( val ~= nil ) then
			return val;
		end
	end

	if( settings.options.DEBUGGING ) then
		printf("Error in memory reading: memoryread%s(proc,0x%X", _type, address)
		if ptr then
			if type(offset) == "number" then
				printf(" ,0x%X)\n",offset)
			elseif type(offset) == "table" then
				printf(" ,{")
				for k,v in pairs(offset) do
					printf("0x%X,",v)
				end
				printf("})\n")
			end
		else
			print(")")
		end
	end
end

function CPawn.new(address)
	local np = CPawn()
	np.Address = address
	return np
end

function CPawn:hasAddress()
	if self.Address == nil or self.Address == 0 then
		return false
	else
		return true
	end
end

function CPawn:update()
	local proc = getProc();
	local memerrmsg = "Failed to read memory";
	local tmp;

	if not self:exists() then -- Updates and checks pawn.Id
		return
	end
	self:updateName()
	self:updateAlive();
	self:updateHP() -- Also updates MaxHP
	self:updateClass()
	self:updateMP() -- Also updates MP2, MaxMP, MaxMP2, Rage, Focus, Energy
	self:updateLastDamage()

	self.Race = memoryReadRepeat("int", proc, self.Address + addresses.pawnRace_offset) or self.Race;


	self:updateGUID()
	self:updateType()

	self:updateHarvesting()
	self:updateCasting()

	self:updateBuffs()

	self:updateLootable()

	self.Level = memoryReadRepeat("int", proc, self.Address + addresses.pawnLevel_offset) or self.Level;
	self.Level2 = memoryReadRepeat("int", proc, self.Address + addresses.pawnLevel2_offset) or self.Level2;

	self:updateTargetPtr()
	self:updateXYZ()
	self:updateDirection() -- Also updates DirectionY

	local attackableFlag = memoryReadRepeat("uint", proc, self.Address + addresses.pawnAttackable_offset)
	if attackableFlag then
		self.Mounted = bitAnd(attackableFlag, 0x10000000)

		--=== Does icon appear when you click pawn ===--
		if bitAnd(attackableFlag,0x10) then
			self.TargetIcon = true
		else
			self.TargetIcon = false
		end

		--=== InParty indicator ===--
		if bitAnd(attackableFlag,0x80000000) then
			self.InParty = true
		else
			self.InParty = false
		end

		if( self.Type == PT_MONSTER ) then
			--printf("%s attackable flag: 0x%X\n", self.Name, attackableFlag);
			if( bitAnd(attackableFlag, ATTACKABLE_MASK_MONSTER) and bitAnd(attackableFlag, ATTACKABLE_MASK_CLICKABLE) ) then
				self.Attackable = true;
			else
				self.Attackable = false;
			end

			if( bitAnd(attackableFlag, AGGRESSIVE_MASK_MONSTER) ) then
				self.Aggressive = true;
			else
				self.Aggressive = false;
			end
		else
			self.Attackable = false;
		end
	end
	self.Speed = memoryReadRepeat("float", proc, self.Address + addresses.pawnSpeed_offset)

	tmp = memoryReadRepeat("byteptr",proc, self.Address + addresses.pawnSwim_offset1, addresses.pawnSwim_offset2)
	self.Swimming = (tmp == 3 or tmp == 4)
	self:updateIsPet()

	if( self.Alive ==nil or self.HP == nil or self.MaxHP == nil or self.MP == nil or self.MaxMP == nil or
		self.MP2 == nil or self.MaxMP2 == nil or self.Name == nil or
		self.Level == nil or self.Level2 == nil or self.TargetPtr == nil or
		self.X == nil or self.Y == nil or self.Z == nil or self.Attackable == nil ) then

		error("Error reading memory in CPawn:update()");
	end

end

function CPawn:updateId()
	if not self:hasAddress() then
		self.Id = 0
		self.Type = 0
		self.Name = "<UNKNOWN>"
		return
	end

	-- Get Id
	local tmp = memoryReadRepeat("uint", getProc(), self.Address + addresses.pawnId_offset) or 0;
	if self.Id == -1 then -- First time. Get it.
		self.Id = tmp
		if self.Id > 999999 then self.Id = 0 end
	elseif self.Id >= 1000 and self.Id <= 1004 then -- player ids can change
		if tmp >= 1000 and tmp <= 1004 then
			self.Id = tmp
		end
	else -- see if it changed
		if tmp ~= self.Id then -- Id changed. Pawn no longer valid
			self.Id = 0
			self.Type = 0
			self.Name = "<UNKNOWN>"
		end
	end
end

function CPawn:exists()
	self:updateId()

	return self.Id ~= 0
end

function CPawn:updateName()
	if not self:hasAddress() then
		self.Name = "<UNKNOWN>"
		return
	end

	showWarnings(false);-- Disable memory warnings for name reading only
	local namePtr = memoryReadRepeat("uint", getProc(), self.Address + addresses.pawnName_offset);
	if( namePtr == nil or namePtr == 0 ) then
		tmp = nil;
	else
		tmp = memoryReadString(getProc(), namePtr); -- Don't use memoryReadRepeat here; this CAN fail!
	end
	showWarnings(true); -- Re-enable warnings after reading
	-- UTF8 -> ASCII translation not for player names
	-- because that would need the whole table and there we normaly
	-- don't need it, we don't print player names in the MM window or so
	if( tmp == nil ) then
		self.Name = "<UNKNOWN>";
	else
		-- time for only convert 8 characters is 0 ms
		-- time for convert the whole UTF8_ASCII.xml table is about 6-7 ms

		if( bot.ClientLanguage == "RU" ) then
			self.Name = utf82oem_russian(tmp);
		else
			self.Name = utf8ToAscii_umlauts(tmp);	-- only convert umlauts
		end
	end
end

function CPawn:updateGUID()
	if not self:hasAddress() then
		self.GUID = 0
		return
	end

	self.GUID = memoryReadInt(getProc(), self.Address + addresses.pawnGUID_offset) or self.GUID;
end

function CPawn:updateType()
	if not self:hasAddress() then
		self.Type = PT_NONE
		return
	end

	self.Type = memoryReadRepeat("int", getProc(), self.Address + addresses.pawnType_offset) or self.Type;
end

function CPawn:updateAlive()
	if not self:hasAddress() then
		self.Alive = false
		return
	end

	local tmp = memoryReadRepeat("byte", getProc(), self.Address + addresses.charAlive_offset);
	self.Alive = not(tmp == 9 or tmp == 8);
end

function CPawn:updateHP()
	if not self:hasAddress() then
		self.HP = 0
		return
	end

	self.HP = memoryReadRepeat("int", getProc(), self.Address + addresses.pawnHP_offset) or self.HP;

	self.MaxHP = memoryReadRepeat("int", getProc(), self.Address + addresses.pawnMaxHP_offset) or self.MaxHP;
end

function CPawn:updateLastDamage()
	if not self:hasAddress() then
		self.LastDamage = 0
		return
	end

	local tmpLastDamage = memoryReadRepeat("uint", getProc(), self.Address + addresses.pawnLastDamage_offset)
	if tmpLastDamage then
		self.LastDamage = tmpLastDamage/1000
	end
end

function CPawn:updateClass()
	if not self:hasAddress() then
		self.Class1 = CLASS_NONE;
		self.Class2 = CLASS_NONE;
		return
	end

	self.Class1 = memoryReadRepeat("int", getProc(), self.Address + addresses.pawnClass1_offset) or self.Class1;
	self.Class2 = memoryReadRepeat("int", getProc(), self.Address + addresses.pawnClass2_offset) or self.Class2;
end

function CPawn:updateMP()
	if not self:hasAddress() then
		self.MP = 0;
		self.MP2 = 0;
		return
	end

	self.MP = memoryReadRepeat("int", getProc(), self.Address + addresses.pawnMP_offset) or self.MP;
	self.MaxMP = memoryReadRepeat("int", getProc(), self.Address + addresses.pawnMaxMP_offset) or self.MaxMP;
	self.MP2 = memoryReadRepeat("int", getProc(), self.Address + addresses.pawnMP2_offset) or self.MP2;
	self.MaxMP2 = memoryReadRepeat("int", getProc(), self.Address + addresses.pawnMaxMP2_offset) or self.MaxMP2;
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

	if self.Class1 == CLASS_NONE then
		self:updateClass()
	end

	-- Set the correct mana/rage/whatever
	local energyStorage1 = classEnergyMap[self.Class1];
	local energyStorage2 = classEnergyMap[self.Class2];
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
	elseif( energyStorage1 == "focus" ) then
		self.Focus = self.MP;
		self.MaxFocus = self.MaxMP;
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
		elseif( energyStorage2 == "focus" ) then
		self.Focus = self.MP2;
		self.MaxFocus = self.MaxMP2;
	end
end

function CPawn:updateBuffs()
	if not self:hasAddress() then
		self.buffs = {};
		return
	end

	local proc = getProc()
	local BuffSize = 0x54
	local buffStart = memoryReadRepeat("uint", proc, self.Address + addresses.pawnBuffsStart_offset);
	local buffEnd = memoryReadRepeat("uint", proc, self.Address + addresses.pawnBuffsEnd_offset);

	self.Buffs = {} -- clear old values
	if buffStart == nil or buffEnd == nil or buffStart == 0 or buffEnd == 0 then return end
	if (buffEnd - buffStart)/ BuffSize > 50 then -- Something wrong, too many buffs
		return
	end

	for i = buffStart, buffEnd - 4, BuffSize do
		local tmp = {}
		--yrest(1)
		tmp.Id = memoryReadRepeat("int", proc, i + addresses.pawnBuffId_offset);
		local name = GetIdName(tmp.Id)

		if name ~= nil and name ~= "" then
			tmp.Name, tmp.Count = parseBuffName(name)
			tmp.TimeLeft = memoryReadRepeat("float", proc, i + addresses.pawnBuffTimeLeft_offset);
			tmp.Level = memoryReadRepeat("int", proc, i + addresses.pawnBuffLevel_offset);

			table.insert(self.Buffs,tmp)
		end
	end
	--[[target = target or "player"; -- By default, assume player.
	self.Buffs = {}; -- Flush old buffs/debuffs
	self.Debuffs = {};

	local buffs = {RoMScript("} for i=1,16 do w,x,y,z=UnitBuff('" .. target ..
	"', i) table.insert(a,w) table.insert(a,y) end z={")};

	local debuffs = {RoMScript("} for i=1,16 do w,x,y,z=UnitDebuff('" .. target
	.. "', i) table.insert(a,w) table.insert(a,y) end z={")};

	if( buffs ) then
		for i = 1,#buffs,2 do
			local buffname = buffs[i];
			local count = buffs[i+1] or 0;
			if( count == 0 ) then count = 1; end;

			self.Buffs[buffname] = count;
		end
	end

	if( debuffs ) then
		for i = 1,#debuffs,2 do
			local buffname = debuffs[i] or "<UNKNOWN>";
			local count = debuffs[i+1] or 0;
			if( count == 0 ) then count = 1; end;

			self.Debuffs[buffname] = count;
		end
	end

	self.LastBuffUpdateTime = getTime();]]
end

function CPawn:updateLootable()
	if not self:hasAddress() then
		self.Lootable = false;
		return
	end

	local tmp = memoryReadRepeat("int", getProc(), self.Address + addresses.pawnLootable_offset);
	if( tmp ) then
		self.Lootable = bitAnd(tmp, 0x4);
	else
		self.Lootable = false;
	end
end

function CPawn:updateHarvesting()
	if not self:hasAddress() then
		self.Harvesting = false;
		return
	end

	self.Harvesting = memoryReadRepeat("int", getProc(), self.Address + addresses.pawnHarvesting_offset) ~= 0;
end

function CPawn:updateCasting()
	if not self:hasAddress() then
		self.Casting = false;
		return
	end

	self.Casting = (memoryReadRepeat("int", getProc(), self.Address + addresses.pawnCasting_offset) ~= 0);
end

function CPawn:updateLevel()
	if not self:hasAddress() then
		self.Level = 1;
		return
	end

	self.Level = memoryReadRepeat("int", getProc(), self.Address + addresses.pawnLevel_offset) or self.Level;
end

function CPawn:updateTargetPtr()
	if not self:hasAddress() then
		self.TargetPtr = 0;
		return
	end


	local tmpTargetPtr = memoryReadRepeat("uint", getProc(), self.Address + addresses.pawnTargetPtr_offset) or 0

	if tmpTargetPtr ~= 0 then
		self.TargetPtr = tmpTargetPtr
		return
	end

	if self.TargetPtr ~= 0 then
		-- Check if still valid
		local addressId = memoryReadRepeat("uint", getProc(), self.TargetPtr + addresses.pawnId_offset) or 0;

		if addressId == 0 or addressId > 999999 then -- The target no longer exists
			self.TargetPtr = 0
		end
	end

	return 0
end

function CPawn:updateXYZ()
	if not self:hasAddress() then
		self.X = 0;
		self.Y = 0;
		self.Z = 0;
		return
	end

	self.X = memoryReadRepeat("float", getProc(), self.Address + addresses.pawnX_offset) or self.X;
	self.Y = memoryReadRepeat("float", getProc(), self.Address + addresses.pawnY_offset) or self.Y;
	self.Z = memoryReadRepeat("float", getProc(), self.Address + addresses.pawnZ_offset) or self.Z;
end

function CPawn:updateDirection()
	if not self:hasAddress() then
		return
	end

	local Vec1 = memoryReadRepeat("float", getProc(), self.Address + addresses.pawnDirXUVec_offset);
	local Vec2 = memoryReadRepeat("float", getProc(), self.Address + addresses.pawnDirZUVec_offset);
	local Vec3 = memoryReadRepeat("float", getProc(), self.Address + addresses.pawnDirYUVec_offset);

	if( Vec1 == nil ) then Vec1 = 0.0; end;
	if( Vec2 == nil ) then Vec2 = 0.0; end;
	if( Vec3 == nil ) then Vec3 = 0.0; end;

	self.Direction = math.atan2(Vec2, Vec1);
	self.DirectionY = math.atan2(Vec3, (Vec1^2 + Vec2^2)^.5 );
end

function CPawn:updateMounted()
	if not self:hasAddress() then
		self.Mounted = false;
		return
	end

	local attackableFlag = memoryReadRepeat("int", getProc(), self.Address + addresses.pawnAttackable_offset)
	if attackableFlag then
		self.Mounted = bitAnd(attackableFlag, 0x10000000)
	end
end

function CPawn:updateInParty()
	if not self:hasAddress() then
		self.InParty = false;
		return
	end

	local attackableFlag = memoryReadRepeat("int", getProc(), self.Address + addresses.pawnAttackable_offset)
	--=== InParty indicator ===--
	if attackableFlag and bitAnd(attackableFlag,0x80000000) then
		self.InParty = true
	else
		self.InParty = false
	end
end

function CPawn:updateAttackable()
	if not self:exists() then
		return
	end

	self:updateType()
	if( self.Type == PT_MONSTER ) then
		local attackableFlag = memoryReadRepeat("int", getProc(), self.Address + addresses.pawnAttackable_offset)
		if attackableFlag then
			if( bitAnd(attackableFlag, ATTACKABLE_MASK_MONSTER) and bitAnd(attackableFlag, ATTACKABLE_MASK_CLICKABLE) ) then
				self.Attackable = true;
			else
				self.Attackable = false;
			end

			if( bitAnd(attackableFlag, AGGRESSIVE_MASK_MONSTER) ) then
				self.Aggressive = true;
			else
				self.Aggressive = false;
			end
		end
	else
		self.Attackable = false;
	end
end

function CPawn:updateSwimming()
	if not self:hasAddress() then
		return
	end

	local tmp = memoryReadRepeat("byteptr",getProc(), self.Address + addresses.pawnSwim_offset1, addresses.pawnSwim_offset2)
	self.Swimming = (tmp == 3 or tmp == 4)
end

function CPawn:updateIsPet()
	if not self:hasAddress() then
		self.IsPet = nil
		return
	end

	if self.IsPet == nil then -- not updated yet
		self.IsPet = memoryReadRepeat("uint",getProc(), self.Address + addresses.pawnIsPet_offset)
		if self.IsPet == 0 then self.IsPet = false end
	end
end

function CPawn:haveTarget()
	-- Update TargetPtr
	self:updateTargetPtr()

	if( self.TargetPtr == 0 ) then
		return false;
	end;

	local tmp = CPawn.new(self.TargetPtr)

	if not tmp:isAlive() then
		return false
	end

	return true
end

function CPawn:getTarget()
	self:updateTargetPtr();
	if( self.TargetPtr ) then
		return CPawn(self.TargetPtr);
	else
		return nil;
	end
end

function CPawn:isAlive()
	-- Check if still valid target
	if not self:exists() then
		return false
	end

	-- Dead
	self:updateHP()
	if( self.HP < 1 ) then
		return false;
	end

	-- Also dead (and has loot)
	self:updateLootable()
	if( self.Lootable ) then
		return false;
	end

	self:updateAlive()
	if( not self.Alive ) then
		return false;
	end

	return true
end

function CPawn:distanceToTarget()
	self:updateTargetPtr()
	if( self.TargetPtr == 0 ) then return 0; end;

	local target = CPawn.new(self.TargetPtr);
	target:updateXYZ()
	self:updateXYZ()
	local tx,ty,tz = target.X, target.Y, target.Z;
	local px,py,pz = self.X, self.Y, self.Z;

	return math.sqrt( (tx-px)*(tx-px) + (ty-py)*(ty-py) + (tz-pz)*(tz-pz) );
end

function CPawn:hasBuff(buffname, count)
	local buff = self:getBuff(buffname, count)

	if buff then
		return true, buff.Count -- count returned for backward compatibility
	else
		return false, 0
	end
end

function CPawn:hasDebuff(debuff, count)
	return self:hasBuff(debuff, count)
end

function CPawn:getBuff(buffnamesorids, count)
	self:updateBuffs()

	-- for each buff the pawn has
	for i, buff in pairs(self.Buffs) do
		-- compare against each 'buffname'
		for buffname in string.gmatch(buffnamesorids,"[^,]+") do
			if type(tonumber(buffname)) == "number" then
				-- Get name from id
				buffname = GetIdName(tonumber(buffname))
				-- Take of end numbers
				buffname = parseBuffName(buffname)
			end
			if buffname == buff.Name and ( count == nil or buff.Count >= count ) then
				return buff
			end
		end
	end

	return false
end

function parseBuffName(buffname)
	if buffname == nil then return end

	local name, count

	-- First try and find '(3)' type count in name
	local tmpCount = string.match(buffname,"%((%d+)%)$")
	if tmpCount then
		count = tonumber(tmpCount)
		name = string.match(buffname,"(.*)%s%(%d+%)$")
		return name, count
	end

	-- Next try and find roman numeral number
	tmpCount = string.match(buffname,"%s([IVX]+)$")
	if tmpCount then
		-- Convert roman number to number
		if tmpCount == "I" then count = 1
		elseif tmpCount == "II" then count = 2
		elseif tmpCount == "III" then count = 3
		elseif tmpCount == "IV" then count = 4
		elseif tmpCount == "V" then count = 5
		elseif tmpCount == "VI" then count = 6
		elseif tmpCount == "VII" then count = 7
		elseif tmpCount == "VIII" then count = 8
		elseif tmpCount == "IX" then count = 9
		elseif tmpCount == "X" then count = 10
		end
		name = string.match(buffname,"(.*)%s[IVX]+$")
		return name, count
	end

	-- Buff not stackable
	return buffname, 1
end

function CPawn:GetPartyIcon()
	self:updateGUID()
	local listStart = memoryReadRepeat("uintptr", getProc(), addresses.partyIconList_base, addresses.partyIconList_offset)
	for i = 0, 7 do
		local guid = memoryReadInt(getProc(), listStart + i * 12)
		if guid == self.GUID then
			return i + 1
		end
	end
end

function CPawn:countMobs(inrange, onlyaggro, idorname)
	self:updateXYZ()
	local count = 0

	local objectList = CObjectList();
	objectList:update();
	for i = 0,objectList:size() do
		local obj = objectList:getObject(i);
		if obj ~= nil and obj.Type == PT_MONSTER and
		  (inrange == nil or inrange >= distance(self.X,self.Z,self.Y,obj.X,obj.Z,obj.Y) ) and
		  (idorname == nil or idorname == obj.Name or idorname == obj.Id) then
			local pawn = CPawn.new(obj.Address)
			pawn:updateAlive()
			pawn:updateHP()
			pawn:updateAttackable()
			pawn:updateLevel()
			if pawn.Alive and pawn.HP >=1 and pawn.Attackable and pawn.Level > 1 then
				if onlyaggro == true then
					pawn:updateTargetPtr()
					if pawn.TargetPtr == player.Address then
						count = count + 1
					end
				else
					count = count + 1
				end
			end
		end
	end

	return count
end

function CPawn:findBestClickPoint(aoerange, skillrange, onlyaggro)
	-- Finds best place to click to get most mobs including this pawn.
	self:updateXYZ()

	player:updateXYZ()
	local MobList = {}
	local EPList = {}

	local function CountMobsInRangeOfCoords(x,z)
		local c = 0
		local list = {}
		for k,mob in ipairs(MobList) do
			if distance(x,z,mob.X,mob.Z) <= aoerange then
				table.insert(list,k)
				c=c+1
			end
		end
		return c, list
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
	if settings.profile.options.FORCE_BETTER_AOE_TARGETING == false then
		return countmobs, self.X, self.Z
	end

	-- First get list of mobs within (2 x aoerange) of this pawn and (skillrange + aoerange) from player.
	local objectList = CObjectList();
	objectList:update();
	for i = 0,objectList:size() do
		local obj = objectList:getObject(i);
		if obj ~= nil and obj.Type == PT_MONSTER and (settings.profile.options.FORCE_BETTER_AOE_TARGETING == true or 0.5 > math.abs(obj.Y - self.Y)) and -- only count mobs on flat floor, results would be unpredictable on hilly surfaces when clicking.
		  aoerange*2 >= distance(self.X,self.Z,self.Y,obj.X,obj.Z,obj.Y) and (skillrange + aoerange >= distance(player.X, player.Z, obj.X, obj.Z)) then
			local pawn = CPawn.new(obj.Address);
			pawn:updateAlive()
			pawn:updateHP()
			pawn:updateAttackable()
			pawn:updateLevel()
			pawn:updateXYZ() -- For the rest of the function
			if pawn.Alive and pawn.HP >=1 and pawn.Attackable and pawn.Level > 1 then
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
			if aoerange >= distance(ep1, self) then -- EP doesn't miss primary target(self)
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
			-- Check ep2 and add
			if aoerange > distance(ep2,self) then -- EP doesn't miss primary target(self)
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
	if countmobs > bestscore then
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

-- returns true if this CPawn is registered as a friend
function CPawn:isFriend( aggroonly)
	-- Is self still valid
	if not self:exists() then
		return false
	end

	-- Pets are friends
	if( player.PetPtr ~= 0 and self.Address == player.PetPtr ) then
		return true;
	end

	-- Following options need 'settings'
	if( not settings ) then
		return false;
	end;

	-- Are they in party
	self:updateInParty()
	if settings.profile.options.PARTY == true and self.InParty then
		return true
	end

	-- If passed above tests and not friend and only interested in pawn that cause aggro, then return false
	if aggroonly == true then
		return false
	end

	-- Are they on the friends list
	self:updateName()
	for i,v in pairs(settings.profile.friends) do
		if( string.find( string.lower(self.Name), string.lower(v), 1, true) ) or tonumber(v) == self.Id then
			return true;
		end
	end

	return false;
end

-- returns true if this CPawn target is registered as a friend
function CPawn:targetIsFriend(aggroonly)
	-- Is self still valid
	if not self:exists() then
		return false
	end

	self:updateTargetPtr()
	if self.TargetPtr == 0 then
		return false
	end

	local target = CPawn.new(self.TargetPtr)

	return target:isFriend(aggroonly)
end

function CPawn:getRemainingCastTime()
	local casttime = memoryReadFloat( getProc(), self.Address + addresses.pawnCasting_offset)
	local castsofar = memoryReadFloat( getProc(), self.Address + addresses.pawnCastingElapsed_offset)

	if casttime and castsofar then
		return casttime - castsofar, casttime
	else
		return 0,0
	end
end

function CPawn:isOnMobIgnoreList()
	for k, v in pairs(player.MobIgnoreList) do
		if v.Address == self.Address then
			-- Check if we can clear it
			if distance(player,player.LastPlaceMobIgnored) > 50 and
			   os.clock()-v.Time > 10 then
				table.remove(player.MobIgnoreList,k)
				return false
			else
				return true
			end
		end
	end

	return false
end
