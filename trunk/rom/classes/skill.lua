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
		self.Id = 0;
		self.TPToLevel = 0;
		self.Level = 1;
		self.aslevel = 0;		-- player level, >= that skill can be used
		self.Mana = 0;
		self.Rage = 0;
		self.Energy = 0;
		self.Concentration = 0;
		self.Nature = 0;
		self.Range = 20;
		self.MinRange = 0; -- Must be at least this far away to cast
		self.CastTime = 0;
		self.Cooldown = 0;
		self.LastCastTime = { low = 0, high = 0 }; 	-- getTime() in ms
		self.Type = STYPE_DAMAGE;
		self.Target = STARGET_ENEMY;
		self.InBattle = nil; -- "true" = usable only in battle, false = out of battle
		self.ManaInc = 0; -- Increase in mana per level

		-- Information about required buffs/debuffs
		self.BuffName = "" -- name of buff if skill type is 'buff'
		self.ReqBuffCount = 0;
		self.ReqBuffTarget = "player";
		self.ReqBuffName = ""; -- Name of the buff/debuff
		self.NoBuffCount = 0;
		self.NoBuffTarget = "player";
		self.NoBuffName = ""; -- Name of the buff/debuff

		self.AutoUse = true; -- Can be used automatically by the bot

		self.TargetMaxHpPer = 100;	-- Must have less than this % HP to use
		self.TargetMaxHp = 9999999;	-- Must have less than this HP to use
		self.MaxHpPer = 100;	-- Must have less than this % HP to use
		self.MaxManaPer = 100;	-- Must have less than this % Mana to use
		self.MinManaPer = 0;	-- Must have more then this % Mana to use
		self.Toggleable = false;
		self.Toggled = false;

		self.Blocking = false;	-- Whether or not the skill blocks the queue
		self.pull = false -- pull is to specify which skill to use to start combat.
		self.pullonly = false;	-- use only in pull phase (only for melees with ranged pull attacks)
		self.maxuse = 0;	-- use that skill only x-times per fight
		self.rebuffcut = 0;	-- reduce cooldown for x seconds to rebuff earlier
		self.used = 0;		-- how often we used that skill in current fight

		self.hotkey = 0;
		self.modifier = 0;

		self.priority = 0; -- Internal use
		self.skillnum = 0
		self.skilltab = 0

		if( type(copyfrom) == "table" ) then
			self.Name = copyfrom.Name;
			self.Id = copyfrom.Id;
			self.TPToLevel = copyfrom.TPToLevel;
			self.Level = copyfrom.Level;
			self.aslevel = copyfrom.aslevel;
			self.Mana = copyfrom.Mana;
			self.Rage = copyfrom.Rage;
			self.Energy = copyfrom.Energy;
			self.Concentration = copyfrom.Concentration;
			self.Nature = copyfrom.Nature;
			self.Range = copyfrom.Range;
			self.MinRange = copyfrom.MinRange;
			self.CastTime = copyfrom.CastTime;
			self.Cooldown = copyfrom.Cooldown;
			self.Type = copyfrom.Type;
			self.Target = copyfrom.Target;
			self.InBattle = copyfrom.InBattle;
			self.ManaInc = copyfrom.ManaInc;
			self.TargetMaxHpPer = copyfrom.TargetMaxHpPer;
			self.TargetMaxHp = copyfrom.TargetMaxHp;
			self.MaxHpPer = copyfrom.MaxHpPer;
			self.MaxManaPer = copyfrom.MaxManaPer;
			self.MinManaPer = copyfrom.MinManaPer;
			self.Toggleable = copyfrom.Toggleable;
			self.hotkey = copyfrom.hotkey;
			self.modifier = copyfrom.modifier;
			self.priority = copyfrom.priority;
			self.pull = copyfrom.pull;
			self.pullonly = copyfrom.pullonly;
			self.maxuse = copyfrom.maxuse;
			self.rebuffcut = copyfrom.rebuffcut;
			self.BuffName = copyfrom.BuffName;
			self.ReqBuffCount = copyfrom.ReqBuffCount;
			self.ReqBuffTarget = copyfrom.ReqBuffTarget;
			self.ReqBuffName = copyfrom.ReqBuffName;
			self.NoBuffCount = copyfrom.NoBuffCount;
			self.NoBuffTarget = copyfrom.NoBuffTarget;
			self.NoBuffName = copyfrom.NoBuffName;
			self.Blocking = copyfrom.Blocking;
			self.skillnum = copyfrom.skillnum
			self.skilltab = copyfrom.skilltab
		end
	end
);


