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
CLASS_GM = 0;
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
ATTACKABLE_MASK_CLICKABLE = 0x10;
ATTACKABLE_MASK_ATTACKABLE = 0x100000;
ATTACKABLE_MASK_ATTACKABLE2 = 0x80000;

AGGRESSIVE_MASK_MONSTER = 0x10000;

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
		self.LastHP = 0;
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
	self:updateLastHP()

	self.Race = memoryReadRepeat("int", proc, self.Address + addresses.game_root.pawn.race) or self.Race;


	self:updateGUID()
	self:updateType()

	self:updateHarvesting()
	self:updateCasting()

	self:updateBuffs()

	self:updateLootable()

	self.Level = memoryReadInt(proc, self.Address + addresses.game_root.pawn.level) or self.Level;
	self.Level2 = memoryReadInt(proc, self.Address + addresses.game_root.pawn.level2) or self.Level;

	self:updateTargetPtr()
	self:updateXYZ()
	self:updateDirection() -- Also updates DirectionY

	local attackableFlag = memoryReadRepeat("uint", proc, self.Address + addresses.game_root.pawn.attackable_flags);
	if attackableFlag then
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

		self:updateAttackable();
	end

	self:updateMounted();
	self:updateSpeed()

	tmp = memoryReadRepeat("byteptr",proc, self.Address + addresses.game_root.pawn.swimming.base, addresses.game_root.pawn.swimming.swimming)
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
	local tmp = memoryReadRepeat("uint", getProc(), self.Address + addresses.game_root.pawn.id) or 0;
	if self.Id == -1 then -- First time. Get it.
		self.Id = tmp
		if self.Id > 999999 then self.Id = 0 end
	elseif self.Id >= PLAYERID_MIN and self.Id <= PLAYERID_MAX then -- player ids can change
		if tmp >= PLAYERID_MIN and tmp <= PLAYERID_MAX then
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
	local namePtr = memoryReadRepeat("uint", getProc(), self.Address + addresses.game_root.pawn.name_ptr);
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

	self.GUID = memoryReadUInt(getProc(), self.Address + addresses.game_root.pawn.guid) or self.GUID;
end

function CPawn:updateType()
	if not self:hasAddress() then
		self.Type = PT_NONE
		return
	end

	self.Type = memoryReadInt(getProc(), self.Address + addresses.game_root.pawn.type) or self.Type;
end

function CPawn:updateAlive()
	if not self:hasAddress() then
		self.Alive = false
		return
	end

	-- Check Alive flag
	local alive = memoryReadInt(getProc(), self.Address + addresses.game_root.pawn.alive_flag);
	self.Alive = (alive ~= 0);

	-- If 'alive' then also check if fading (only for mobs).
	if self.Alive then
		self:updateType()
		if self.Type == PT_MONSTER then
			self.Alive = memoryReadRepeat("float", getProc(), self.Address + addresses.game_root.pawn.fading) == 0;
		end
	end
end

function CPawn:updateHP()
	if not self:hasAddress() then
		self.HP = 0
		return
	end

	local hpTmp = memoryReadInt(getProc(), self.Address + addresses.game_root.pawn.hp);
	local maxHpTmp = memoryReadInt(getProc(), self.Address + addresses.game_root.pawn.max_hp);

	if( hpTmp ~= nil ) then
		self.HP = math.floor(QWord:fromQWord(hpTmp) + 0.5);
	end
	if( maxHpTmp ~= nil ) then
		self.MaxHP = math.floor(QWord:fromQWord(maxHpTmp) + 0.5);
	end
end

function CPawn:updateLastHP()
	if not self:hasAddress() then
		self.LastHP = 0
		return
	end

	local tmpLastHP = memoryReadRepeat("uint", getProc(), self.Address + addresses.game_root.pawn.previous_hp)
	if tmpLastHP and tmpLastHp ~= 0 then
		tmpLastHP = QWord:fromQWord(tmpLastHP); -- Convert from ROM's representation
		self.LastHP = tmpLastHP
		if player and self.LastHP ~= player.PawnLastHP then
			player.PawnLastHP = self.LastHP
			player.LastHitTime = getGameTime()
		end
	end
end

