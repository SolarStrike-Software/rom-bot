-- Skill types
STYPE_DAMAGE = 0
STYPE_HEAL = 1
STYPE_BUFF = 2
STYPE_DOT = 3
STYPE_HOT = 4
STYPE_SUMMON = 5

-- Target types
STARGET_ENEMY = 0
STARGET_SELF = 1
STARGET_FRIENDLY = 2
STARGET_PET = 3

CSkill = class(
	function (self, copyfrom)
		self.Name = "";
		self.aslevel = 0;		-- player level, >= that skill can be used
		self.skilltab = nil;	-- skill tab number
		self.skillnum = nil;	-- number of the skill at that skill tab
		self.Mana = 0;
		self.Rage = 0;
		self.Energy = 0;
		self.Concentration = 0;
		self.Range = 20;
		self.MinRange = 0; -- Must be at least this far away to cast
		self.CastTime = 0;
		self.Cooldown = 0;
		self.LastCastTime = { low = 0, high = 0 }; 	-- getTime() in ms
		self.Type = STYPE_DAMAGE;
		self.Target = STARGET_ENEMY;
		self.InBattle = nil; -- "true" = usable only in battle, false = out of battle
		self.ManaInc = 0; -- Increase in mana per level
		self.Level = 1;

		self.AutoUse = true; -- Can be used automatically by the bot

		self.MaxHpPer = 100; -- Must have less than this % HP to use
		self.MaxManaPer = 100;	-- Must have less than this % Mana to use
		self.MinManaPer = 0;	-- Must have more then this % Mana to use
		self.Toggleable = false;
		self.Toggled = false;
		
		self.pullonly = false;	-- use only in pull phase (only for melees with ranged pull attacks)
		self.maxuse = 0;	-- use that skill only x-times per fight
		self.rebuffcut = 0;	-- reduce cooldown for x seconds to rebuff earlier
		self.used = 0;		-- how often we used that skill in current fight

		self.hotkey = 0;
		self.modifier = 0;

		self.priority = 0; -- Internal use


		if( type(copyfrom) == "table" ) then
			self.Name = copyfrom.Name;
			self.Mana = copyfrom.Mana;
			self.Rage = copyfrom.Rage;
			self.Energy = copyfrom.Energy;
			self.Concentration = copyfrom.Concentration;
			self.Range = copyfrom.Range;
			self.MinRange = copyfrom.MinRange;
			self.CastTime = copyfrom.CastTime;
			self.Cooldown = copyfrom.Cooldown;
			self.Type = copyfrom.Type;
			self.Target = copyfrom.Target;
			self.InBattle = copyfrom.InBattle;
			self.ManaInc = copyfrom.ManaInc;
			self.MaxHpPer = copyfrom.MaxHpPer;
			self.MaxManaPer = copyfrom.MaxManaPer;
			self.MinManaPer = copyfrom.MinManaPer;
			self.Toggleable = copyfrom.Toggleable;
			self.priority = copyfrom.priority;
			self.pullonly = copyfrom.pullonly;
			self.maxuse = copyfrom.maxuse;
			self.rebuffcut = copyfrom.rebuffcut;
			self.aslevel = copyfrom.aslevel;
			self.skilltab = copyfrom.skilltab;
			self.skillnum = copyfrom.skillnum;
		end
	end
);


function CSkill:canUse(_only_friendly)
	if( hotkey == 0 ) then return false; end; --hotkey must be set!

	-- a local function to make it more easy to insert debuging lines
	-- you have to insert the correspointing options into your profile
	-- at the <onLoad> event to set the right values
	-- 	settings.profile.options.DEBUG_SKILLUSE.ENABLE = true;
	--	settings.profile.options.DEBUG_SKILLUSE.TIMEGAP = true;

	local function debug_skilluse(_reason, _arg1, _arg2, _arg3, _arg4, _arg5, _arg6 )
		
		-- return if debugging / detail  is disabled
		if( not settings.profile.options.DEBUG_SKILLUSE.ENABLE ) then return; end
		if( settings.profile.options.DEBUG_SKILLUSE[_reason] == false ) 	then  return; end;
