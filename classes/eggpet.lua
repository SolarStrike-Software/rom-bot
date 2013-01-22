local CRAFT_TOOLS = { Mining = 204228, Woodworking = 204232, Herbalism = 204230} -- Small Hoe, Small Hatchet, Small Spade
local CRAFT_INDEX_LEVELS = {
	[1] = 1,
	[2] = 8,
	[3] = 11,
	[4] = 14,
	[5] = 20,
	[6] = 26,
	[7] = 31,
	[8] = 32,
	[9] = 38,
	[10] = 41,
	[11] = 44,
	[12] = 50,
	[13] = 56,
	[14] = 61,
}

local FOOD_LEVLES = {
	[204791] = 5, -- CAKE
	[204925] = 10, -- CHEESE
	[204924] = 20, -- MILK
	[204234] = 30, -- BEEF
	[204510] = 1, -- Desert of Happiness
	[204511] = 10, -- Favorite Meal
}

local petInfoInstalled = nil

CEggPet = class(
	function (self, eggSlot)
		self.EggSlot = eggSlot
		self.Name = ""
		self.Available = false
		self.EggId = 0
		self.PetId = 0
		self.Level = 0
		self.Crafting = false
		self.Summoned = false
		self.Exp = 0
		self.MaxExp = 0
		self.TP = 0
		self.MaxTP = 0
		self.Loyalty = 0
		self.Nourishment = 0
		self.Aptitude = 0
		self.Training = 0
		self.Str = 0
		self.Sta = 0
		self.Dex = 0
		self.Int = 0
		self.Wis = 0
		self.Skills = {}
		self.Mining = 0
		self.Woodworking = 0
		self.Herbalism = 0
		self.Tool = {}
		self.Products = {}

		if eggSlot ~= nil and eggSlot ~= 0 then
			self:update()
		end
	end
)