function CPawn:updateClass()
	if not self:hasAddress() then
		self.Class1 = CLASS_NONE;
		self.Class2 = CLASS_NONE;
		return
	end

	self.Class1 = memoryReadRepeat("int", getProc(), self.Address + addresses.game_root.pawn.class1) or self.Class1;
	self.Class2 = memoryReadRepeat("int", getProc(), self.Address + addresses.game_root.pawn.class2) or self.Class2;
end

function CPawn:updateMP()
	if not self:hasAddress() then
		self.MP = 0;
		self.MP2 = 0;
		return
	end

	self.MP = memoryReadRepeat("int", getProc(), self.Address + addresses.game_root.pawn.energy1) or self.MP;
	self.MaxMP = memoryReadRepeat("int", getProc(), self.Address + addresses.game_root.pawn.max_energy1) or self.MaxMP;
	self.MP2 = memoryReadRepeat("int", getProc(), self.Address + addresses.game_root.pawn.energy2) or self.MP2;
	self.MaxMP2 = memoryReadRepeat("int", getProc(), self.Address + addresses.game_root.pawn.max_energy2) or self.MaxMP2;
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
	local BuffSize = addresses.game_root.pawn.buffs.buff.size;
	local buffStart = memoryReadRepeat("uint", proc, self.Address + addresses.game_root.pawn.buffs.array_start);
	local buffEnd = memoryReadRepeat("uint", proc, self.Address + addresses.game_root.pawn.buffs.array_end);

	self.Buffs = {} -- clear old values
	if buffStart == nil or buffEnd == nil or buffStart == 0 or buffEnd == 0 then return end
	if (buffEnd - buffStart)/ BuffSize > 50 then -- Something wrong, too many buffs
		return
	end

	local buffIndex = 1;
	for i = buffStart, buffEnd - 4, BuffSize do
		local tmp = {}
		tmp.Id = memoryReadRepeat("int", proc, i + addresses.game_root.pawn.buffs.buff.id);
		local name = GetIdName(tmp.Id)

		if name ~= nil then
			tmp.Name, tmp.Count = parseBuffName(name)
			if( type(tmp.Count) ~= "number" ) then
				tmp.Count = 1
			end
			tmp.TimeLeft = memoryReadRepeat("float", proc, i + addresses.game_root.pawn.buffs.buff.time_remaining);
			tmp.Level = memoryReadRepeat("int", proc, i + addresses.game_root.pawn.buffs.buff.level);

			table.insert(self.Buffs, buffIndex, tmp);
			buffIndex = buffIndex + 1;
		end
	end

end

function CPawn:updateLootable()
	if not self:hasAddress() then
		self.Lootable = false;
		return
	end

	local tmp = memoryReadRepeat("int", getProc(), self.Address + addresses.game_root.pawn.lootable_flags);
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

	self.Harvesting = memoryReadRepeat("int", getProc(), self.Address + addresses.game_root.pawn.harvesting) ~= 0;
end

function CPawn:updateCasting()
	if not self:hasAddress() then
		self.Casting = false;
		return
	end

    self.Casting = (memoryReadRepeat("float", getProc(), self.Address + addresses.game_root.pawn.cast_full_time) > 0);
end

function CPawn:updateLevel()
	if not self:hasAddress() then
		self.Level = 1;
		return
	end

	self.Level = memoryReadRepeat("int", getProc(), self.Address + addresses.game_root.pawn.level) or self.Level;
	self.Level2 = memoryReadRepeat("int", getProc(), self.Address + addresses.game_root.pawn.level2) or self.Level;

end

function CPawn:updateTargetPtr()
	if not self:hasAddress() then
		self.TargetPtr = 0;
		return
	end


	local tmpTargetPtr = memoryReadRepeat("uint", getProc(), self.Address + addresses.game_root.pawn.target) or 0

	if tmpTargetPtr ~= 0 then
		self.TargetPtr = tmpTargetPtr
		return
	end

	if self.TargetPtr ~= 0 then
		-- Check if still valid
		local addressId = memoryReadRepeat("uint", getProc(), self.TargetPtr + addresses.game_root.pawn.id) or 0;

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

	self.X = memoryReadRepeat("float", getProc(), self.Address + addresses.game_root.pawn.x) or self.X;
	self.Y = memoryReadRepeat("float", getProc(), self.Address + addresses.game_root.pawn.y) or self.Y;
	self.Z = memoryReadRepeat("float", getProc(), self.Address + addresses.game_root.pawn.z) or self.Z;