--		if( _reason == "ONCOOLDOWN"	and  not settings.profile.options.DEBUG_SKILLUSE.ONCOOLDOWN ) 	then  return; end;
--		if( _reason == "NOCOOLDOWN"	and  not settings.profile.options.DEBUG_SKILLUSE.NOCOOLDOWN ) 	then  return; end;
--		if( _reason == "HPLOW" 		and  not settings.profile.options.DEBUG_SKILLUSE.HPLOW ) 		then  return; end;
	
		local function make_printable(_v)
			if(_v == true) then
				_v = "<true>";
			end
			if(_v == false) then
				_v = "<false>";
			end
			if( type(_v) == "table" ) then
				_v = "<table>";
			end
			if( type(_v) == "number" ) then
				_v = sprintf("%d", _v);
			end
			return _v
		end
	
		local hf_arg1, hf_arg2, hf_arg3, hf_arg4, hf_arg5, hf_arg6 = "", "", "", "", "", "";
		if(_arg1) then hf_arg1 = make_printable(_arg1); end;
		if(_arg2) then hf_arg2 = make_printable(_arg2); end;
		if(_arg3) then hf_arg3 = make_printable(_arg3); end;
		if(_arg4) then hf_arg4 = make_printable(_arg4); end;
		if(_arg5) then hf_arg5 = make_printable(_arg5); end;
		if(_arg6) then hf_arg6 = make_printable(_arg6); end;


		local msg = sprintf("[DEBUG] %s %s %s %s %s %s %s %s\n", _reason, self.Name, hf_arg1, hf_arg2, hf_arg3, hf_arg4, hf_arg5, hf_arg6 ) ;
		
		cprintf(cli.yellow, msg);
		
	end



	-- only friendly skill types?
	if( _only_friendly ) then
		if( self.Type ~= STYPE_HEAL  and
		    self.Type ~= STYPE_BUFF  and
			self.Type ~= STYPE_SUMMON and
		    self.Type ~= STYPE_HOT ) then
			return false;
		end;
	end

	-- You don't meet the maximum HP percent requirement
	if( player.MaxHP == 0 ) then player.MaxHP = 1; end; -- prevent division by zero
	if( player.HP / player.MaxHP * 100 > self.MaxHpPer ) then
		return false;
	end

	-- You are not below the maximum Mana Percent
	if( (player.Mana/player.MaxMana*100) > self.MaxManaPer ) then
		return false;
	end

	-- You are not above the minimum Mana Percent
	if( (player.Mana/player.MaxMana*100) < self.MinManaPer ) then
		return false;
	end

	-- Not enough rage/energy/concentration
	if(  player.Rage < self.Rage or player.Energy < self.Energy
		or player.Concentration < self.Concentration ) then
		return false;
	end

	-- This skill cannot be used in battle
	if( (player.Battling or player.Fighting) and self.InBattle == false ) then
		debug_skilluse("NOTINBATTLE");
		return false;
	end

	-- This skill can only be used in battle
	if( not player.Battling and self.InBattle == true ) then
		debug_skilluse("ONLYINBATTLE");
		return false;
	end   

	-- check if hp below our HP_LOW level
	if( self.Type == STYPE_HEAL or self.Type == STYPE_HOT ) then
		local hpper = (player.HP/player.MaxHP * 100);

		if( self.MaxHpPer ~= 100 ) then
			if( hpper > self.MaxHpPer ) then
				return false;
			end
		else
			-- Inherit from settings' HP_LOW
			if( hpper > settings.profile.options.HP_LOW ) then
				debug_skilluse("HPLOW", hpper, "greater as setting", settings.profile.options.HP_LOW );
				return false;
			end
		end
	end


	-- Still cooling down...