function CEggPet:update()
	if self.EggSlot and self.EggSlot > 0 then
		eggPetAddress = addresses.eggPetBaseAddress + 0x348 * (self.EggSlot - 1)
	else
		printf("Egg pet not updated. Invalid EggSlot specified.\n")
		return
	end

	if self.EggSlot > 2 then
		self.Available = memoryReadUInt(getProc(), addresses.rentEggSlotBase + (self.EggSlot - 3) * 4) ~= 0xFFFFFFFF
	else
		self.Available = true
	end

	self.EggId = memoryReadInt(getProc(), eggPetAddress + addresses.eggPetEggId_offset)
	if self.EggId ~= nil and self.EggId > 0 and self.Available then -- There is an egg pet
		self.PetId = memoryReadInt(getProc(), eggPetAddress + addresses.eggPetPetId_offset)
		self.Name = memoryReadString(getProc(), eggPetAddress)
		if self.Name == "" then self.Name = GetIdName(self.PetId) end
		self.Level = memoryReadInt(getProc(), eggPetAddress + addresses.eggPetLevel_offset)
		self.Summoned = (memoryReadInt(getProc(), eggPetAddress + addresses.eggPetSummoned_offset) == 2)
		self.Exp = memoryReadInt(getProc(), eggPetAddress + addresses.eggPetExp_offset)
		self.MaxExp = memoryReadIntPtr(getProc(), addresses.eggPetMaxExpTablePtr, 0x4 * self.Level)
		self.TP = memoryReadInt(getProc(), eggPetAddress + addresses.eggPetTP_offset)
		self.MaxTP = memoryReadInt(getProc(), eggPetAddress + addresses.eggPetMaxTP_offset)
		self.Loyalty = memoryReadInt(getProc(), eggPetAddress + addresses.eggPetLoyalty_offset)
		self.Nourishment = memoryReadInt(getProc(), eggPetAddress + addresses.eggPetNourishment_offset)
		self.Aptitude = memoryReadFloat(getProc(), eggPetAddress + addresses.eggPetAptitude_offset)
		self.Training = memoryReadInt(getProc(), eggPetAddress + addresses.eggPetTraining_offset)
		self.Str = memoryReadFloat(getProc(), eggPetAddress + addresses.eggPetStr_offset)
		self.Sta = memoryReadFloat(getProc(), eggPetAddress + addresses.eggPetSta_offset)
		self.Dex = memoryReadFloat(getProc(), eggPetAddress + addresses.eggPetDex_offset)
		self.Int = memoryReadFloat(getProc(), eggPetAddress + addresses.eggPetInt_offset)
		self.Wis = memoryReadFloat(getProc(), eggPetAddress + addresses.eggPetWis_offset)
		self.Skills = {}
		local skillBase = eggPetAddress + addresses.eggPetSkills_offset
		for i = 0, 7 do
			local id = memoryReadInt(getProc(), skillBase + 0x8 * i)
			if id and id > 0 then
				self.Skills[i+1] = {}
				self.Skills[i+1].Id = id
				self.Skills[i+1].Name = GetIdName(id)
				self.Skills[i+1].Level = memoryReadInt(getProc(), skillBase + 0x8 * i + 0x4) + 1
			end
		end
		self.Mining = memoryReadFloat(getProc(), eggPetAddress + addresses.eggPetMining_offset)
		self.Woodworking = memoryReadFloat(getProc(), eggPetAddress + addresses.eggPetWoodworking_offset)
		self.Herbalism = memoryReadFloat(getProc(), eggPetAddress + addresses.eggPetHerbalism_offset)
		self.Tool = {}
		local toolId = memoryReadInt(getProc(), eggPetAddress + addresses.eggPetToolId_offset)
		if toolId ~= nil and toolId > 0 then
			self.Tool.Id = toolId
			self.Tool.Name = GetIdName (toolId)
			self.Crafting = (memoryReadInt(getProc(), eggPetAddress + addresses.eggPetCrafting_offset) == 10)
		else
			self.Crafting = false
		end
		self.Products = {}
		local productsBase = eggPetAddress + addresses.eggPetProducts_offset
		for i = 0, 3 do
			local id = memoryReadInt(getProc(), productsBase + 0x44 * i)
			if id and id > 0 then
				self.Products[i+1] = {}
				self.Products[i+1].Id = id
				self.Products[i+1].Name = GetIdName(id)
				self.Products[i+1].ItemCount = memoryReadInt(getProc(), productsBase + 0x44 * i + 0x10)
			end
		end
	else
		self.Name = ""
		self.EggId = 0
		self.PetId = 0
		self.Level = 0
		self.Crafting = false
		self.Summoned = false
		self.Exp = 0
		self.MaxExp = 0
		self.TP = 0
		self.MaxTP = 0
		self.Loyalty = 0
		self.Nourishment = 0
		self.Aptitude = 0
		self.Training = 0
		self.Str = 0
		self.Sta = 0
		self.Dex = 0
		self.Int = 0
		self.Wis = 0
		self.Skills = {}
		self.Mining = 0
		self.Woodworking = 0
		self.Herbalism = 0
		self.Tool = {}
		self.Products = {}
	end
end

function CEggPet:feed(foodNameOrId, number)
	self:update()

	local originalFoodNumber = inventory:itemTotalCount(foodNameOrId)

	-- 'number' can be "all" to feed all food.
	if number == nil then
		number = 1 -- default, use 1
	elseif string.lower(number) == "all" then
		number = originalFoodNumber
	end

	local summonedState = self.Summoned

	repeat -- this loop is if you need to use more than 1 stack of food
		-- find food item.
		local foodItem = inventory:findItem(foodNameOrId)

		if( foodItem ~= nil ) then
			printf("Feeding Egg Pet...\n")
			if self.Summoned == true then -- Return pet for feeding
				self:Return(); yrest(200)
				self:update()
			end

			-- Insert food in pet feed slot
			RoMScript("ClearPetFeedItem()")
			RoMScript("PickupBagItem("..foodItem.BagId..")")
			RoMScript("ClickPetFeedItem()")

			-- How many left to do
			local numberDone = originalFoodNumber - inventory:itemTotalCount(foodNameOrId)
			local numberLeft = number - numberDone

			-- How many times to feed this loop
			if foodItem.ItemCount >= numberLeft then
				times = numberLeft
			else
				times = foodItem.ItemCount
			end

			-- Feed number of times
			for i = 1, times do
				RoMScript("FeedPet(" .. self.EggSlot .. ")")
			end

			RoMScript("ClearPetFeedItem()")
		else
			break -- No feed found
		end
	until (originalFoodNumber - inventory:itemTotalCount(foodNameOrId)) >= number


	if summonedState == true and self.Summoned == false then
		self:Summon()
	end

	self:update()
