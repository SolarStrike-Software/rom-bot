database =  {
	skills = {},
	nodes = {},
	utf8_ascii = {},
	consumables = {},
	giftbags = {}
};

function database.load()
	local root = xml.open(getExecutionPath() .. "/database/skills.xml");
	local elements = root:getElements();


	for i,v in pairs(elements) do
		local tmp = CSkill();
		local name, id, mana, targetmaxhpper, targetmaxhp, maxhpper, maxmanaper, rage, energy, focus, nature;
		local range, minrange, casttime, cooldown, type, target, autouse;
		local toggleable, minmanaper, inbattle, priority, level, aslevel, skilltab, skillnum;
		local buffname, reqbuffcount, reqbufftarget, reqbuffname, nobuffcount, nobufftarget, nobuffname;
		local enemydodge, enemycritical, playerblock, playerdodge

		name = v:getAttribute("name");
		id = v:getAttribute("id");
		range = v:getAttribute("range");
		minrange = v:getAttribute("minrange");
		casttime = v:getAttribute("casttime");
		cooldown = v:getAttribute("cooldown");
		type = v:getAttribute("type");
		target = v:getAttribute("target");
		autouse = v:getAttribute("autouse");
		toggleable = v:getAttribute("toggleable");
		maxhpper = v:getAttribute("maxhpper");
		maxmanaper = v:getAttribute("maxmanaper");
		minmanaper = v:getAttribute("minmanaper");
		targetmaxhpper = v:getAttribute("targetmaxhpper");
		targetmaxhp = v:getAttribute("targetmaxhp");
		inbattle = v:getAttribute("inbattle");
		priority = v:getAttribute("priority");
		enemydodge = v:getAttribute("enemydodge")
		enemycritical = v:getAttribute("enemycritical")
		playerblock = v:getAttribute("playerblock")
		playerdodge = v:getAttribute("playerdodge")

		buffname = tostring(v:getAttribute("buffname") or "");
		reqbuffcount = tonumber(v:getAttribute("reqbuffcount") or 0);
		reqbufftarget = string.lower(tostring(v:getAttribute("reqbufftarget") or "player"));
		reqbuffname = tostring(v:getAttribute("reqbuffname") or "");
		nobuffcount = tonumber(v:getAttribute("nobuffcount") or 0);
		nobufftarget = string.lower(tostring(v:getAttribute("nobufftarget") or "player"));
		nobuffname = tostring(v:getAttribute("nobuffname") or "");

		aoecenter = string.lower(v:getAttribute("aoecenter") or "");
		aoerange = v:getAttribute("aoerange") or ""
		clicktocast = v:getAttribute("clicktocast")
		globalcooldown = v:getAttribute("globalcooldown")
		addweaponrange = v:getAttribute("addweaponrange")

		-- Automatically assign priority (if not given) based on type
		if( not priority ) then
			if( type == "damage" ) then
				priority = 70;
			elseif( type == "hot" ) then
				priority = 110;
			elseif( type == "heal" ) then
				priority = 100;
			elseif( type == "buff" ) then
				priority = 90;
			elseif( type == "summon" ) then
				priority = 95;
			elseif( type == "dot" ) then
				priority = 80;
			end;
		end

		-- Re-assign type to an actual defined type (improves speed; reduces slow string compares)
		if( type == "damage" ) then
			type = STYPE_DAMAGE;
		elseif( type == "hot" ) then
			type = STYPE_HOT;
		elseif( type == "heal" ) then
			type = STYPE_HEAL;
		elseif( type == "buff" ) then
			type = STYPE_BUFF;
		elseif( type == "summon" ) then
			type = STYPE_SUMMON;
		elseif( type == "dot" ) then
			type = STYPE_DOT;
		end;

		if clicktocast == true and aoecenter == "" then
			aoecenter = SAOE_TARGET
		end

		if aoecenter == "player" then
			aoecenter = SAOE_PLAYER
		elseif aoecenter == "target" or aoecenter == SAOE_TARGET then
			aoecenter = SAOE_TARGET
			if aoerange == "" then
				if clicktocast == true then
					aoerange = 65
				else
					aoerange = 50
				end
			end
		end

		if addweaponrange ~= true then
			addweaponrange = nil
		end


		if( target == "enemy" ) then target = STARGET_ENEMY; end;
		if( target == "self" ) then target = STARGET_SELF; end;
		if( target == "friendly" ) then target = STARGET_FRIENDLY; end;
		if( target == "party" ) then target = STARGET_PARTY; end;

		if(name) then tmp.Name = name; end;
		if(id) then tmp.Id = id; end;
		if(mana) then tmp.Mana = mana; end;
		if(rage) then tmp.Rage = rage; end;
		if(energy) then tmp.Energy = energy; end;
		if(focus) then tmp.focus = focus; end;
		if(nature) then tmp.Nature = nature end
		if(range) then tmp.Range = range; end;
		if(minrange) then tmp.MinRange = minrange; end;
		if(casttime) then tmp.CastTime = casttime; end;
		if(cooldown) then tmp.Cooldown = cooldown; end;
		if(type) then tmp.Type = type; end;
		if(target) then tmp.Target = target; end;
		if(autouse~=nil) then tmp.AutoUse = autouse; end;
		if(toggleable) then tmp.Toggleable = toggleable; end;
		if(targetmaxhp) then tmp.TargetMaxHp = targetmaxhp; end;
		if(targetmaxhpper) then tmp.TargetMaxHpPer = targetmaxhpper; end;
		if(maxhpper) then tmp.MaxHpPer = maxhpper; end;
		if(maxmanaper) then tmp.MaxManaPer = maxmanaper; end;
		if(minmanaper) then tmp.MinManaPer = minmanaper; end;
		if(inbattle ~= nil) then tmp.InBattle = inbattle; end;
		if(priority) then tmp.priority = priority; end;
		if(level) then tmp.Level = level; end;
		if(aslevel) then tmp.aslevel = aslevel; end;
		if(skilltab) then tmp.skilltab = skilltab; end;
		if(skillnum) then tmp.skillnum = skillnum; end;

		if(buffname ~= "") then tmp.BuffName = buffname; end;
		if(reqbuffcount > 0 ) then tmp.ReqBuffCount = reqbuffcount; end;
		if(reqbufftarget ~= "") then tmp.ReqBuffTarget = reqbufftarget; end;
		if(reqbuffname ~= "") then tmp.ReqBuffName = reqbuffname; end;
		if(nobuffcount > 0 ) then tmp.NoBuffCount = nobuffcount; end;
		if(nobufftarget ~= "") then tmp.NoBuffTarget = nobufftarget; end;
		if(nobuffname ~= "") then tmp.NoBuffName = nobuffname; end;
		if(aoecenter ~= "") then tmp.AOECenter = aoecenter; end;
		if(aoerange ~= "") then tmp.AOERange = aoerange; end;
		if(clicktocast ~= "") then tmp.ClickToCast = clicktocast; end;
		if(globalcooldown ~= nil) then tmp.GlobalCooldown = globalcooldown; end;
		if(addweaponrange ~= nil) then tmp.AddWeaponRange = addweaponrange; end;

		if(enemydodge) then tmp.EnemyDodge = true; end;
		if(enemycritical) then tmp.EnemyCritical = true; end;
		if(playerdodge) then tmp.PlayerDodge = true; end;
		if(playerblock) then tmp.PlayerBlock = true; end;

		database.skills[name] = tmp;
	end


	-- import nodes/ressouces
	root = xml.open(getExecutionPath() .. "/database/nodes.xml");
	elements = root:getElements();

	for i,v in pairs(elements) do
		local name, id, type, level;
		local tmp = CNode();

		name = v:getAttribute("name");
		id = v:getAttribute("id");
		type = v:getAttribute("type");
		level = v:getAttribute("level");

		if( type == "WOOD" ) then
			type = NTYPE_WOOD;
		elseif( type == "ORE" ) then
			type = NTYPE_ORE;
		elseif( type == "HERB" ) then
			type = NTYPE_HERB;
		end;

		tmp.Name = name;
		tmp.Id = id;
		tmp.Type = type;
		tmp.Level = level;

		database.nodes[id] = tmp;
	end


	-- UTF-8 -> ASCII translation
	root = xml.open(getExecutionPath() .. "/database/utf8_ascii.xml");
	elements = root:getElements();

	for i,v in pairs(elements) do
		local utf8_1, utf8_2, ascii, dos_replace;
		local tmp = {};

		utf8_1 = v:getAttribute("utf8_1");
		utf8_2 = v:getAttribute("utf8_2");
		ascii = v:getAttribute("ascii");
		dos_replace = v:getAttribute("dos_replace");

