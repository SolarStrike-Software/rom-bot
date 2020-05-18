PT_NONE = -1;
PT_PLAYER = 1;
PT_MONSTER = 2;
PT_NPC = 4;
PT_NODE = 4;

CObject = class(
	function (self, ptr)
		self.Address = ptr;
		self.Name = "<UNKNOWN>";
		self.Id = 0;
		self.Type = PT_NONE;
		self.X = 0.0;
		self.Y = 0.0;
		self.Z = 0.0;

		if( self.Address ~= 0 and self.Address ~= nil ) then self:update(); end
	end
);

function CObject:update()
	local proc = getProc();
	local memerrmsg = "Failed to read memory";
	local tmp;

	self.Id = memoryReadUInt(proc, self.Address + addresses.game_root.pawn.id) or 0;
	self.Type = memoryReadInt(proc, self.Address + addresses.game_root.pawn.type) or -1;

	if( 1 > self.Id or self.Id > 999999 or self.Type == -1 ) then -- invalid object
		self.Id = 0
		self.Type = -1
		self.Name = ""
		return;
	end

	-- Disable memory warnings for name reading only
	showWarnings(false);
	local namePtr = memoryReadRepeat("uint", proc, self.Address + addresses.game_root.pawn.name_ptr);
--	self.Name = debugAssert(memoryReadString(proc, namePtr), memerrmsg);
	if( namePtr == nil or namePtr == 0 ) then
		tmp = nil;
	else
		tmp = memoryReadString(proc, namePtr);
	end
	showWarnings(true); -- Re-enable warnings after reading


	-- UTF8 -> ASCII translation not for player names
	-- because that would need the whole table and there we normaly
	-- don't need it, we don't print player names in the MM window or so
	if( tmp == nil ) then
		self.Name = "<UNKNOWN>";
--	elseif(self.Type == PT_PLAYER ) then
--		self.Name = tmp;
	else
		-- time for only convert 8 characters is 0 ms
		-- time for convert the whole UTF8_ASCII.xml table is about 6-7 ms
--		local hf_before = getTime();

		if( bot.ClientLanguage == "RU" ) then
			self.Name = utf82oem_russian(tmp);
		else
			self.Name = utf8ToAscii_umlauts(tmp);	-- only convert umlauts
--			self.Name = convert_utf8_ascii( tmp )	-- convert the whole UTF8_ASCII.xml table
		end
--		cprintf(cli.yellow, "DEBUG utf8 %s %d\n", self.Name, deltaTime(getTime(), hf_before) );
	end

	self.X = memoryReadFloat(proc, self.Address + addresses.game_root.pawn.x) or 0;
	self.Y = memoryReadFloat(proc, self.Address + addresses.game_root.pawn.y) or 0;
	self.Z = memoryReadFloat(proc, self.Address + addresses.game_root.pawn.z) or 0;

	--local attackableFlag = debugAssert(memoryReadUByte(proc, self.Address + addresses.pawnAttackable_offset)) or 0;
	--printf("attackable flag: 0x%X (%s)\n", attackableFlag, self.Name);
	--printf("check(player): %s\n", tostring( bitAnd(attackableFlag, ATTACKABLE_MASK_PLAYER) ));

	if( self.Type == PT_MONSTER ) then
		self.Attackable = true;
	else
		self.Attackable = false;
		--[[
		if( bitAnd(attackableFlag, ATTACKABLE_MASK_PLAYER) ) then
			self.Attackable = true;
		else
			self.Attackable = false;
		end]]
	end

	if( self.Address == nil ) then
		error("Error reading memory in CObject:update()");
	end
end