end

function CEggPet:Summon()
	self:update()
	while self.EggId > 0 and player.Level > self.Level-5 and self.Summoned == false and player.Alive and player.HP > 0 do
		keyboardRelease( settings.hotkeys.MOVE_FORWARD.key ); yrest(200)
		RoMScript("SummonPet("..self.EggSlot..")")
		repeat
			yrest(500)
			self:update()
			player:updateBattling()
			player:updateCasting()
		until self.Summoned or player.Battling or player.Casting == false
		yrest(500)
		if player.Battling then
			if player:target(player:findEnemy(true, nil, evalTargetDefault)) then
				player:fight()
			end
		end
		self:update()
	end
end

function CEggPet:Return()
	self:update()
	if self.EggId > 0 and self.Summoned then
		repeat
			RoMScript("ReturnPet("..self.EggSlot..")")
			yrest(100)
			self:update()
		until self.Summoned == false
	end
end

function CEggPet:craft(_craftType, indexLevel)
	-- Stop petInfo from auto replacing tools if installed
	if petInfoInstalled == nil then -- so it only checks once
		petInfoInstalled = RoMScript("PetInfo~=nil")
		if petInfoInstalled then
			RoMScript("PetInfoFrame:UnregisterEvent(\"PET_CRAFT_END\")")
		end
	end

	self:update()

	--Check if already crafting
	if self.Crafting then
		return
	elseif self.Summoned then
		self:Return()
	end

	-- Clear Harvest
	self:harvest()
	inventory:update()

	-- Remove existing tool tool, even if the correct tool (resolves a bug in the game).
	if self.Tool.Id ~= nil then
		local emptyBagSlot = inventory:findItem(0,"bags")
		if emptyBagSlot == nil then
			return
		end

		RoMScript("ClickPetCraftItem(".. self.EggSlot ..")")
		RoMScript("PickupBagItem(".. emptyBagSlot.BagId ..")");
		-- wait for a maximum of 1 second
		for i = 1, 4 do
			yrest(250)
			self:update()
			if self.Tool.Id == nil then
				break
			end
		end
	end

	if self.Tool.Id ~= nil or self.Crafting then -- maybe an addon replaced the tools. Give up.
		return
	end

	-- check '_craftType' value
	if _craftType ~= nil and CRAFT_TOOLS[_craftType] == nil then
		-- invalid type
		return
	elseif _craftType == nil then
		-- then use profile settings

		-- Which tool
		local bestTool = self:getBestTool()

		if bestTool == nil then -- no tools in inventory
			return
		end

		_craftType = bestTool.Type
	end

	-- Get tool item
	local craftTool = inventory:findItem(CRAFT_TOOLS[_craftType])

	if craftTool == nil then
		return
	end

	-- Get pet craft Level
	local petCraftLvl = self[_craftType]

	-- Get highest possible craft level
	local maxCraftIndex = 0
	for i = 1, 14 do
		if petCraftLvl >= CRAFT_INDEX_LEVELS[i] then
			maxCraftIndex = i
		else
			break
		end
	end

	-- Check indexLevel
	if indexLevel == nil then
		-- See if there is a user profile index override
		if settings.profile.options.EGGPET_CRAFT_INDEXES then
			local mIndex, wIndex, hIndex = string.match(settings.profile.options.EGGPET_CRAFT_INDEXES,"(%w*)%s*,%s*(%w*)%s*,%s*(%w*)")
			if _craftType == "Mining" then
				indexLevel = mIndex
			elseif _craftType == "Woodworking" then
				indexLevel = wIndex
			elseif _craftType == "Herbalism" then
				indexLevel = hIndex
			end
		end
		-- convert to numbers
		indexLevel = tonumber(indexLevel)
	end

	if indexLevel == nil or indexLevel > maxCraftIndex then
		indexLevel = maxCraftIndex -- Default to highest level
	end

	-- Insert tool
	RoMScript("PickupBagItem("..craftTool.BagId..")")
	RoMScript("ClickPetCraftItem(".. self.EggSlot ..")")

	yrest(1000)

	-- Start crafting
	RoMScript("SendSystemChat('Pet Crafting started.')")
	RoMScript("PetCraftingStart(".. self.EggSlot ..",".. indexLevel ..")")

	self:update()
