-- Skill types
STYPE_DAMAGE = 0
STYPE_HEAL = 1
STYPE_BUFF = 2
STYPE_DOT = 3
STYPE_HOT = 4

-- Target types
STARGET_ENEMY = 0
STARGET_SELF = 1
STARGET_FRIENDLY = 2

CSkill = class(
	function (self, copyfrom)
		self.Name = "";
		self.Mana = 0;
		self.Rage = 0;
		self.Energy = 0;
		self.Concentration = 0;
		self.Range = 20;
		self.MinRange = 0; -- Must be at least this far away to cast
		self.CastTime = 0;
		self.Cooldown = 0;
		self.LastCastTime = 0; --os.time();
		self.Type = STYPE_DAMAGE;
		self.Target = STARGET_ENEMY;
		self.InBattle = nil; -- "true" = usable only in battle, false = out of battle
		self.ManaInc = 0; -- Increase in mana per level
		self.Level = 1;

		self.MaxHpPer = 100; -- Must have less than this % HP to cast
		self.Toggleable = false;
		self.Toggled = false;

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
			self.Toggleable = copyfrom.Toggleable;
			self.priority = copyfrom.priority;
		end
	end
);


function CSkill:canUse()
	if( hotkey == 0 ) then return false; end; --hotkey must be set!

	-- Still cooling down...
	if( os.difftime(os.time(), self.LastCastTime) <= self.Cooldown ) then
		return false;
	end

	if( player.Mana < math.ceil(self.Mana + (self.Level-1)*self.ManaInc) ) then
		return false;
	end

	-- Not enough rage/energy/concentration
	if(  player.Rage < self.Rage or player.Energy < self.Energy
		or player.Concentration < self.Concentration ) then
		return false;
	end

	-- This skill cannot be used in battle
	if( player.Battling and self.InBattle == false ) then
		return false;
	end

	-- This skill can only be used in battle
	if( not player.Battling and self.InBattle == true ) then
		return false;
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

	-- You don't meet the maximum HP percent requirement
	if( player.MaxHP == 0 ) then player.MaxHP = 1; end; -- prevent division by zero
	if( player.HP / player.MaxHP * 100 > self.MaxHpPer ) then
		return false;
	end

	if( self.Type == STYPE_HEAL or self.Type == STYPE_HOT ) then
		local hpper = (player.HP/player.MaxHP * 100);

		if( self.MaxHpPer ~= 100 ) then
			if( hpper > self.MaxHpPer ) then
				return false;
			end
		else
			-- Inherit from settings' HP_LOW
			if( hpper > settings.profile.options.HP_LOW ) then
				return false;
			end
		end
	end

	if( self.Toggleable and self.Toggled == true ) then
		return false;
	end

	return true;
end


function CSkill:use()
	local estimatedMana = math.ceil(self.Mana + (self.Level-1)*self.ManaInc);
	printf(language[21], self.Name);

	if( self.hotkey == nil ) then
		local str = sprintf("Bad skill hotkey name: %s", tostring(self.Name));
		error(str);
	end

	self.LastCastTime = os.time() + self.CastTime;
	if( self.modifier ) then
		keyboardHold(self.modifier);
	end
	keyboardPress(self.hotkey);
	if( self.modifier ) then
		keyboardRelease(self.modifier);
	end

	if( type(settings.profile.events.onSkillCast) == "function" ) then
		arg1 = self;
		local status,err = pcall(settings.profile.events.onSkillCast);
		if( status == false ) then
			local msg = sprintf("onSkillCast error: %s", err);
			error(msg);
		end
	end

	if( self.Toggleable ) then
		self.Toggled = true;
	end

end