--	if( os.difftime(os.time(), self.LastCastTime) <= self.Cooldown ) then
--	if( os.difftime(os.time(), self.LastCastTime) < self.Cooldown ) then
	if( deltaTime(getTime(), self.LastCastTime) < 
	  self.Cooldown*1000-self.rebuffcut*1000 - settings.profile.options.SKILL_USE_PRIOR ) then	-- Cooldown is in sec

		debug_skilluse("ONCOOLDOWN", self.Cooldown*1000-self.rebuffcut*1000 - deltaTime(getTime(), self.LastCastTime) );
		return false;
	else
		debug_skilluse("NOCOOLDOWN", deltaTime(getTime(), self.LastCastTime) - self.Cooldown*1000-self.rebuffcut*1000 );
	end

	-- skill with maximum use per fight
	if( self.maxuse > 0 and
	    self.used >= self.maxuse ) then
		return false
	end

	-- Needs an enemy target
	if( self.Target == STARGET_ENEMY ) then
		if( not player:haveTarget() ) then
			return false;
		end
	end

	-- DOTs require the enemy to have > X% hp
	if( self.Type == STYPE_DOT ) then
		local enemy = player:getTarget();
		local hpper = (enemy.HP / enemy.MaxHP) * 100;
		if( hpper < settings.profile.options.DOT_PERCENT ) then
			return false;
		end;
	end

	-- Out of range
	if( player:distanceToTarget() > self.Range  and
	    self.Target ~= STARGET_SELF  ) then		-- range check only if no selftarget skill
		return false;
	end

	-- Too close
	if( player:distanceToTarget() < self.MinRange  and
	    self.Target ~= STARGET_SELF  ) then		-- range check only if no selftarget skill 
		return false;
	end

	-- check pullonly skills
	if( self.pullonly == true and
	    not player.ranged_pull ) then
		return false
	end
	
	-- Not enough mana
	if( player.Mana < math.ceil(self.Mana + (self.Level-1)*self.ManaInc) ) then
		return false;
	end

	-- Already have a pet out
	if( self.Type == STYPE_SUMMON and player.PetPtr ~= 0 ) then
		return false;
	end

	if( self.Toggleable and self.Toggled == true ) then
		return false;
	end

	return true;
end


function CSkill:use()
	local estimatedMana;
	if( self.MinManaPer > 0 ) then
		estimatedMana = math.ceil((self.MinManaPer/100)*player.MaxMana);
	else
		estimatedMana = math.ceil(self.Mana + (self.Level-1)*self.ManaInc);
	end

	local target = player:getTarget();

	if( self.hotkey == nil ) then
		local str = sprintf("Bad skill hotkey name: %s", tostring(self.Name));
		error(str);
	end

	self.used = self.used + 1;	-- count use of skill per fight
--	self.LastCastTime = os.time() + self.CastTime;

	-- be sure to don't miss a buff true casting to fast, so we cast a little slower for
	-- our own buffs
	if( self.Type == STYPE_BUFF ) then
		yrest(settings.profile.options.SKILL_USE_PRIOR);
	end

	-- set LastCastTime, thats the current key press time plus the casting time (if there is some)
	-- self.CastTime is in sec, hence * 1000
	-- every 1 ms in self.LastCastTime.low ( from getTime() ) is about getTimerFrequency().low
	-- but we calculate the value at bot start time
	self.LastCastTime = getTime();
	self.LastCastTime.low = self.LastCastTime.low + self.CastTime*1000 * bot.GetTimeFrequency;
	
	-- debug time gap between casts
	if( settings.profile.options.DEBUG_SKILLUSE.ENABLE  and
		settings.profile.options.DEBUG_SKILLUSE.TIMEGAP and
		debug_LastCastTime ~= nil and
		debug_LastCastTime.low > 0 ) then 
		
		local msg = sprintf("[DEBUG] time-gap between skill use %d\n", 
		  deltaTime(getTime(), debug_LastCastTime) );
		cprintf(cli.yellow, msg);
	end
	debug_LastCastTime = getTime();		-- remember time to check time-lag between casts

	
	if(self.hotkey == "MACRO" or self.hotkey == "" or self.hotkey == nil ) then
	
		-- hopefully skillnames in enus and eneu are the same
		if(bot.ClientLanguage == "enus" or bot.ClientLanguage == "eneu") then
			local hf_langu = "en";
		else
			local hf_langu = bot.ClientLanguage;
		end
	
		if( database.skills[self.Name][hf_langu] ) then		-- is local skill name available?
			RoMScript("CastSpellByName("..database.skills[self.Name][hf_langu]..");");
		elseif( self.skilltab ~= nil  and  self.skillnum ~= nil ) then
			RoMScript("UseSkill("..self.skilltab..","..self.skillnum..");");
		else
			cprintf(cli.yellow, "No local skillname in skills_local.xml. Please maintenance the file and send it to the developers.\n", self.Name);	
		end;
	else
		-- use the normal hotkeys
		if( self.modifier ) then
			keyboardHold(self.modifier);
		end
		keyboardPress(self.hotkey);
		if( self.modifier ) then
			keyboardRelease(self.modifier);
		end
	end

	if( self.Toggleable ) then
		self.Toggled = true;
	end

end