--		tmp.Name = name;
		tmp.utf8_1 = utf8_1;
		tmp.utf8_2 = utf8_2;
		tmp.ascii = ascii;
		tmp.dos_replace = dos_replace;

		local key = utf8_1*1000 + utf8_2;
		database.utf8_ascii[key] = tmp;
	end


	-- import consumables (potions, arrows, stones, ...)
	root = xml.open(getExecutionPath() .. "/database/consumables.xml");
	elements = root:getElements();

	for i,v in pairs(elements) do
	    local type, name, level, potency, id;
		local tmp = {};

		type = v:getAttribute("type");
		name = v:getAttribute("name");
		level = v:getAttribute("level");
		potency = v:getAttribute("potency");
		id = v:getAttribute("id");

		if (type) then tmp.Type = type; end;
		if (name) then tmp.Name = name; end;
		if (level) then tmp.Level = level; end;
		if (potency) then
			tmp.Potency = potency;
		else
			tmp.Potency = 0;
		end;
		if (id) then tmp.Id = id; end;

		database.consumables[id] = tmp;
	end

	-- import giftbag contents
	root = xml.open(getExecutionPath() .. "/database/giftbags.xml");
	elements = root:getElements();

	for i,v in pairs(elements) do
	    local itemid, type, armor, level, name;
		local tmp = {};

		itemid = v:getAttribute("itemid");
		type   = v:getAttribute("type");
		armor  = v:getAttribute("armor");
		level  = v:getAttribute("level");
		name   = v:getAttribute("name");

		if (itemid) then tmp.itemid = itemid; end;
		if (type)   then tmp.type   = type;   end;
		if (armor)  then tmp.armor  = armor;  end;
		if (level)  then tmp.level  = level;  end;
		if (name)   then tmp.name   = name;   end;

		database.giftbags[i] = tmp;
	end

end
