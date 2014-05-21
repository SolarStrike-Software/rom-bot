local fairy_db = {
[CLASS_WARRIOR]	= {PetId = 102104, PetSummon = 493267, Buff = 503455}, -- Fire Fairy - Accuracy Halo
[CLASS_SCOUT]	= {PetId = 102105, PetSummon = 493268, Buff = 503736}, -- Water Fairy - Frost Halo
[CLASS_ROGUE]	= {PetId = 102106, PetSummon = 493269, Buff = 503459}, -- Shadow Fairy - Wraith Halo
[CLASS_MAGE]	= {PetId = 102107, PetSummon = 493270, Buff = 503461}, -- Wind Fairy - WindRider Halo
[CLASS_KNIGHT]	= {PetId = 102108, PetSummon = 493271, Buff = 503507}, -- Light Fairy - Devotion Halo
}

function setpettable()
	pettable = {
		[1] = {
		name = GetIdName(102297), -- spirit of the oak
		skillid = 493333,
		skill5name = "PUNCH",
		skill5auto = "true",
		skill6name = "ENTANGLE",
		skill6auto = "false"},

		[2] = {
		name = GetIdName(102325), -- nature crystal
		skillid = 493344,
		skill5name = "PROTECTION",
		skill5auto = "true",
		skill6name = "ACCELERATION",
		skill6auto = "true"},

		[3] = {
		name = GetIdName(102324), -- oak walker
		skillid = 493343,
		skill5name = "STAB",
		skill5auto = "true",
		skill6name = "INTERFERENCE",
		skill6auto = "false"},

		[4] = {
		name = GetIdName(102803), -- chiron the centaur
		skillid = 494212,
		skill5name = "CENTAURS_ARROW",
		skill5auto = "true",
		skill6name = "VALIANT_SHOT",
		skill6auto = "true"}
	}
end

function setpetautoattacks()
	petupdate()
	--=== set pet to counter attack except for nature crystal
	local icon,active,autoCastAllowed = RoMScript("GetPetActionInfo(4)")
	if pet.Name ~= GetIdName(102325) then
		if active ~= true then
			RoMCode("UsePetAction(4)")
		end
	else
		if active == true then
			RoMCode("UsePetAction(4)")
		end
	end

	for k,v in pairs(pettable) do
		if v.name == pet.Name then
			if v.skill5auto == "true" then
				local icon,active,autoCastAllowed = RoMScript("GetPetActionInfo(5)")
				if active ~= true then
					RoMCode("UsePetAction(5,true)")
				end
			end
			if v.skill5auto == "true" then
				local icon,active,autoCastAllowed = RoMScript("GetPetActionInfo(6)")
				if active ~= true then
					RoMCode("UsePetAction(6,true)")
				end
			end
		end
	end
end

function petupdate()
	petaddress = memoryReadRepeat("uint", getProc(), player.Address + addresses.pawnPetPtr_offset);
	pet = CPawn(petaddress)
	setpettable()
end

function wardenbuff(_nameorid)
	return
	--no longer needed.
--[[
	keyboardRelease(settings.hotkeys.MOVE_FORWARD.key);
	petupdate()
	local buffid
	if type(_nameorid) == "number" then
		buffname = GetIdName(_nameorid)
	else
		if string.find(string.lower(_nameorid), "spirit" ) or
			string.find(string.lower(_nameorid), "heart" ) then
			buffname = GetIdName(503946)
		elseif string.find(string.lower(_nameorid), "nature") then
			buffname = GetIdName(503581)
		elseif string.find(string.lower(_nameorid), "walker") then
			buffname = GetIdName(503580)
		else
			error("Unrecognized name for warden pet buff.")
		end
	end
	petupdate()

	-- Check if already have the buff
	if player:getBuff(buffname) then
		return
	end

	local function summonbuff()
		if not player.Battling then
			if buffname == GetIdName(503946) then
				RoMScript("CastSpellByName(\""..GetIdName(493333).."\");");
				print("Summoning "..GetIdName(102297))
				repeat
				yrest(1000)
				player:update()
				until not player.Casting
				RoMScript("CastSpellByName(\""..GetIdName(493346).."\")")
				print("Casting Buff: "..GetIdName(503946))
			end
			if buffname == GetIdName(503581) then
				RoMScript("CastSpellByName(\""..GetIdName(493344).."\");");
				print("Summoning "..GetIdName(102325))
				repeat
				yrest(1000)
				player:update()
				until not player.Casting
				RoMScript("CastSpellByName(\""..GetIdName(493348).."\")")
				print("Casting Buff: "..GetIdName(503581))
			end
			if buffname == GetIdName(503580) then
				RoMScript("CastSpellByName(\""..GetIdName(493343).."\");");
				print("Summoning "..GetIdName(102324))
				repeat
				yrest(1000)
				player:update()
				until not player.Casting
				RoMScript("CastSpellByName(\""..GetIdName(493347).."\")")
				print("Casting Buff: "..GetIdName(503580))
			end
		end
	end
	if pet.Name ~= "<UNKNOWN>" then -- pet summoned
		if pet.Name == GetIdName(102297) and buffname == GetIdName(503946) then
			RoMScript("CastSpellByName(\""..GetIdName(493346).."\")")
		elseif pet.Name == GetIdName(102325) and buffname == GetIdName(503581) then
			RoMScript("CastSpellByName(\""..GetIdName(493348).."\")")
		elseif pet.Name == GetIdName(102324) and buffname == GetIdName(503580) then
			RoMScript("CastSpellByName(\""..GetIdName(493347).."\")")
		else
			RoMScript("CastSpellByName(\""..GetIdName(493645).."\")") -- recall pet
			yrest(1300)
			summonbuff()
		end
	else
		summonbuff()
	end
	PetWaitTimer = 1 -- So it immediately resummons assist pet if used.
	]]
end

function petstartcombat()
	petupdate()
	if pet.Name == GetIdName(102325) then
		if _printed == nil then
			print("Nature Crystal Doesn't attack")
			_printed = true
		end
	else
		RoMCode("UsePetAction(3)")
		print("Making Pet Attack")
	end
end

function checkfairy()
	local fairy = fairy_db[player.Class2]

	if player.Class1 ~= CLASS_PRIEST or fairy == nil then
		return -- can't have a water fairy if class is wrong
	end

	if  player.Mounted then
		return
	end

	petupdate()
	if pet.Id ~= fairy.PetId then -- Fairy
		if PetWaitTimer == nil or PetWaitTimer == 0 then -- Start timer
			PetWaitTimer = os.time()
			return false
		elseif os.time() - PetWaitTimer < 15 then -- Wait longer
			return false
		end

		keyboardRelease(settings.hotkeys.MOVE_FORWARD.key); yrest(500)
		sendMacro("CastSpellByName(\""..GetIdName(fairy.PetSummon).."\")")
		print("Summoning "..GetIdName(fairy.PetId))
		repeat
			yrest(1000)
		until not (memoryReadRepeat("int", getProc(), player.Address + addresses.pawnCasting_offset) ~= 0);

		petupdate()
		local icon,active,autoCastAllowed = RoMScript("GetPetActionInfo(4)")
		if active == true then
			sendMacro("UsePetAction(4)")
		end
		player.LastDistImprove = os.time();   -- global, because we reset it while skill use
	else
		PetWaitTimer = 0
	end

	if not pet:hasBuff(fairy.Buff) then -- Frost Halo, Accuracy Halo...
		sendMacro("UsePetAction(5)")
		yrest(500)
	end
	if not pet:hasBuff(503753) then -- Conceal
		sendMacro("UsePetAction(6)")
		yrest(500)
	end
end