function CSkill:canUse(_only_friendly, target)
	if not self.Available then
		return false
	end

	if( target == nil ) then
		player:update();
		target = player:getTarget();
	end
	if( self.hotkey == 0 ) then return false; end; --hotkey must be set!

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

	--local target = player:getTarget();	-- get target fields

	-- Is player level more than or equal to aslevel
	if player.Level < self.aslevel then
		debug_skilluse("ASLEVEL", player.Level, self.aslevel);
		return false
	end

	-- only friendly skill types?
	if( _only_friendly ) then
		if( self.Type ~= STYPE_HEAL  and
		    self.Type ~= STYPE_BUFF  and
			self.Type ~= STYPE_SUMMON and
		    self.Type ~= STYPE_HOT ) then
		    debug_skilluse("ONLYFRIENDLY", self.Type);
			return false;
		end;
	end


	-- Still cooling down...
	local prior = getSkillUsePrior();

	if( deltaTime(getTime(), self.LastCastTime) <
		  (self.Cooldown*1000 - prior) ) then	-- Cooldown is in sec
		debug_skilluse("ONCOOLDOWN", self.Cooldown*1000 - deltaTime(getTime(), self.LastCastTime) );
		return false;
--	else
--		debug_skilluse("NOCOOLDOWN", deltaTime(getTime(), self.LastCastTime) - self.Cooldown*1000-self.rebuffcut*1000 );
	end


-- You don't meet the maximum HP percent requirement
   if( player.MaxHP == 0 ) then player.MaxHP = 1; end; -- prevent division by zero
   if( target.MaxHP == 0 ) then target.MaxHP = 1; end

   if target.Type ~= PT_PLAYER then -- no target or enemy target, heal self
      if( (self.MaxHpPer < 0 and -1 or 1) * (player.HP / player.MaxHP * 100) > self.MaxHpPer ) then
         debug_skilluse("MAXHPPER", player.HP/player.MaxHP*100, self.MaxHpPer);
         return false;
      end
   else
   --=== Heal friendly target, including self ===--
      if( (self.MaxHpPer < 0 and -1 or 1) * (target.HP / target.MaxHP * 100) > self.MaxHpPer ) then
         debug_skilluse("MAXHPPER", target.HP/target.MaxHP*100, self.MaxHpPer);
         return false;
      end
   end

	-- You are not below the maximum Mana Percent
	if( (self.MaxManaPer < 0 and -1 or 1) * (player.Mana/player.MaxMana*100) > self.MaxManaPer ) then
		debug_skilluse("MAXMANAPER", (player.Mana/player.MaxMana*100), self.MaxManaPer);
		return false;
	end

	-- You are not above the minimum Mana Percent
	if( (player.Mana/player.MaxMana*100) < self.MinManaPer ) then
		debug_skilluse("MINMANAPER", (player.Mana/player.MaxMana*100), self.MinManaPer);
		return false;
	end

	-- Not enough rage/energy/concentration
	if(  player.Rage < self.Rage or player.Energy < self.Energy
		or player.Concentration < self.Concentration ) then
		debug_skilluse("NORAGEENERGYCONCEN");
		return false;
	end

	-- This skill cannot be used in battle