end

function CEggPet:harvest()
	if #self.Products ~= 0 then
		RoMScript("PetCraftHarvest(".. self.EggSlot.. ")")
		yrest(2000)
		self:update()
	end
end

function CEggPet:getToolChoices()
	-- Returns the tool ids in order based on the user profile ratio setting and the materials in your inventory

	local function countMaterials(craft)
		local t2
		if craft == "Mining" then
			t2 = 0
		elseif craft == "Woodworking" then
			t2 = 1
		elseif craft == "Herbalism" then
			t2 = 2
		end

		local count = 0
		for k, item in pairs(inventory.BagSlot) do
			if not item.Empty and item.Available and
				item.ObjType == 3 and item.ObjSubType == t2 then
				local tmpCount = item.ItemCount
				if item.Quality > 0 then
					tmpCount = tmpCount * 2
				end
				if item.Quality > 1 then
					tmpCount = tmpCount * 6^(item.Quality - 1)
				end
				count = count + tmpCount
			end
		end
		return count
	end

	-- Get user profile ratio settings
	local mRatio, wRatio, hRatio
	if settings.profile.options.EGGPET_CRAFT_RATIO ~= nil then
		mRatio, wRatio, hRatio = string.match(settings.profile.options.EGGPET_CRAFT_RATIO,"(%d*)%s*:%s*(%d*)%s*:%s*(%d*)")
	end

	-- check for nil values
	if mRatio == nil or wRatio == nil or hRatio == nil then
		mRatio, wRatio, hRatio = 1,1,1 -- default to 1:1:1 if no ratio given
	end

	-- convert to numbers
	mRatio = tonumber(mRatio)
	wRatio = tonumber(wRatio)
	hRatio = tonumber(hRatio)

	-- equilize values and add to tmpResult table
	local tmpResults = {}
	if mRatio > 0 then
		local tmp = {}
		tmp.Type = "Mining"
		tmp.Id = CRAFT_TOOLS[tmp.Type]
		tmp.Value = countMaterials(tmp.Type)/mRatio
		tmp.HaveSome = false
		table.insert(tmpResults,tmp)
	end
	if wRatio > 0 then
		local tmp = {}
		tmp.Type = "Woodworking"
		tmp.Id = CRAFT_TOOLS[tmp.Type]
		tmp.Value = countMaterials(tmp.Type)/wRatio
		tmp.HaveSome = false
		table.insert(tmpResults,tmp)
	end
	if hRatio > 0 then
		local tmp = {}
		tmp.Type = "Herbalism"
		tmp.Id = CRAFT_TOOLS[tmp.Type]
		tmp.Value = countMaterials(tmp.Type)/hRatio
		tmp.HaveSome = false
		table.insert(tmpResults,tmp)
	end

	-- Sort
	table.sort(tmpResults, function(a,b) return a.Value < b.Value end)

	results = {}
	for k,v in pairs(tmpResults) do
		results[k] = {Type = v.Type, Id = v.Id}
	end

	return results
end

function CEggPet:getBestTool()
	local toolChoices = self:getToolChoices()
	-- Check if you have tools in inventory

	-- Custom inventory search function to speed things up
	local item
	for slot = 51, 240 do
		item = inventory.BagSlot[slot]
		if item.Available and not item.Empty then

			for i, Type in pairs(toolChoices) do
				if Type.Id == item.Id or Type.Id == self.Tool.Id then
					toolChoices[i].HaveSome = true
					break
				end
			end

		end
	end

	-- Check if you have tools
	for i, Type in pairs(toolChoices) do
		if Type.HaveSome then
			return Type
		end
	end
end


