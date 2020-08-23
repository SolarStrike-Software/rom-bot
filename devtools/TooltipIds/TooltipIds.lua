local me = {   -- Create local namespace

	Strings ={
		AddonName = "TooltipIds",
		Version = "1.0b3",
		Author = "Rock5",
		IconPath = "Interface\ItemMall\IM_Help-Normal",
	},

	DefaultSettings = {
		Options = {
			[1] = true,
			[2] = true,
			[3] = true,
			[4] = true,
			[5] = true,
			[6] = true,
			[7] = true,
			[8] = true,
			[9] = true,
		},
		TextColor ={r=.33,g=0.86,b=0.6},
	},

	Constants = {
		OptionSpacing =30,
		OptionTopSpace = 48,
		Options = {
			[1] = "Unit",
			[2] = "Item",
			[3] = "Skill",
			[4] = "Buff",
			[5] = "Title",
			[6] = "Mall",
			[7] = "Store",
			[8] = "Guild",
			[9] = "Quest",
		},
	},
}
_G[me.Strings.AddonName] = me  -- Expose to global namespace
local settings -- local pointer to saved settings

local Orig_TooltipAddonUpdate_orig

--=====  HELPER FUNCTIONS  =====--

local IdTable -- Holds final table, listed by Id
local NameTable -- Holds the final table, listed by name

local scanTable -- Holds range of Ids it will scan
local scanIndex -- The index of scanTable that the scan is up to.
local ranges = {
	-- {from = 100000, to = 899999}, -- Full range
	{from = 100000, to = 130000}, -- Regular NPCs
	{from = 560000, to = 561000}, -- Resource nodes
}
local numberUpdatedAtATime = 500 -- How many Ids are collected per update tick.
local StartTime = 0 -- Holds the start time for the update timer

local function startIdScan()
	if not IdTable then
		StartTime = GetTime()
		scanTable = {}
		for _,range in pairs(ranges) do
			for id = range.from, range.to do
				table.insert(scanTable,id)
			end
		end

		scanIndex = 1
		IdTable = {}
		NameTable = {}
	end
end

-- Gets the id from a link, if in a link
local function getLinkId(link)
	if link == nil then return end

	local _type, _id = string.match(link,"|H(%a*):(%x*)")
	if _id then
		if _type == "item" then
			_id = tonumber("0x".._id)
		end
	else
		_id = link
	end

	return _id
end

-- Adds a line to the tooltip as is.
local function addLine(line)
	-- See if alreaddy added
	local firstLine = string.match(line,"^%C*")
	local lineobj, text
	local lineAlreadyAdded = false
	for i=1,40,1 do
		lineobj = _G["GameTooltipTextLeft"..i];
		if (not lineobj) or (not lineobj:IsVisible()) then
			break
		else
			text = lineobj:GetText();
			if string.find(text, firstLine) then
				lineAlreadyAdded = true
				break
			end
		end
	end

	-- Add if not already added
	if not lineAlreadyAdded then
		local color = string.format("%2x%2x%2x",settings.TextColor.r*0xff, settings.TextColor.g*0xff, settings.TextColor.b*0xff)
		GameTooltip:AddLine("|cff"..color..tostring(line))
	end
end

-- Adds an id or gets the id from a link and adds that, to the tooltip with a prefix of 'ID:'
local function addId(id)
	local _id = getLinkId(id)
	if _id == nil then return end

	addLine("ID: "..tostring(_id))
end

-- Set up Slash commands
local function setupSlashCommands()
	SLASH_TI1 = "/ti"
	SLASH_TI2 = "/TI"
	SLASH_TI3 = "/tooltipids"
	SlashCmdList["TI"] = function(editBox, msg)
		me.ToggleVisible()
	end
end