--	if( (player.Battling or player.Fighting) and self.InBattle == false ) then
	if( player.Battling  and self.InBattle == false ) then
		debug_skilluse("NOTINBATTLE", player.Battling, player.Fighting);
		return false;
	end

	-- This skill can only be used in battle
	if( not player.Battling and self.InBattle == true ) then
		debug_skilluse("ONLYINBATTLE", player.Battling);
		return false;
	end

	-- check if hp below our HP_LOW level
	if( self.Type == STYPE_HEAL or self.Type == STYPE_HOT ) then
		local hpper = (player.HP/player.MaxHP * 100);
		if target.Type ~= PT_PLAYER then
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
		else
			local hpper = (target.HP/target.MaxHP * 100);
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
	end


	-- skill with maximum use per fight
	if( self.maxuse > 0 and
	    self.used >= self.maxuse ) then
	    debug_skilluse("MAXUSE", self.used, self.maxuse);
		return false
	end

	-- Needs an enemy target
	if( self.Target == STARGET_ENEMY ) then
		if( not player:haveTarget() ) then
			debug_skilluse("TARGETNOENEMY");
			return false;
		end
	end

	-- DOTs require the enemy to have > X% hp
	if( self.Type == STYPE_DOT ) then
		local hpper = (target.HP / target.MaxHP) * 100;
		if( hpper < settings.profile.options.DOT_PERCENT ) then
			debug_skilluse("DOTHPPER", hpper, settings.profile.options.DOT_PERCENT);
			return false;
		end;
	end

	-- only if target HP % is below given level
	if( target  and  ((self.TargetMaxHpPer < 0 and -1 or 1) * (target.HP/target.MaxHP*100)) > self.TargetMaxHpPer ) then
		debug_skilluse("TARGETHPPER", target.HP/target.MaxHP*100 );
		return false;
	end

	-- only if target HP points is below given level
	if( target  and  ((self.TargetMaxHp < 0 and -1 or 1) * target.HP) > self.TargetMaxHp ) then
		debug_skilluse("TARGEHP", target.HP );
		return false;
	end

	-- Out of range
	if( player:distanceToTarget() > self.Range  and
	    self.Target ~= STARGET_SELF  ) then		-- range check only if no selftarget skill
	    debug_skilluse("OUTOFRANGE", player:distanceToTarget(), self.Range );
		return false;
	end

	-- Too close
	if( player:distanceToTarget() < self.MinRange  and
	    self.Target ~= STARGET_SELF  ) then		-- range check only if no selftarget skill
	    debug_skilluse("MINRANGE", player:distanceToTarget(), self.MinRange );
		return false;
	end

	-- check pullonly skills
	if( self.pullonly == true and
	    not player.ranged_pull ) then
	    debug_skilluse("PULLONLY");
		return false
	end

	-- Not enough mana
	if( player.Mana < math.ceil(self.Mana + (self.Level-1)*self.ManaInc) ) then
		debug_skilluse("NOTENOUGHMANA", player.Mana, math.ceil(self.Mana + (self.Level-1)*self.ManaInc));
		return false;
	end


	-- Already have the same pet out
	if self.Type == STYPE_SUMMON then
		petupdate()
		if player.Class1 == CLASS_WARDEN and pet.Name ~= "<UNKNOWN>" then -- have a pet out already
			for k,v in pairs(pettable) do
				if pet.Name == v.name and self.Id == v.skillid then
					debug_skilluse("PETALREADYOUT");
					PetWaitTimer = 0
					return false;
				end
			end
		end

		if PetWaitTimer == nil or PetWaitTimer == 0 then -- Start timer
			PetWaitTimer = os.time()
			return false
		elseif os.time() - PetWaitTimer < 15 then -- Wait longer
			return false
		end
	end


	if( self.Toggleable and self.Toggled == true ) then
		debug_skilluse("TOGGLED");
		return false;
	end

	-- check if 'self' has buff
	if self.BuffName ~= nil and self.Target == STARGET_SELF then
		local buffitem = player:getBuff(self.BuffName)
		--=== check for -1 for buffs with no duration like rogue hide ===--
		if buffitem and ((buffitem.TimeLeft > self.rebuffcut + prior/1000) or buffitem.TimeLeft == -1 ) then
			debug_skilluse("PLAYERHASBUFF");
			return false
		end
	end

	-- check if 'enemy' has buff
	if self.BuffName ~= nil and self.Target == STARGET_ENEMY and
		target and target.Type == PT_MONSTER then
		if target:hasBuff(self.BuffName) then
			debug_skilluse("TARGETHASBUFF");
			return false
		end
	end

	-- check if 'friendly' has buff
	if self.BuffName ~= nil and self.Target == STARGET_FRIENDLY then
		if target and target.Type == PT_PLAYER then
			if target:hasBuff(self.BuffName) then
				debug_skilluse("TARGETHASBUFF");
				return false
			end
		else
			if player:hasBuff(self.BuffName) then
				debug_skilluse("PLAYERHASBUFF");
				return false
			end
		end
	end

	-- Check required buffs/debuffs
	if( self.ReqBuffName ~= "" ) then
		local bool;
		if( self.ReqBuffTarget == "player" ) then
			bool = player:hasBuff(self.ReqBuffName, self.ReqBuffCount)
		elseif target and ( self.ReqBuffTarget == "target" ) then
			bool = target:hasBuff(self.ReqBuffName, self.ReqBuffCount)
		end

		if bool == false then
			debug_skilluse("REQBUFF");
			return false
		end
	end

	-- Check non-required buffs/debuffs
	if( self.NoBuffName ~= "" ) then
		local bool;
		if( self.NoBuffTarget == "player" ) then
			bool = player:hasBuff(self.NoBuffName, self.NoBuffCount)
		elseif target and ( self.NoBuffTarget == "target" ) then
			bool = target:hasBuff(self.NoBuffName, self.NoBuffCount)
		end

		if bool == true then
			debug_skilluse("NOBUFF");
			return false
		end
	end

	-- CHeck if enough Natures Power
	if self.Nature > player.Nature and
		not player:hasBuff(503817) then -- No need NP if has buff "Unity with Mother Earth"
		debug_skilluse("NEEDMORENATURE");
		return false
	end

	-- warden pet heal
	if self.Id == 493398 then
		petupdate()
		if pet.Name == "<UNKNOWN>" or ( pet.HP / pet.MaxHP * 100) > 70 then
			return false
		end
	end

	--=== water fairy usage
	if player.Class1 == CLASS_PRIEST and self.Type == STYPE_SUMMON then
		debug_skilluse("USINGPETFUNCTION");
		waterfairy()
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


	-- set LastCastTime, thats the current key press time plus the casting time (if there is some)
	-- self.CastTime is in sec, hence * 1000
	-- every 1 ms in self.LastCastTime.low ( from getTime() ) is about getTimerFrequency().low
	-- we calculate the value at bot start time
	self.LastCastTime = getTime();
	self.LastCastTime.low = self.LastCastTime.low + self.CastTime*1000 * bot.GetTimeFrequency;
	if self.CastTime > 0 then player.LastSkillCastTime = self.CastTime end
	if self.CastTime > 0 then player.LastSkillType = self.Type end
	-- wait for global cooldown gap (1000ms) between skill use
	-- there are different 'waits' in the bot:
	-- at CPlayer:cast(skill): for the casting flag gone
	-- at CPlayer:checkSkills(): for the casting flag gone
	-- and here to have a minimum delay between the keypresses
	-- 850/900 will work after skills without casting time, but will result in misses
	-- after skills that have a casting time
	local prior = getSkillUsePrior();

	while( deltaTime(getTime(), bot.LastSkillKeypressTime) <
		settings.profile.options.SKILL_GLOBALCOOLDOWN - prior ) do
		yrest(10);
	end

	-- debug time gap between casts
	if( settings.profile.options.DEBUG_SKILLUSE.ENABLE  and
		settings.profile.options.DEBUG_SKILLUSE.TIMEGAP ) then
		local hf_casting = "false";
		if(player.Casting) then hf_casting = "true"; end;
		local msg = sprintf("[DEBUG] gap between skilluse %d, pcasting=%s\n",
		  deltaTime(getTime(), bot.LastSkillKeypressTime), hf_casting );
		cprintf(cli.yellow, msg);
	end

	-- Make sure we aren't already busy casting something else, thats only neccessary after
	-- skills with a casting time
	--[[local start_wait = getTime();
	while(player.Casting) do -- this is done in CPlayer:cast()
		if( deltaTime(getTime(), start_wait ) > 6000 ) then break; end;	-- in case there is a client update bug
		-- Waiting for casting to finish...
		yrest(50);
		player:update();
	end]]

	bot.LastSkillKeypressTime = getTime();		-- remember time to check time-lag between casts

	--=== warden usage
	if player.Class1 == CLASS_WARDEN then
		local skillName = GetIdName(self.Id)
		if self.Type == STYPE_BUFF then
			if not player.Battling then
				--=== sacrifice pet buffs
				if self.Id == 493346 then -- heart of the oak
					wardenbuff(503946) 	-- code in classes/pet.lua
					return
				end
				if self.Id == 493348 then -- protection of nature
					wardenbuff(503581)
					return
				end
				if self.Id == 493347 then -- power of the oak
					wardenbuff(503580)
					return
				end
			else
				return
			end
		end
		if self.Type == STYPE_SUMMON and not player.Battling then
			petupdate()		-- code in classes/pet.lua
			-- dont summon warden pet if already summoned.
			if self.Id == 493333 and pet.Name ~= GetIdName(102297) then
				RoMScript("CastSpellByName(\""..skillName.."\");");
				repeat
					yrest(1000)
					player:update()
				until not player.Casting
				setpetautoattacks()
				return
			end
			if self.Id == 493344 and pet.Name ~= GetIdName(102325) then
				RoMScript("CastSpellByName(\""..skillName.."\");");
				repeat
					yrest(1000)
					player:update()
				until not player.Casting
				setpetautoattacks()
				return
			end
			if self.Id == 493343 and pet.Name ~= GetIdName(102324) then
				RoMScript("CastSpellByName(\""..skillName.."\");");
				repeat
					yrest(1000)
					player:update()
				until not player.Casting
				setpetautoattacks()
				return
			end
			if self.Id == 494212 and pet.Name ~= GetIdName(102803) then
				RoMScript("CastSpellByName(\""..skillName.."\");");
				repeat
					yrest(1000)
					player:update()
				until not player.Casting
				setpetautoattacks()
				return
			end
		end

	end

	if(self.hotkey == "MACRO" or self.hotkey == "" or self.hotkey == nil ) then
		-- Get skill name
		local skillName = GetIdName(self.Id)

		-- Cast skill
		RoMScript("CastSpellByName(\""..skillName.."\");");
	else
		-- use the normal hotkeys
		keyboardPress(self.hotkey, self.modifier);
	end

	if( self.Toggleable ) then
		self.Toggled = true;
	end

end