function checkEggPets()
	-- This function makes sure the pets are crafting and assisting as per the profile settings.

	local assistEgg = nil
	local craftEgg = nil

	-- Get Eggs
	if settings.profile.options.EGGPET_ENABLE_ASSIST and
	  settings.profile.options.EGGPET_ASSIST_SLOT ~= NIL then
		assistEgg = CEggPet(settings.profile.options.EGGPET_ASSIST_SLOT)
		if assistEgg.EggId == 0 then -- Bad egg
			printf("Bad egg slot given to EGGPET_ASSIST_SLOT in profile.\n")
			assistEgg = nil
		else
			player:updateLevel()
			if assistEgg.Level >= player.Level + 5 then
				assistEgg = nil
			end
		end
	end

	if settings.profile.options.EGGPET_ENABLE_CRAFT and
	  settings.profile.options.EGGPET_CRAFT_SLOT ~= NIL then
		craftEgg = CEggPet(settings.profile.options.EGGPET_CRAFT_SLOT)
		if craftEgg.EggId == 0 then -- Bad edd
			printf("Bad egg slot given to EGGPET_CRAFT_SLOT in profile.\n")
			craftEgg = nil
		elseif not craftEgg.Crafting then
			craftEgg:harvest() -- This 'harvest' makes sure to harvest when the tools run out
		end
	end

	-- Checks they are not the same
	if assistEgg and craftEgg and (assistEgg.EggSlot == craftEgg.EggSlot) then
		-- if there are tools, craft, else assist

		local choice = craftEgg:getBestTool()
		-- Check if you have tools in inventory
		if choice == nil and craftEgg.Tool.Id == nil then
			-- No tools, disable craft
			craftEgg = nil
		else
			-- Have tools, disable assist
			assistEgg = nil
		end

	end

	if assistEgg then
		-- This is the assist egg. Assist ...

		-- First make sure it isn't crafting
		if assistEgg.Crafting then
			RoMScript("PetCraftingStop(".. assistEgg.EggSlot ..")")
			repeat
				assistEgg:update()
			until assistEgg.Crafting == false
		end

		-- Custom count function because 6 itemTotalCounts is too slow
		inventory:update();

		local item, cake, cheese, milk, beef, favorite, dessert = 0,0,0,0,0,0,0
		for slot = 51, 240 do
			item = inventory.BagSlot[slot]
			if item.Available then
				if item.Id == 204791 then
					cake = cake + item.ItemCount
				elseif item.Id == 204925 then
					cheese = cheese + item.ItemCount
				elseif item.Id == 204924 then
					milk = milk + item.ItemCount
				elseif item.Id == beef then
					beef = beef + item.ItemCount
				elseif item.Id == 204511 then
					favorite = favorite + item.ItemCount
				elseif item.Id == 204510 then
					dessert = dessert + item.ItemCount
				end
			end;
		end;

		-- Check if needs to be fed

		-- Get best nourishment food
		local foodId = 0
		if assistEgg.Nourishment <= 95 and cake > 0 then -- use cake
			foodId = 204791
		elseif assistEgg.Nourishment <= 90 and cheese > 0 then -- use cheese
			foodId = 204925
		elseif assistEgg.Nourishment <= 80 and milk > 0 then -- use milk
			foodId = 204924
		elseif assistEgg.Nourishment <= 70 and beef > 0 then -- use beef
			foodId = 204234
		end

		-- Get best loyalty food
		local loyaltyFoodId = 0
		if assistEgg.Loyalty <= 90 and favorite > 0 then -- Use Favorite Meal
			loyaltyFoodId = 204511
		elseif assistEgg.Loyalty <= 99 and dessert > 0 then -- Use Dessert of Happiness
			loyaltyFoodId = 204510
		end

		if FOOD_LEVLES[foodId] and assistEgg.Nourishment <= (100 - FOOD_LEVLES[foodId]) or -- needs nourishment
		   FOOD_LEVLES[loyaltyFoodId] and assistEgg.Loyalty <= (100 - FOOD_LEVLES[loyaltyFoodId]) then -- needs loyalty
			if assistEgg.Summoned then
				assistEgg:Return()
			end

			-- feed nourishment
			if foodId ~= 0 then
				while assistEgg.Nourishment <= (100 - FOOD_LEVLES[foodId]) and inventory:itemTotalCount(foodId) > 0 do
					assistEgg:feed(foodId)
				end
			end

			-- feed loyalty
			if loyaltyFoodId ~= 0 then
				while assistEgg.Loyalty <= (100 - FOOD_LEVLES[loyaltyFoodId]) and inventory:itemTotalCount(loyaltyFoodId) > 0 do
					assistEgg:feed(loyaltyFoodId)
				end
			end
		end

		-- Resummon pet
		if assistEgg.Summoned == false then
			assistEgg:Summon()
		end
	end

	if craftEgg and not craftEgg.Crafting then
		-- This is the craft egg. Craft ...

		craftEgg:craft()
	end
end
