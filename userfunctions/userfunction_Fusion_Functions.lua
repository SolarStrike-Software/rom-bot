--==<<               Rock5's Fusion Functions                 >>==--
--==<<             By Rock5        Version 0.46 b2            >>==--
--==<<                                                        >>==--
--==<<   Requirements: Store already open                     >>==--
--==<<                 Fusion addon installed v2.0 or newer   >>==--
--==<<                 enough money to buy items required     >>==--
--==<<                                                        >>==--
--==<<  www.solarstrike.net/phpBB3/viewtopic.php?f=21&t=1434  >>==--

local function checkAddons()
	if RoMScript("FusionFrame1 ~= nil") then
		cprintf(cli.lightred,"This version of Fusion Functions only supports Fusion v2.0 and newer.\n")
		return false
	end
	if RoMScript("AdvancedMagicBoxFrame ~= nil") then
		cprintf(cli.lightred,"This version of Fusion_Functions only supports Fusion v2.0 and newer which requires you to update your AdvancedMagicBox addon.\n")
		return false
	end

	return true
end

function Fusion_NumberToBuy(_beltTierLevel)
------------------------------------------------
-- Calculates minimum number to buy for belts and
-- fusion stones to use up all your charges. Takes
-- into account number of charges and mana stones
-- you already have. You only need to use this if
-- you create disposable characters.
-- Accepts argument:
--    _beltTierLevel = the tier level stone the
--                     belt makes - defaults to Fusion Item Tier setting
------------------------------------------------
	_beltTierLevel = _beltTierLevel or RoMScript("Fusion_Settings.ItemTier") -- defaults to Fusion Item Tier setting

	local ht	= 20 -- highest tier stone to make. Fusion can only make upto tier 20 mana stones
	local wt	= ht -- Current working tier level. Start at top
	local ch 	= RoMScript("GetMagicBoxEnergy()") -- get charges
	local buy	= 0  -- Number to buy

	-- Get tier stone counts
	local t={}
	for i = 2, wt do
		t[i]=inventory:getItemCount(202839+i)
	end

	while ch > 0 do
		if t[wt]>2 and ht>wt then -- go up
			ch=ch-1
			t[wt]=t[wt]-3
			wt=wt+1
			t[wt]=t[wt]+1
		elseif wt==2 then -- fuse belt
			ch=ch-1
			buy=buy+1
			t[_beltTierLevel]=t[_beltTierLevel]+1
			wt = _beltTierLevel
		else -- go down
			wt=wt-1
		end
	end
	return buy
end

function Fusion_Config(setting, value)
------------------------------------------------
-- Use to change values on the fusion config page.
-- Accepts arguments:
--    setting = The name of the setting to change.
--              Accepted values include
--                  'Random Fusion Stones'
--                  'Fusion Stones'
--                  'Purified Fusion Stones'
--                  'Item Tier Level'
--                  'Maximum Stats'
--                  'Use Clean Items'
--                  'Use Item Whitelist'
--                  'Set Whitelist'
--                  'White'
--                  'Green'
--                  'Blue'
--                  'Purple'
--    value = the value to change it to.
-------------------------------------------------
	if checkAddons() ~= true then return end

	if setting == "Random Fusion Stones" then
		if type(value) == "boolean" then
			print("Setting \'Random Fusion Stones\' to " .. tostring(value) .. ".")
			RoMCode("Fusion_Settings.UseRandomFusionStones="..tostring(value))
			return
		end
	end
	if setting == "Fusion Stones" then
		if type(value) == "boolean" then
			print("Setting \'Fusion Stones\' to " .. tostring(value) .. ".")
			RoMCode("Fusion_Settings.UseFusionStones="..tostring(value))
			return
		end
	end
	if setting == "Purified Fusion Stones" then
		if type(value) == "boolean" then
			print("Setting \'Purified Fusion Stones\' to " .. tostring(value) .. ".")
			RoMCode("Fusion_Settings.UsePurifiedFusionStones="..tostring(value))
			return
		end
	end
	if setting == "Item Tier Level" then
		if type(value) == "number" then
			print("Setting \'Item Tier Level\' to " .. tostring(value) .. ".")
			RoMCode("Fusion_Settings.ItemTier="..tostring(value))
			return
		end
	end
	if setting == "Maximum Stats" then
		if type(value) == "number" then
			print("Setting \'Maximum Stats\' to " .. tostring(value) .. ".")
			RoMCode("Fusion_Settings.MaxStats="..tostring(value))
			return
		end
	end
	if setting == "Use Clean Items" then
		if type(value) == "boolean" then
			print("Setting \'Use Clean Items\' to " .. tostring(value) .. ".")
			RoMCode("Fusion_Settings.UseCleanItems="..tostring(value))
			return
		end
	end
	if setting == "Use Item Whitelist" then
		if type(value) == "boolean" then
			print("Setting \'Use Item Whitelist\' to " .. tostring(value) .. ".")
			RoMCode("Fusion_Settings.UseItemlist="..tostring(value))
			return
		end
	end
	if setting == "Set Whitelist" then
		if type(value) == "string" then
			print("Setting the Whitelist to " .. value .. ".")
			RoMCode([[
				Fusion_Settings.Itemlist = ]]..tostrin(value)..[[
				Fusion_Settings.Itemlist = string.gsub (Fusion_Settings.Itemlist, "%s*[;,]%s*", "\n"); -- replace ; with linefeed
				Fusion.Itemlist = Fusion.Tool:StringExplode( Fusion_Settings.Itemlist, "\n");
			]])
			return
		end
	end
	if setting == "White" then
		if type(value) == "boolean" then
			print("Setting \'White\' to " .. tostring(value) .. ".")
			RoMCode("Fusion_Settings.White="..tostring(value))
			return
		end
	end
	if setting == "Green" then
		if type(value) == "boolean" then
			print("Setting \'Green\' to " .. tostring(value) .. ".")
			RoMCode("Fusion_Settings.Green="..tostring(value))
			return
		end
	end
	if setting == "Blue" then
		if type(value) == "boolean" then
			print("Setting \'Blue\' to " .. tostring(value) .. ".")
			RoMCode("Fusion_Settings.Blue="..tostring(value))
			return
		end
	end
	if setting == "Purple" then
		if type(value) == "boolean" then
			print("Setting \'Purple\' to " .. tostring(value) .. ".")
			RoMCode("Fusion_Settings.Purple="..tostring(value))
			return
		end
	end

	cprintf(cli.yellow,"Wrong usage of the Fusion_Config function.\n")
	print("Possible argument values are listed below;")
	print("   Fusion_Config(\"Random Fusion Stones\",true/false)")
	print("   Fusion_Config(\"Fusion Stones\",true/false)")
	print("   Fusion_Config(\"Purified Fusion Stones\",true/false)")
	print("   Fusion_Config(\"Item Tier Level\",number)")
	print("   Fusion_Config(\"Maximum Stats\",number)")
	print("   Fusion_Config(\"Use Clean Items\",true/false)")
	print("   Fusion_Config(\"Use Item Whitelist\",true/false)")
	print("   Fusion_Config(\"Set Whitelist\",\"item1,item2\")")
	print("   Fusion_Config(\"White\",true/false)")
	print("   Fusion_Config(\"Green\",true/false)")
	print("   Fusion_Config(\"Blue\",true/false)")
	print("   Fusion_Config(\"Purple\",true/false)")