end

function CPawn:updateDirection()
	if not self:hasAddress() then
		return
	end

	local Vec1 = memoryReadRepeat("float", getProc(), self.Address + addresses.game_root.pawn.rotation_x);
	local Vec2 = memoryReadRepeat("float", getProc(), self.Address + addresses.game_root.pawn.rotation_y);
	local Vec3 = memoryReadRepeat("float", getProc(), self.Address + addresses.game_root.pawn.rotation_z);

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

	local mount_address = memoryReadInt(getProc(), self.Address + addresses.game_root.pawn.mount_ptr);
	if( mount_address ~= nil and mount_address ~= 0 ) then
		self.Mounted = true;
	else
		self.Mounted = false;
	end
end

function CPawn:updateInParty()
	if not self:hasAddress() then
		self.InParty = false;
		return
	end

	local attackableFlag = memoryReadRepeat("uint", getProc(), self.Address + addresses.game_root.pawn.attackable_flags);
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
		local attackableFlag = memoryReadRepeat("uint", getProc(), self.Address + addresses.game_root.pawn.attackable_flags);
		if attackableFlag then
			self.Attackable = bitAnd(attackableFlag, ATTACKABLE_MASK_ATTACKABLE) or bitAnd(attackableFlag, ATTACKABLE_MASK_ATTACKABLE2);

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

--[[
	local tmp = memoryReadRepeat("byteptr",getProc(), self.Address + addresses.pawnSwim_offset1, addresses.pawnSwim_offset2)
	self.Swimming = (tmp == 3 or tmp == 4)
	--]]
end

function CPawn:updateIsPet()
	if not self:hasAddress() then
		self.IsPet = nil
		return
	end


	if self.IsPet == nil then -- not updated yet
		self.IsPet = memoryReadRepeat("uint",getProc(), self.Address + addresses.game_root.pawn.owner_ptr)
		if self.IsPet == 0 then self.IsPet = false end
	end

end

function CPawn:updateSpeed()
	self.Speed = memoryReadRepeat("float", getProc(), self.Address + addresses.game_root.pawn.speed);
	self.Moving = (self.ActualSpeed ~= 0);
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
	if( type(count) ~= "number" ) then
		count = nil
	end

	self:updateBuffs()

	if type(buffnamesorids) ~= "table" then
		local buffs = {}
		for buffname in string.gmatch(buffnamesorids,"[^,]+") do
			table.insert(buffs, buffname)
		end
		buffnamesorids = buffs
	end

	-- for each buff the pawn has
	for i, buff in pairs(self.Buffs) do
		-- compare against each 'buffname'
		for j,buffname in pairs(buffnamesorids) do
			if( count == nil or buff.Count >= count ) then
				if( type(tonumber(buffname)) == "number" ) then
					-- Must be an ID. Do ID comparison.
					if( tonumber(buffname) == buff.Id ) then
						return buff;
					end
				else
					-- Do name comparison
					if( buffname == buff.Name ) then
						return buff
					end
				end
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

	-- Then try and find ' 3' type count in name
	local tmpCount = string.match(buffname,"%s(%d+)$")
	if tmpCount then
		count = tonumber(tmpCount)
		name = string.match(buffname,"(.*)%s%d+$")
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

	local base = getBaseAddress(addresses.party.icon_list.base);
	local listStart = memoryReadRepeat("uintptr", getProc(), base, addresses.party.icon_list.offset);
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
	local castFullTime = memoryReadFloat( getProc(), self.Address + addresses.game_root.pawn.cast_full_time);
	local castSoFar = memoryReadFloat( getProc(), self.Address + addresses.game_root.pawn.cast_time);

	if castFullTime and castSoFar then
		return castFullTime - castSoFar, castFullTime
	else
		return 0,0
	end

	return 0;
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

function CPawn:getLastDamage()
	return RoMScript("igf_events:getLastEnemyDamage()") or 0;
end

function CPawn:getLastCriticalTime()
	return RoMScript("igf_events:getLastEnemyCriticalTime()")
end

function CPawn:getLastDodgeTime()
	return RoMScript("igf_events:getLastEnemyDodgeTime()")
end