-- Set up AddonManager button
local function setupAddonManagerMiniButton()
	if AddonManager then
		local addon = {
			name = me.Strings.AddonName,
			description = "Shows the Id numbers of certain elements in the game",
			category = "Inventory",
			version = me.Strings.Version,
			author = me.Strings.Author,
			slashCommands = "/ti",
			miniButton = _G[me.Strings.AddonName.."MiniButton"],
			icon = me.Strings.IconPath,
			onClickScript = me.ToggleVisible,
		}

		if AddonManager.RegisterAddonTable then
			AddonManager.RegisterAddonTable(addon)
		else
			AddonManager.RegisterAddon(addon.name, addon.description, addon.icon, addon.category,
				addon.configFrame, addon.slashCommands, addon.miniButton, addon.onClickScript)
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage(me.Strings.AddonName.. " " .. me.Strings.Version .. " loaded",
			settings.TextColor.r, settings.TextColor.g, settings.TextColor.b);
	end
end

-- Sets up the hooks
local function setHooks()
	local Orig_GameTooltipSetBagItem = GameTooltip["SetBagItem"];
	local Orig_GameTooltipSetBankItem = GameTooltip["SetBankItem"];
	local Orig_GameTooltipSetUnitBuff = GameTooltip["SetUnitBuff"];
	local Orig_GameTooltipSetUnitDebuff = GameTooltip["SetUnitDebuff"];
	local Orig_GameTooltipSetSkillItem = GameTooltip["SetSkillItem"];
	local Orig_GameTooltipSetTitle = GameTooltip["SetTitle"];
	local Orig_GameTooltipSetItemMall = GameTooltip["SetItemMall"];
	local Orig_GameTooltipSetStoreItem = GameTooltip["SetStoreItem"];
	local Orig_GameTooltipSetHyperLink = GameTooltip["SetHyperLink"];

	-- SetBagItem hook
	function GameTooltip:SetBagItem( BagId )
		Orig_GameTooltipSetBagItem( self, BagId );

		if settings.Options[2] then
			local link = GetBagItemLink(BagId)
			addId(link)
		end
	end

	-- SetBankItem hook
	function GameTooltip:SetBankItem( BankId )
		Orig_GameTooltipSetBankItem( self, BankId );

		if settings.Options[2] then
			local link = GetBankItemLink(BankId)
			addId(link)
		end
	end

	-- SetUnitBuff hook
	function GameTooltip:SetUnitBuff( unit, num )
		Orig_GameTooltipSetUnitBuff( self, unit, num );

		if settings.Options[4] then
			local name, icon, count, ID = UnitBuff(unit , num )
			addId(ID) -- Doesn't work
			DEFAULT_CHAT_FRAME:AddMessage(name.." ID: ".. ID, settings.TextColor.r, settings.TextColor.g, settings.TextColor.b);
		end
	end

	-- SetUnitDebuff hook
	function GameTooltip:SetUnitDebuff( unit, num )
		Orig_GameTooltipSetUnitDebuff( self, unit, num );

		if settings.Options[4] then
			local name, icon, count, ID = UnitDebuff(unit , num )
			-- addId(ID) -- Doesn't work
			DEFAULT_CHAT_FRAME:AddMessage(name.." ID: ".. ID, settings.TextColor.r, settings.TextColor.g, settings.TextColor.b);
		end
	end

	-- SetSkillItem hook
	function GameTooltip:SetSkillItem( gtype, index )
		Orig_GameTooltipSetSkillItem( self, gtype, index )

		if settings.Options[3] then
			local link = GetSkillHyperLink(gtype, index)
			addId(link)
		end
	end

	-- SetTitle hook
	function GameTooltip:SetTitle(titleid)
		Orig_GameTooltipSetTitle(self, titleid)

		if settings.Options[5] then
			addId(titleid)
		end
	end

	-- SetItemMall hook
	function GameTooltip:SetItemMall(id)
		Orig_GameTooltipSetItemMall(self, id)

		if settings.Options[6] then
			local link = GetItemMallLink(id)
			addLine("ID: "..getLinkId(link).."  GUID: "..id)
		end
	end

	-- QuestBookItem_OnEnter replacment
	function QuestBookItem_OnEnter( this )
		local textObj = getglobal( this:GetName() .. "_QuestName" );

		if( textObj:IsDrawDot() or settings.Options[9])then
			local text = textObj:GetText();
			GameTooltip:SetOwner( this, "ANCHOR_TOPRIGHT", -5, 0 );
			GameTooltip:SetText( text,1,1,1 );
			GameTooltip:Show();
		end
		if settings.Options[9] then
			addId(GetQuestId(this.QuestID))
		end

	end


	-- SetStoreItem hook
	function GameTooltip:SetStoreItem(tab,index)
		Orig_GameTooltipSetStoreItem(self, tab,index)

		if settings.Options[7] then
			local link
			if tab == "SELL" then
				link = GetStoreSellItemLink(index)
			elseif tab == "BUYBACK" then
				link = GetStoreBuyBackItemLink(index)
			end
			addId(link)
		end
	end

	function GameTooltip:SetHyperLink(itemlink)
		Orig_GameTooltipSetHyperLink(self,itemlink)

		if settings.Options[8] then
			addId(itemlink)
		end
	end