end

function Fusion_LoadPreset(namenum)
	local num
	if type(tonumber(namenum)) == "number" then
		if RoMScript("Fusion_Settings.Presets["..namenum.."]~=nil") then
			num = namenum
		end
	elseif type(namenum) == "string" then
		num = RoMCode([[
for k,v in pairs(Fusion_Settings.Presets) do
	if v.Label=="]]..namenum..[[" then a=k break end
end]])
	end
	if num then
		RoMCode("Fusion:LoadPreset(FusionFrame_Preset"..num..")")
	else
		print("Fusion_LoadPreset: No such preset, "..namenum..".")
	end
end

function BuyItemByName(itemname, num)
------------------------------------------------
-- Buy number of items by item name
-- itemname = name of item to buy
-- num = number of items to buy
-- Store should already be open
--
-- Superceeded:
-- Users of newer versions of the bot should use
--       store:buyItem(nameIdOrIndex, quantity) or
--       inventory:storeBuyItem(nameIdOrIndex, quantity)
-- Kept for backward compatability.
------------------------------------------------
	return store:buyItem(itemname, num)
end

function Fusion_MakeMaxManaStones(_maxManaStoneLevel)
------------------------------------------------
-- Just makes the maximum mana stones possible.
-- Similar to just clicking "Max" then "Start"
-- but you have the option to specify the maximum
-- level mana stones to make.
-- Accepts argument:
--    _maxManaStoneLevel = The maxixmum level mana stones
--                         to make. If omitted, creates
--                         highest possible.
--------------------------------------------------
	if checkAddons() ~= true then return end

	if _maxManaStoneLevel then
		if type(_maxManaStoneLevel) ~= "number" then
			error("Fusion_MakeMaxManaStones: wrong type arg#1. Expected 'number' or nil, got ".. type(_maxManaStoneLevel))
		elseif (_maxManaStoneLevel < 4 and _maxManaStoneLevel ~= 0) or _maxManaStoneLevel > 20 then
			error("Fusion_MakeMaxManaStones: arg#1 out of range. Valid values are 0 and 4 to 20, or nil.")
		end
	end

	cprintf(cli.lightblue,"Making Mana stones...\n")

	-- Open dialogs
	print("Opening Transmutor and Fusion frames.")
	RoMCode("MagicBoxFrame:Show(); FusionFrame:Show()"); yrest(1500)

	-- Set number to make
	if _maxManaStoneLevel ~= nil then
		print("Setting to make Mana Stones up to a level of ".._maxManaStoneLevel )
RoMCode([[
local num
for i = 2,20 do
	if i <= ]].._maxManaStoneLevel..[[ and ]].._maxManaStoneLevel..[[ ~= 0 then
		num = 999
	else
		num = 0
	end
	repeat
		_G["FusionFrame_Number"..i.."EditBox"]:SetNumber(num);
	until _G["FusionFrame_Number"..i.."EditBox"]:GetNumber() == num
end
]])
	else
		RoMCode("Fusion:Max_OnClick(FusionFrame_Max)")
	end
	yrest(1500)

	print("Now Fusing ...")
	RoMCode("Fusion:Do_OnClick(FusionFrame_Do)");

	repeat
		yrest(1500)
	until RoMScript("Fusion.DoQueue")~=true and RoMScript("Fusion.EmptyMagicBox") ~= true

	-- close
	yrest(2000)
	RoMCode("MagicBoxFrame:Hide()"); yrest(500)
end
