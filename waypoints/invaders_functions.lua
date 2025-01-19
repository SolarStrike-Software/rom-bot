-- version 0.5

	keyObjectivesBase = addresses.inventoryBagIds + 0x13C
	keyObjectivesOffset = 0x5
	keyObjectivesSize = 0xc

	targetIds = {
		pirate =		"105140,105144",
		craftsman = 	"117314",
		adventurer = 	"105194,105195,105265",
		player = 		"1000,1001,1002,1003",
	}

	-- Debuffs
	local Bleed = 508573
	local ShakenMoral = 508582
	local InsufferableItch = 508583
	local HandofEarth = 508588
	local BreathofNature = 508591
	local ImpendingDoom = 508707
	local RevolutionarySpirit = 508627

	function getBagsWanted()
		local BagsWanted
		repeat
			cprintf(cli.lightgreen,"\nPlease enter the number of bags you want to get\n")
			printf(" Number of bags> ")
			BagsWanted = io.stdin:read()
			BagsWanted = tonumber(BagsWanted)
			if type(BagsWanted) ~= "number" or 0 > BagsWanted then
				cprintf(cli.yellow,"\nExpecting number more than or equal to 0.\n")
				yrest(2000)
			end
		until type(BagsWanted) == "number" and BagsWanted >= 0

		return BagsWanted
	end

	function getSubQuestId()
		repeat
			local buff = player:getBuff("508564,508565,508566,508567,508568,508569,508570,508571,508572")
			if buff then
				return buff.Id
			else
				yrest(100)
				player:update()
			end
		until false
	end

	-- Returns
	function questComplete()
		return isQuestComplete(423953)
	end

	-- Set up settings and assign the correct action function to "doActions"
	function setupSubQuest()
		-- Restore Potions settings if changed
		if skill2TacticWorks then
			settings.profile.options.HP_LOW_POTION = rememberLastHPSetting
			settings.profile.options.MP_LOW_POTION = rememberLastMPSetting
			settings.profile.options.PHIRIUS_HP_LOW = rememberLastPHPSetting
			settings.profile.options.PHIRIUS_MP_LOW = rememberLastPMPSetting
			skill2TacticWorks = nil
		end

		-- Check sub quest Id
		subQuest = getSubQuestId()
		if subQuest == 508564 then -- Adventurer's chain combat skills
			skills = {
				[1] = {Id=496876, Name="Dagger Throw", CastTime=0, Cooldown=15, Range=200, Target="pirate", MinHpPer=10, MaxHpPer=75, ReqBuff=nil, NoBuff=Bleed, },
				[2] = {Id=496877, Name="Grapple", CastTime=0, Cooldown=15, Range=50, Target="pirate", MinHpPer=nil, MaxHpPer=nil, ReqBuff=Bleed, NoBuff=nil, },
			}
			doActions = quest508564 -- Copy correct actions function.
			path = "Find Pirates" -- The path to use
		elseif subQuest == 508565 then -- Quick Guide to Facility Repair
			skills = { -- Not used
				[1] = {Id=496911, Name="Report to the Experienced Craftsman", CastTime=0, Cooldown=30, Range=40, Target="craftsman", MinHpPer=nil, MaxHpPer=nil, ReqBuff=nil, NoBuff=nil, },
				[2] = {Id=496879, Name="Fixing Technique", CastTime=1, Cooldown=3, Range=40, Target="craftsman", MinHpPer=nil, MaxHpPer=nil, ReqBuff=nil, NoBuff=nil, },
				[3] = {Id=496878, Name="Measuring Technique", CastTime=1, Cooldown=3, Range=40, Target="craftsman", MinHpPer=nil, MaxHpPer=nil, ReqBuff=nil, NoBuff=nil, },
				[4] = {Id=496880, Name="Assembly Technique", CastTime=1, Cooldown=3, Range=40, Target="craftsman", MinHpPer=nil, MaxHpPer=nil, ReqBuff=nil, NoBuff=nil, },
			}
			doActions = quest508565 -- Copy correct actions function.
			path = "Find Craftsmen" -- The path to use
		elseif subQuest == 508566 then -- Ailic's Recruitment Orders
			skills = {
				[1] = {Id=496881, Name="Moral Persuasion", CastTime=1, Cooldown=20, Range=40, Target="pirate", MinHpPer=5, MaxHpPer=50, ReqBuff=nil, NoBuff=nil, },
				[2] = {Id=496886, Name="Out of Pocket", CastTime=0, Cooldown=15, Range=40, Target="pirate", MinHpPer=10, MaxHpPer=nil, ReqBuff=nil, NoBuff=nil, },
				[3] = {Id=496887, Name="Gentle Strike", CastTime=2, Cooldown=15, Range=150, Target="pirate", MinHpPer=5, MaxHpPer=50, ReqBuff=nil, NoBuff=nil, },
			}
			doActions = quest508566 -- Copy correct actions function.
			path = "Find Pirates" -- The path to use
		elseif subQuest == 508567 then -- Heffner's Double-edged Plan
			skills = {
				[1] = {Id=496888, Name="Spread Rumors", CastTime=1, Cooldown=15, Range=40, Target="pirate", MinHpPer=nil, MaxHpPer=nil, ReqBuff=nil, NoBuff=ShakenMoral, },
				[2] = {Id=496889, Name="Itchy All Over", CastTime=0, Cooldown=30, Range=70, Target="pirate", MinHpPer=nil, MaxHpPer=nil, ReqBuff=nil, NoBuff=InsufferableItch, },
				[3] = {Id=496890, Name="Refreshing Powder", CastTime=0, Cooldown=3, Range=70, Target="player,adventurer", MinHpPer=nil, MaxHpPer=nil, ReqBuff=InsufferableItch, NoBuff=nil, },
			}
			doActions = quest508567 -- Copy correct actions function.
			path = "Find Pirates" -- The path to use
		elseif subQuest == 508568 then -- Elves' Power of Nature
			skills = {
				[1] = {Id=496891, Name="Hand of Earth", CastTime=0, Cooldown=60, Range=100, Target="pirate", MinHpPer=nil, MaxHpPer=nil, ReqBuff=nil, NoBuff=HandofEarth, },
				[2] = {Id=496900, Name="Breath of Nature", CastTime=0, Cooldown=3, Range=100, Target="adventurer", MinHpPer=nil, MaxHpPer=nil, ReqBuff=nil, NoBuff=BreathofNature, },
			}
			doActions = quest508568 -- Copy correct actions function.
			path = "Find Pirates" -- The path to use
		elseif subQuest == 508569 then -- Phirius Workshop's Scheme
			skills = {
				[1] = {Id=496901, Name="Give Faux Diamond", CastTime=0, Cooldown=40, Range=40, Target="pirate", MinHpPer=10, MaxHpPer=60, ReqBuff=nil, NoBuff=ImpendingDoom, },
				[2] = {Id=496902, Name="Public Testimony", CastTime=0, Cooldown=5, Range=80, Target="pirate", MinHpPer=nil, MaxHpPer=nil, ReqBuff=ImpendingDoom, NoBuff=nil, },
			}
			doActions = quest508569 -- Copy correct actions function.
			path = "Find Pirates" -- The path to use
		elseif subQuest == 508570 then -- Eye of Wisdom Magic
			skills = {
				[1] = {Id=496903, Name="Exploding Rune Circle", CastTime=0, Cooldown=30, Range=0, Target="none", MinHpPer=nil, MaxHpPer=nil, ReqBuff=nil, NoBuff=nil, },
				[2] = {Id=496904, Name="Stiff Impression", CastTime=0, Cooldown=30, Range=0, Target="none", MinHpPer=nil, MaxHpPer=nil, ReqBuff=nil, NoBuff=nil, },
				[3] = {Id=496905, Name="Energy Shield", CastTime=0, Cooldown=30, Range=0, Target="none", MinHpPer=nil, MaxHpPer=nil, ReqBuff=nil, NoBuff=nil, },
			}
			doActions = quest508570 -- Copy correct actions function.
			path = "Find Pirates" -- The path to use
		elseif subQuest == 508571 then -- I was born to research
			skills = {
				[1] = {Id=496906, Name="Live Samples", CastTime=0, Cooldown=0, Range=40, Target="pirate", MinHpPer=5, MaxHpPer=50, ReqBuff=nil, NoBuff=nil, },
				[2] = {Id=496907, Name="Ailic's Forte", CastTime=0, Cooldown=15, Range=0, Target="none", MinHpPer=nil, MaxHpPer=nil, ReqBuff=nil, NoBuff=nil, },
				[3] = {Id=496908, Name="Deliver the Sample", CastTime=0, Cooldown=15, Range=0, Target="none", MinHpPer=nil, MaxHpPer=nil, ReqBuff=nil, NoBuff=nil, },
			}
			doActions = quest508571 -- Copy correct actions function.
			path = "Find Pirates" -- The path to use
		elseif subQuest == 508572 then -- Adventurer Camaraderie
			skills = {
				[1] = {Id=496909, Name="Hang in there, brother!", CastTime=0, Cooldown=15, Range=100, Target="adventurer", MinHpPer=20, MaxHpPer=50, ReqBuff=nil, NoBuff=RevolutionarySpirit, },
				[2] = {Id=496910, Name="Leave Me Alone! Go Away!", CastTime=0, Cooldown=60, Range=150, Target="adventurer", MinHpPer=nil, MaxHpPer=nil, ReqBuff=nil, NoBuff=nil, },
			}

			-- Test skill2 tactic
			originalequipement = RoMScript("GetEuipmentNumber()")

			local count = RoMScript("CharactFrame_GetEquipSlotCount();")
			local hplevels = {}
			for i = 1,count do
				RoMScript("SwapEquipmentItem("..(i - 1)..");") yrest(2000)
				player:update()
				hplevels[i] = player.MaxHP
			end
			skill2TacticWorks = false
			for a = 1, #hplevels - 1 do -- for each hp (not including the last)
				for b = a + 1, #hplevels do -- compare against the rest
					if hplevels[b] > hplevels[a]*2 then
						skill2TacticWorks = true
						firstswap = a; secondswap = b
						break
					elseif hplevels[a] > hplevels[b]*2 then
						skill2TacticWorks = true
						firstswap = b; secondswap = a
						break
					end
				end
			end
			if skill2TacticWorks then
				rememberLastHPSetting = settings.profile.options.HP_LOW_POTION
				rememberLastMPSetting = settings.profile.options.MP_LOW_POTION
				rememberLastPHPSetting = settings.profile.options.PHIRIUS_HP_LOW
				rememberLastPMPSetting = settings.profile.options.PHIRIUS_MP_LOW
				settings.profile.options.HP_LOW_POTION = 0
				settings.profile.options.MP_LOW_POTION = 0
				settings.profile.options.PHIRIUS_HP_LOW = 0
				settings.profile.options.PHIRIUS_MP_LOW = 0
			end
			RoMScript("SwapEquipmentItem("..(originalequipement - 1)..")")

			doActions = quest508572 -- Copy correct actions function.
			path = "Find Pirates" -- The path to use
		else
			error(string.format("Sub quest id %d not found. Name \"%s\"\n",subQuest, GetIdName(subQuest)))
		end

		-- Count extra action button to make sure there weren't existing buttons. If so, set offset.
		actionOffset = RoMCode("a=0 while GetExtraActionInfo(a+1)~=nil do a=a+1 end") - #skills

		cprintf(cli.yellow,"Doing subquest \"%s\".\n",GetIdName(subQuest))
	end

	function checkQuest()
		if questComplete() then
			__WPL:setDirection(WPT_BACKWARD)
			return
		end
		doActions()
		if questComplete() and subQuest ~= 508571 then
			__WPL:setDirection(WPT_BACKWARD)
		end
	end

	function skillCanUse(skill)
		targetpawn:update()
		-- Is target still valid
		if targetpawn.Id == 0 then
			return
		end

		-- Is dead
		if not targetpawn.Alive or targetpawn.HP == 0 then
			return
		end

		-- wrong target
		local match = false
		for id in string.gmatch(skill.Target,"[^,]+") do
			if string.find(targetIds[id], targetpawn.Id) then
				match = true
				break
			end
		end
		if not match then
			return
		end

		if InvadersDebug then
			print("Trying to cast "..skill.Name)
		end

		-- On cooldown?
		if skill.Cooldown and skill.LastCastTime and skill.Cooldown > os.clock() - skill.LastCastTime then
			if InvadersDebug then
				print("\tOn cooldown")
			end
			return
		end

		-- Has minimum hp percent?
		if skill.MinHpPer and skill.MinHpPer > targetpawn.HP/targetpawn.MaxHP*100 then
			if InvadersDebug then
				print("\tNot enough HP")
			end
			return
		end

		-- Has maximum hp percent?
		if skill.MaxHpPer and targetpawn.HP/targetpawn.MaxHP*100 > skill.MaxHpPer then
			if InvadersDebug then
				print("\tToo much HP")
			end
			return
		end

		-- Has required buff?
		if skill.ReqBuff and not targetpawn:hasBuff(skill.ReqBuff) then
			if InvadersDebug then
				print("\tDoesn't have buff")
			end
			return
		end

		-- Has non-required buff?
		if skill.NoBuff and targetpawn:hasBuff(skill.NoBuff) then
			if InvadersDebug then
				print("\tHas buff")
			end
			return
		end

		cprintf(cli.yellow, "Casting \"%s\".\n",skill.Name)

		return true
	end

	function quest508564()
		local range = 70

		local objectList = CObjectList();
		objectList:update();
		local objSize = objectList:size()

		for i = 0,objSize do
			local obj = objectList:getObject(i);
			if range > distance(player.X, player.Z, obj.X, obj.Z) then -- In range
				targetpawn = CPawn(obj.Address)

				for k = 1, #skills do
					skill = skills[k]
					if skillCanUse(skill) then
						player:target(targetpawn)
						player:moveTo(targetpawn,true,nil,skill.Range)
						yrest(200)
						RoMScript("UseExtraAction(".. k+actionOffset ..")")
						yrest(skill.CastTime * 1000)
						skill.LastCastTime = os.clock()
						yrest(1000)
						player:update()
						targetpawn:update()
					end
				end
			end
		end
	end

	function quest508565()
		--if corner == nil then corner = 1 end
		local craftsman
		repeat
			-- Look for Craftsman
			craftsman = player:findNearestNameOrId(targetIds.craftsman)
			if craftsman and 20 > distance(craftsman.X, craftsman.Z, player.X, player.Z) then
				-- Correct craftsman found
				break
			end
			yrest(3000)
			-- Try again
			craftsman = player:findNearestNameOrId(targetIds.craftsman)
			if craftsman and 20 > distance(craftsman.X, craftsman.Z, player.X, player.Z) then
				-- Correct craftsman found
				break
			end
			corner = corner + 1; if corner > 4 then corner = 1 end
			player:moveTo(CWaypoint(corners[corner].X, corners[corner].Z), true)
		until false

		-- Craftsman found. Target.
		player:target(craftsman)
		yrest(200)
		RoMScript("UseExtraAction(".. 1+actionOffset ..")")
		LastCastTime = os.clock()
		yrest(1500)

		--Setup chat monitor.
		EventMonitorStop("CraftsmanSaid");
		EventMonitorStart("CraftsmanSaid", "CHAT_MSG_SYSTEM");

		-- Check monitor while following craftsman.
		local nextCraftsman = false
		repeat
			player:update()
			craftsman:update()
			if nextCraftsman then
				if corner == 1 or corner == 4 then
					break
				else
					corner = corner + 1
					player:moveTo(CWaypoint(corners[corner].X, corners[corner].Z), true)
				end
			elseif distance(player.X, player.Z, craftsman.X, craftsman.Z) > 40 then
				-- Craftsman moved. Move to next corner.
				corner = corner + 1; if corner > 4 then corner = 1 end
				player:moveTo(CWaypoint(corners[corner].X, corners[corner].Z), true)
				yrest(1000)
			else
				-- Check chat messages
				repeat
					local time, moreToCome, name, msg = EventMonitorCheck("CraftsmanSaid", "4,1")
					if time ~= nil then
						if string.find(msg, RoMScript("TEXT(\"SC_PE_ZONE13_01_SMITH02\")"),1,true) then -- Fix that end!
							RoMScript("UseExtraAction(".. 2+actionOffset ..")") yrest(1500)
						elseif string.find(msg, RoMScript("TEXT(\"SC_PE_ZONE13_01_SMITH01\")"),1,true) then -- It's time to measure that distance!
							RoMScript("UseExtraAction(".. 3+actionOffset ..")") yrest(1500)
						elseif string.find(msg, RoMScript("TEXT(\"SC_PE_ZONE13_01_SMITH03\")"),1,true) then -- Good! Assemble it!
							RoMScript("UseExtraAction(".. 4+actionOffset ..")") yrest(1500)
						elseif string.find(msg, RoMScript("TEXT(\"SC_PE_ZONE13_01_SMITH04\")"),1,true) or -- failed
							   string.find(msg, RoMScript("TEXT(\"SC_PE_ZONE13_01_SMITH05\")"),1,true) then -- succeeded
							-- Move to next Craftsman
							nextCraftsman = true
						end
					end
				until moreToCome ~= true
			end
			yrest(1000)
		until false

		if LastCastTime and 30 > os.clock()-LastCastTime then
			-- Wait for cooldown
			yrest((30 + os.clock()-LastCastTime)*1000)
		end
	end

	function quest508566()
		local range = 70

		local objectList = CObjectList();
		objectList:update();
		local objSize = objectList:size()

		for i = 0,objSize do
			local obj = objectList:getObject(i);
			if range > distance(player.X, player.Z, obj.X, obj.Z) then -- In range
				targetpawn = CPawn(obj.Address)

				for k = 1, #skills do
					skill = skills[k]
					if skillCanUse(skill) then
						player:target(targetpawn)
						player:moveTo(targetpawn,true,nil,skill.Range)
						yrest(200)
						RoMScript("UseExtraAction(".. k+actionOffset ..")")
						yrest(skill.CastTime * 1000)
						skill.LastCastTime = os.clock()
						yrest(1000)
						if k == 2 then
							RoMScript("ChoiceListDialogOption(4)")
							yrest(1000)
						end
						player:update()
						if player.Battling then
							player:fight()
						end
						targetpawn:update()
					end
				end
			end
		end
	end

	function quest508567()
		local range = 70

		local objectList = CObjectList();
		objectList:update();
		local objSize = objectList:size()

		for i = 0,objSize do
			local obj = objectList:getObject(i);
			if range > distance(player.X, player.Z, obj.X, obj.Z) then -- In range
				targetpawn = CPawn(obj.Address)

				for k = 1, #skills do
					skill = skills[k]
					if skillCanUse(skill) then
						player:target(targetpawn)
						player:moveTo(targetpawn,true,nil,skill.Range)
						yrest(200)
						RoMScript("UseExtraAction(".. k+actionOffset ..")")
						yrest(skill.CastTime * 1000)
						skill.LastCastTime = os.clock()
						yrest(1000)
						player:update()
						if player.Battling then
							player:fight()
						end
						targetpawn:update()
					end
				end
			end
		end
	end

	function quest508568()
		local range = 70

		local objectList = CObjectList();
		objectList:update();
		local objSize = objectList:size()

		for i = 0,objSize do
			local obj = objectList:getObject(i);
			if range > distance(player.X, player.Z, obj.X, obj.Z) then -- In range
				targetpawn = CPawn(obj.Address)

				if skills[1].LastCastTime == nil or os.clock() - skills[1].LastCastTime > skills[1].Cooldown then
					k = 1
				else
					k = 2
				end
				skill = skills[k]

				if skillCanUse(skill) then
					player:target(targetpawn)
					player:moveTo(targetpawn,true,nil,skill.Range)
					yrest(200)
					RoMScript("UseExtraAction(".. k+actionOffset ..")")
					yrest(skill.CastTime * 1000)
					skill.LastCastTime = os.clock()
					yrest(1000)
					if k == 2 and skills[1].LastCastTime then
						skills[1].LastCastTime = skills[1].LastCastTime - 20
					end
					targetpawn:update()
				end
			end
		end
	end

	function quest508569()
		local range = 70

		local objectList = CObjectList();
		objectList:update();
		local objSize = objectList:size()

		-- Cast Impending Doom
		for i = 0,objSize do
			local obj = objectList:getObject(i);
			if range > distance(player.X, player.Z, obj.X, obj.Z) then -- In range
				targetpawn = CPawn(obj.Address)

				skill = skills[1]
				if skillCanUse(skill) then
					player:target(targetpawn)
					player:moveTo(targetpawn,true,nil,skill.Range)
					yrest(200)
					RoMScript("UseExtraAction(".. 1+actionOffset ..")")
					skill.LastCastTime = os.clock()
					yrest(1000)
					targetpawn:update()
					break
				end
			end
		end

		-- Keep searching for sufferers of Impeding Doom until none left
		while targetpawn:hasBuff(skills[1].NoBuff) and targetpawn.Alive do
			-- Is still in Cooldown?
			if skills[2].LastCastTime == nil or (os.clock() - skills[2].LastCastTime > skills[2].Cooldown) then
				player:target(targetpawn)
				player:moveTo(targetpawn,true,nil,skills[2].Range)
				yrest(200)
				cprintf(cli.yellow, "Casting \"%s\".\n",skills[2].Name)
				RoMScript("UseExtraAction(".. 2+actionOffset ..")")
				skills[2].LastCastTime = os.clock()
			end
			yrest(500)

			targetpawn:update()

			-- See if it's dead. Look for another.
			if not targetpawn:hasBuff(skills[1].NoBuff) or not targetpawn.Alive then -- look for another mob with Impenting doom
				if questComplete() then
					return
				end

				objectList:update();
				local objSize = objectList:size()
				range = 150
				for i = 0,objSize do
					local obj = objectList:getObject(i);
					if range > distance(player.X, player.Z, obj.X, obj.Z) then -- In range
						targetpawn = CPawn(obj.Address)

						if targetpawn:hasBuff(skills[1].NoBuff) and targetpawn.Alive then
							break
						end
					end
				end
			end
		end
	end

	function quest508570()
		local range = 150

		local objectList = CObjectList();
		objectList:update();
		local objSize = objectList:size()

		-- Count pirates in range
		local count = 0
		for i = 0,objSize do
			local obj = objectList:getObject(i);
			if range > distance(player.X, player.Z, obj.X, obj.Z) then -- In range
				targetpawn = CPawn(obj.Address)

				if string.find(targetIds.pirate, targetpawn.Id) and -- Is Pirate
				   targetpawn.Alive and targetpawn.HP > 0 then -- Is alive
					count = count + 1
				end
			end
		end

		if count > 4 then
			yrest(200)
			cprintf(cli.yellow, "Casting \"%s\".\n",skills[3].Name)
			LastCastTime = os.clock()
			RoMScript("UseExtraAction(".. 3+actionOffset ..")")
			yrest(1000)
			cprintf(cli.yellow, "Casting \"%s\".\n",skills[1].Name)
			RoMScript("UseExtraAction(".. 1+actionOffset ..")")
			yrest(1000)
			cprintf(cli.yellow, "Casting \"%s\".\n",skills[2].Name)
			RoMScript("UseExtraAction(".. 2+actionOffset ..")")
			yrest(8000)
			player:update()
			while player.Battling do
				player:target(player:findEnemy(true))
				player:fight()
				player:update()
			end

			if not questComplete() then
				local toWait = 31 - (os.clock() - LastCastTime)
				if toWait > 0 then
					yrest(toWait*1000)
				end
			end
		end
	end

	function quest508571()
		local range = 70

		local objectList = CObjectList();
		objectList:update();
		local objSize = objectList:size()

		for i = 0,objSize do
			local obj = objectList:getObject(i);
			if range > distance(player.X, player.Z, obj.X, obj.Z) then -- In range
				targetpawn = CPawn(obj.Address)

				skill = skills[1]

				if skillCanUse(skill) then
					player:target(targetpawn)
					player:moveTo(targetpawn,true,nil,skill.Range)
					yrest(200)
					RoMScript("UseExtraAction(".. 1+actionOffset ..")")
					yrest(700)
					cprintf(cli.yellow, "Casting \"%s\".\n",skills[2].Name)
					RoMScript("UseExtraAction(".. 2+actionOffset ..")")
					yrest(2000)
					cprintf(cli.yellow, "Casting \"%s\".\n",skills[3].Name)
					local startTimer = getTime()
					repeat
						SlashCommand("/script UseExtraAction(".. 3+actionOffset ..")")
						yrest(200)
						player:update()
						if deltaTime(getTime(), startTimer) > 10000 then -- Give up after 10s
							return
						end
					until 5 > distance(player.X,player.Z,-7526,-4226) and not player:hasBuff(508623) -- Fresh Sample
					yrest(2000)
					player:update()
					__WPL:setDirection(WPT_FORWARD)
					__WPL:setWaypointIndex(__WPL:getNearestWaypoint(player.X, player.Z, player.Y))
					break
				end
			end
		end
	end

	function quest508572()
		local range = 70

		local objectList = CObjectList();
		objectList:update();
		local objSize = objectList:size()

		if skill2TacticWorks and
		   (skills[2].LastCastTime == nil or (os.clock() - skills[2].LastCastTime > skills[2].Cooldown)) then
			player:update()
			if player.HP*2 > player.MaxHP then
				RoMScript("SwapEquipmentItem("..(firstswap - 1)..")") yrest(2000)
				RoMScript("SwapEquipmentItem("..(secondswap - 1)..")") yrest(2000)
			end
			cprintf(cli.yellow, "Casting \"%s\".\n",skills[2].Name)
			RoMScript("UseExtraAction(".. 2+actionOffset ..")")
			skills[2].LastCastTime = os.clock()
			yrest(500)
			if secondswap ~= originalequipement then RoMScript("SwapEquipmentItem("..(originalequipement - 1)..")") end
		end

		for i = 0,objSize do
			local obj = objectList:getObject(i);
			if range > distance(player.X, player.Z, obj.X, obj.Z) then -- In range
				targetpawn = CPawn(obj.Address)

				skill = skills[1]

				if skillCanUse(skill) then
					player:target(targetpawn)
					player:moveTo(targetpawn,true,nil,skill.Range)
					yrest(200)
					RoMScript("UseExtraAction(".. 1+actionOffset ..")")
					skill.LastCastTime = os.clock()

					-- Try and heal NPC
					targetpawn.Type = 1
					for i,v in pairs(settings.profile.skills) do
						if (v.AutoUse and v:canUse(true, targetpawn) ) and
						   (v.Type == STYPE_HEAL or v.Type == STYPE_HOT) and
						   (v.Target == STARGET_FRIENDLY) then
							printf("Casting %s on NPC.\n",v.Name)
							player:target(targetpawn)
							yrest(500)
							v:use()
							yrest(500)
							repeat
								player:update()
								yrest(50)
							until not player.Casting
							break
						end
					end

					yrest(700)
					break
				end
			end
		end
	end
