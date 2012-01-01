
pettable = {
	[1] = {
	name = GetIdName(102297), -- spirit of the oak
	skillid = 493333,
	skill6name = "PUNCH",
	skill6auto = "true",
	skill7name = "ENTANGLE",
	skill7auto = "false"},

	[2] = {
	name = GetIdName(102325), -- nature crystal
	skillid = 493344,
	skill6name = "PROTECTION",
	skill6auto = "true",
	skill7name = "ACCELERATION",
	skill7auto = "true"},

	[3] = {
	name = GetIdName(102324), -- oak walker
	skillid = 493343,
	skill6name = "STAB",
	skill6auto = "true",
	skill7name = "INTERFERENCE",
	skill7auto = "false"},
	
	[4] = {
	name = GetIdName(102803), -- chiron the centaur
	skillid = 494212,
	skill6name = "CENTAURS_ARROW",
	skill6auto = "true",
	skill7name = "VALIANT_SHOT",
	skill7auto = "true"}
}

function setpetautoattacks()
	petupdate()
	--=== set pet to counter attack except for nature crystal
	local icon,active,autoCastAllowed = RoMScript("GetPetActionInfo(5)")
	if pet.Name ~= GetIdName(102325) then	
		if active ~= true then
			RoMScript("UsePetAction(5)")
		end
	else
		if active == true then
			RoMScript("UsePetAction(5)")
		end
	end
	
	for k,v in pairs(pettable) do
		if v.name == pet.Name then
			if v.skill6auto == "true" then
				local icon,active,autoCastAllowed = RoMScript("GetPetActionInfo(6)")
				if active ~= true then
					RoMScript("UsePetAction(6,true)")
				end
			end
			if v.skill7auto == "true" then
				local icon,active,autoCastAllowed = RoMScript("GetPetActionInfo(7)")
				if active ~= true then
					RoMScript("UsePetAction(7,true)")
				end
			end
		end
	end
end

function petupdate()
	petaddress = memoryReadRepeat("uint", getProc(), player.Address + addresses.pawnPetPtr_offset);
	pet = CPawn(petaddress)
	pet:update()
end

function wardenbuff(_nameorid)
	keyboardRelease(settings.hotkeys.MOVE_FORWARD.key);
	petupdate()
	local buffid
	if type(_nameorid) == "number" then
		buffid = _nameorid
	else
		if string.find(string.lower(_nameorid), "spirit" ) or
			string.find(string.lower(_nameorid), "heart" ) then
			buffid = 503946
		elseif string.find(string.lower(_nameorid), "nature") then
			buffid = 503581
		elseif string.find(string.lower(_nameorid), "walker") then
			buffid = 503580
		else 
			error("Unrecognized name for warden pet buff.")
		end
	end
	petupdate()
	local function summonbuff()
		if not player.Battling then
			if buffid == 503946 and not player:hasBuff(503946) then
				RoMScript("CastSpellByName(\""..GetIdName(493333).."\");");
				print("Summoning "..GetIdName(102297))
				repeat
				yrest(1000)
				player:update()
				until not player.Casting
				RoMScript("CastSpellByName(\""..GetIdName(493346).."\")")
				print("Casting Buff: "..GetIdName(503946))
			end
			if buffid == 503581 and not player:hasBuff(503581) then
				RoMScript("CastSpellByName(\""..GetIdName(493344).."\");");
				print("Summoning "..GetIdName(102325))
				repeat
				yrest(1000)			
				player:update()
				until not player.Casting
				RoMScript("CastSpellByName(\""..GetIdName(493348).."\")")
				print("Casting Buff: "..GetIdName(503581))				
			end		
			if buffid == 503580 and not player:hasBuff(503580) then
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
		if pet.Name == GetIdName(102297) and buffid == 503946 then
			RoMScript("CastSpellByName(\""..GetIdName(493346).."\")")
		elseif pet.Name == GetIdName(102325) and buffid == 503581 then
			RoMScript("CastSpellByName(\""..GetIdName(493348).."\")")
		elseif pet.Name == GetIdName(102324) and buffid == 503580 then
			RoMScript("CastSpellByName(\""..GetIdName(493347).."\")")
		else
			RoMScript("CastSpellByName(\""..GetIdName(493645).."\")") -- recall pet
			yrest(1300)
			summonbuff()
		end
	else
		summonbuff()
	end
end

function petstartcombat()
	petupdate()
	if pet.Name == GetIdName(102803) then
		RoMScript("UsePetAction(6)")
		print("Making Pet Attack")
		yrest(500)
		RoMScript("UsePetAction(7)")
		yrest(500)
		RoMScript("UsePetAction(3)")
	elseif pet.Name == GetIdName(102325) then
		if _printed == nil then
			print("Nature Crystal Doesn't attack")
			_printed = true
		end
	else
		RoMScript("UsePetAction(3)")
		print("Making Pet Attack")
	end
end

function waterfairy()
	if player.Class1 ~= CLASS_PRIEST or player.Class2 ~= CLASS_SCOUT then
		return -- can't have a water fairy if class is wrong
	end
	petupdate()
	if pet.Name ~= GetIdName(102105) then
		RoMScript("CastSpellByName(\""..GetIdName(493268).."\")")
		print("Summoning "..GetIdName(102105))
		repeat
		yrest(1000)
		player:update()
		until not player.Casting
	end
	player:update()
	if not player:hasBuff(503736) then
		if _timess == nil or os.time() - _timess > 20 then
			RoMScript("UsePetAction(6)")
			_timess = os.time()
		end
	end
	petupdate()
	local hasbuffconceal = false
	for k,v in pairs(pet.Buffs) do
		if v.Name == GetIdName(503753) then
			hasbuffconceal = true
		end
	end
	if hasbuffconceal == false then
		RoMScript("UsePetAction(7)")
	end
	local icon,active,autoCastAllowed = RoMScript("GetPetActionInfo(5)")
	if active == true then
		RoMScript("UsePetAction(5)")
	end
end