end

--=====  FUNCTIONS AVAILABLE TO USER  =====--

-- Returns a table of ids that match a given name
function GetNameIds(_name)
	if NameTable and NameTable[_name] then
		return NameTable[_name]
	elseif scanIndex then
		return {"Still scanning..."}
	end
end

-- Returns the name of a given id
function GetIdName(_id)
	if IdTable and IdTable[_id] then
		return IdTable[_id]
	elseif scanIndex then
		return {"Still scanning..."}
	end
end

--=====  'ME' TRIGGERED FUNCTIONS  =====--

-- Toogle the config frame
function me.ToggleVisible()
	local frame = _G[me.Strings.AddonName.."Frame"]
	if frame:IsVisible() then
		frame:Hide()
	else
		frame:Show()
	end
end

-- Unit mouseover function. Called by pbinfo or local mouseover event handler.
function me:MouseOverUnit()
	if settings.Options[1] then
		local name = UnitName("mouseover");
		if name then
			local ids = GetNameIds(name)
			if ids then
				local cols = math.min(4,math.ceil(#ids/20))
				local tmpIds = {}
				for k= 1,#ids,cols do
					local tmp = ids[k]
					for i = k+1, k + cols-1 do
						if ids[i] then
							tmp = tmp .. " " .. ids[i]
						end
					end
					table.insert(tmpIds,tmp)
				end
				tmpIds = table.concat(tmpIds,"\n")
				addId(tmpIds)
			end
		end
	end
end

-- OnLoad Handler
function me:OnLoad(this)
	UIPanelBackdropFrame_SetTexture( this, "Interface/Common/PanelCommonFrame", 256, 256 );
	this:RegisterEvent("VARIABLES_LOADED");
	setHooks()
end

-- OnUpdate handler
function me.OnUpdate(this)
	-- Scans 'numberUpdatedAtATime' ids at a time so it doesn't freeze the screen.
	if scanIndex and scanTable then
		local scanTo = scanIndex + numberUpdatedAtATime
		if scanTo > #scanTable then
			scanTo = #scanTable
		end
		local id, t1, t2
		for i = scanIndex, scanTo do
			id = scanTable[i]
			t1 = "Sys"..id.."_name"
			t2 = TEXT(t1)
			if t1~=t2 then
				IdTable[id] = t2
				if NameTable[t2] == nil then
					NameTable[t2] = {id}
				else
					table.insert(NameTable[t2],id)
				end
			end
		end
		if scanTo == #scanTable then -- Scan finished
			-- Print message
			local msg = string.format("TooltipIds Id update complete in %.1fs",GetTime() - StartTime)
			SendSystemChat(msg)
			-- Reset values
			scanIndex = nil
			scanTable = nil
			me.UpdateFrame:Hide() -- Stops the scanning
			-- Check that that id range hasn't gone out of bounds
			for k,v in pairs(ranges) do
				if IdTable[v.to] then
					local msg = string.format("TooltipIds: Id range ending in %d needs to be updated.",v.to)
					SendSystemChat(msg)
				end
			end
			return
		end
		scanIndex = scanIndex + numberUpdatedAtATime + 1
	end
end

-- Event handler
function me:OnEvent(frame, event, arg1, arg2)
	if event == "VARIABLES_LOADED" then
		-- Check variables
		if _G[me.Strings.AddonName.."_Settings"] == nil then
			_G[me.Strings.AddonName.."_Settings"] = {}
		end
		settings = _G[me.Strings.AddonName.."_Settings"]
		--local checksettings
		local function checksettings(_settings,_defaults)
			for k,v in pairs(_defaults) do
				if _settings[k] == nil then
					_settings[k] = v
				elseif type(v) == "table" then
					checksettings(_settings[k],v)
				end
			end
		end
		checksettings(settings,me.DefaultSettings)

		SaveVariables(me.Strings.AddonName.."_Settings")

		-- Set up frame
		me.UpdateFrame = _G[me.Strings.AddonName.."UpdateFrame"]
		me.Frame = _G[me.Strings.AddonName.."Frame"]
		me.Frame:SetSize(220,me.Constants.OptionTopSpace*2+#settings.Options*me.Constants.OptionSpacing)
		_G[me.Frame:GetName().."Title"]:SetText("|cffffaa50"..me.Strings.AddonName.." "..me.Strings.Version)

		-- Position colorpicker button
		me.ColorPicker = _G[me.Frame:GetName().."ColorPicker"]
		me.ColorPicker:ClearAllAnchors()
		me.ColorPicker:SetAnchor("TOPLEFT","TOPLEFT",me.Strings.AddonName.."Frame",70,me.Constants.OptionTopSpace)
		_G[me.Frame:GetName().. "ColorPickerButtonBlock"]:SetColor(settings.TextColor.r, settings.TextColor.g, settings.TextColor.b)
		_G[me.Frame:GetName().. "ColorPickerText"]:SetText("|cfffffd66Id Color")


		-- Set up Options
		me.Option={}
		for i = 1, #me.Constants.Options do
			me.Option[i]=_G[me.Frame:GetName().."Option"..i]
			me.Option[i]:ClearAllAnchors()
			me.Option[i]:SetAnchor("TOPLEFT","TOPLEFT",me.Strings.AddonName.."Frame",50,me.Constants.OptionTopSpace+me.Option[i]:GetID()*me.Constants.OptionSpacing)
			me.Option[i]:SetChecked(settings.Options[i])
			local text = "|cffbbbbffShow |cfffffd66"..me.Constants.Options[i].." |cffbbbbffIds"
			_G[me.Option[i]:GetName().."Name"]:SetText(text)
		end
		if pbInfo then
			local Orig_TooltipAddonUpdate_orig = pbInfo.Tooltip.Scripts.OnUpdate;
			pbInfo.Tooltip.Scripts.OnUpdate = function()
				Orig_TooltipAddonUpdate_orig()
				me.MouseOverUnit();
			end
		else
			frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
		end

		setupSlashCommands()
		setupAddonManagerMiniButton()

	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		me.MouseOverUnit()
	end

	-- Uses the update event to collect the ids and names
	startIdScan()
	me.UpdateFrame:Show() -- Starts the updates for scanning.
end

-- Option OnClick handler
function me:Checkbox_OnClick(this)
	settings.Options[this:GetID()]=this:IsChecked()
end

-- Color picker for displayed Id.
function me:OpenColorPicker(this)
	--CallBack data
	ColorPickerFrame.call=this;

	local r,g,b=getglobal(this:GetName().."Block"):GetColor();

	if (r==0 and g==0 and b==0) then
		r=1;
		g=1;
		b=1;
	end

	local function ColorOkay()
		settings.TextColor.r = ColorPickerFrame.r
		settings.TextColor.g = ColorPickerFrame.g
		settings.TextColor.b = ColorPickerFrame.b
	end

	local function ColorUpdate()
		local r, g, b = ColorPickerFrame.r, ColorPickerFrame.g, ColorPickerFrame.b;
		_G[this:GetName() .. "Block"]:SetColor(r, g, b);
	end

	local info = {};
	info.parent    = this;
	info.titleText = _G[this:GetParent():GetName().."Text"]:GetText();
	info.alphaMode = nil;
	info.r         = r;
	info.g         = g;
	info.b         = b;
	info.a         = 1;
	info.brightnessUp   = 1;
	info.brightnessDown = 0.2;
	info.callbackFuncOkay   = ColorOkay;
	info.callbackFuncUpdate = ColorUpdate;
	info.callbackFuncCancel = ColorUpdate;

	OpenColorPickerFrameEx(info);
end