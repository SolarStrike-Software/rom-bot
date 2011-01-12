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

local CRAFT_NOURISHMENT_LEVLES = {
	[204791] = 5, -- CAKE
	[204925] = 10, -- CHEESE
	[204924] = 20, -- MILK
	[204234] = 30, -- BEEF
}


CEggPet = class(
	function (self, eggSlot)
		self.EggSlot = eggSlot
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

	self.EggId = memoryReadInt(getProc(), eggPetAddress + addresses.eggPetEggId_offset)
	if self.EggId ~= nil and self.EggId > 0 then -- There is an egg pet
		self.Name = memoryReadString(getProc(), eggPetAddress)
		self.PetId = memoryReadInt(getProc(), eggPetAddress + addresses.eggPetPetId_offset)
		self.Level = memoryReadInt(getProc(), eggPetAddress + addresses.eggPetLevel_offset)
		self.Summoned = (memoryReadInt(getProc(), eggPetAddress + addresses.eggPetSummoned_offset) == 2)
		self.Exp = memoryReadInt(getProc(), eggPetAddress + addresses.eggPetExp_offset)
		self.MaxExp = memoryReadIntPtr(getProc(), addresses.eggPetMaxExpTablePtr, 0x4 * self.Level)
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
		self.Id = 0
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
	if string.lower(number) == "all" then
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
	while self.EggId > 0 and self.Summoned == false do
		RoMScript("SummonPet("..self.EggSlot..")")
		repeat
			self:update()
			player:update()
			yrest(200)
		until self.Summoned or player.Battling
		if player.Battling then
			player:fight()
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
	self:update()

	--Check if already crafting
	if self.Crafting then
		return
	elseif self.Summoned then
		self:Return()
	end

	-- Clear Harvest
	self:harvest()

	-- Remove existing tool tool, even if the correct tool (resolves a bug in the game).
	if self.Tool.Id ~= nil then
		local emptyBagSlot = inventory:findItem(0)
		if emptyBagSlot == nil then
			print("Run out of bag space.")
			return
		end
		RoMScript("ClickPetCraftItem(".. self.EggSlot ..")")
		RoMScript("PickupBagItem(".. emptyBagSlot.BagId ..")");
		repeat
			yrest(100)
			self:update()
		until self.Tool.Id == nil
	end

	-- check '_craftType' value
	if _craftType == nil or _craftType == "" then
		-- Default to all
		_craftType = "mining,woodworking,herbalism"
	elseif type(_craftType) == "string" then
		-- Make sure it's lower case
		_craftType = string.lower(_craftType)
	else
		printf("Wrong value for _craftType. Defaulting to all crafts.\n")
		_craftType = "mining,woodworking,herbalism"
	end

	-- Get tool item
	local craftTool = nil
	for __, findType in pairs({"Mining","Woodworking","Herbalism"}) do
		if string.find(_craftType, string.lower(findType)) then -- User wants this one. See if we have tools.
			craftTool = inventory:findItem(CRAFT_TOOLS[findType])
			if craftTool ~= nil then
				_craftType = findType
				break
			end
		end
	end

	if craftTool == nil then
		print("No crafting tools.")
		return
	end

	-- Get pet craft Level
	local petCraftLvl = 0
	petCraftLvl = self[_craftType]
	if petCraftLvl == nil then
		printf("Wrong value for _craftType\n")
	end

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
	if indexLevel == nil or indexLevel > maxCraftIndex then
		indexLevel = maxCraftIndex -- Default to highest level
	end

	-- If pet out, return it.
	if self.Summoned then
		self:Return()
	end

	-- Insert tool
	RoMScript("PickupBagItem("..craftTool.BagId..")")
	RoMScript("ClickPetCraftItem(".. self.EggSlot ..")")

	yrest(1000)

	-- Start crafting
	RoMScript("PetCraftingStart(".. self.EggSlot ..",".. indexLevel ..")")

	self:update()
end


function CEggPet:harvest()
	if #self.Products ~= 0 then
		RoMScript("PetCraftHarvest(".. self.EggSlot.. ")")
	end
end

function checkEggs()
	-- This function makes sure the pets are crafting and assisting as per the profile settings.

	local assistEgg = nil
	local craftEgg = nil

	-- Get Eggs
	if settings.profile.options.EGGPET_ENABLE_ASSIST and
	  settings.profile.options.EGGPET_ASSIST_SLOT ~= NIL then
		assistEgg = CEggPet(settings.profile.options.EGGPET_ASSIST_SLOT)
		if assistEgg.EggId == 0 then -- Bad edd
			printf("Bad egg slot given to EGGPET_ASSIST_SLOT in profile.\n")
			assistEgg = nil
		end
	end

	if settings.profile.options.EGGPET_ENABLE_CRAFT and
	  settings.profile.options.EGGPET_CRAFT_SLOT ~= NIL then
		craftEgg = CEggPet(settings.profile.options.EGGPET_CRAFT_SLOT)
		if craftEgg.EggId == 0 then -- Bad edd
			printf("Bad egg slot given to EGGPET_CRAFT_SLOT in profile.\n")
			craftEgg = nil
		end
	end

	-- Checks they are not the same
	if assistEgg and craftEgg and (assistEgg.EggSlot == craftEgg.EggSlot) then
		error("Cannot use the same egg pet to assist and craft at the same time. Please change you profile settings.")
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

		-- Check if needs to be fed

		-- Get best food
		local foodId = 0
		if assistEgg.Nourishment < 95 and inventory:itemTotalCount(204791) > 0 then -- use cake
			foodId = 204791
		elseif assistEgg.Nourishment < 90 and inventory:itemTotalCount(204925) > 0 then -- use cheese
			foodId = 204925
		elseif assistEgg.Nourishment < 80 and inventory:itemTotalCount(204924) > 0 then -- use milk
			foodId = 204924
		elseif assistEgg.Nourishment < 70 and inventory:itemTotalCount(204234) > 0 then -- use beef
			foodId = 204234
		end

		if CRAFT_NOURISHMENT_LEVLES[foodId] and assistEgg.Nourishment <= (100 - CRAFT_NOURISHMENT_LEVLES[foodId]) then
			if assistEgg.Summoned then
				assistEgg:Return()
			end

			repeat
				assistEgg:feed(foodId,1)
				assistEgg:update()
			until assistEgg.Nourishment > (100 - CRAFT_NOURISHMENT_LEVLES[foodId]) or inventory:itemTotalCount(foodId) == 0
		end

		-- Resummon pet
		if assistEgg.Summoned == false then
			assistEgg:Summon()
		end
	end

	if craftEgg then
		-- This is the craft egg. Craft ...
		craftEgg:craft(settings.profile.options.EGGPET_CRAFT, settings.profile.options.EGGPET_CRAFTINDEX)
	end

end

