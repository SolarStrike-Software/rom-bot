--[[
	d303Fix v0.9 by DRACULA
	Released under to public domain - http://en.wikipedia.org/wiki/Public_Domain
]]

-- Slash commands
SLASH_d303FixGUI1 = "/dt";
SLASH_d303FixGUI1 = "/os";

-- Slash commands handling

SlashCmdList["d303FixGUI"] = function(editBox, msg) d303Fix.SwitchFunc(d303Fix_GUI.Config_FuncTable, msg) end;

d303Fix_GUI = {
	Config_FuncTable = {
			["hide"]	= function (msg) d303Fix_Config_Frame:Hide() end,
			default		= function (msg) d303Fix_Config_Frame:Show() end,
		},
	
	Strings = {
			["ItemShopEnable"]			= "Enable Item Shop probing",
			["ItemShopOffset"]			= "Time offset:",
			["ScreenShotEnable"]		= "Enable ScreenShoot name parsing.",
			["ScreenShotEnableAuto"]	= "Auto ScreenShot on login.",
			["ScreenShotEnableOnFail"]	= "Auto ScreenShot on Item Shop fail.",

			["SaveTip"]					= "Save settings.",
			["ResetTip"]				= "Reset clock and load last saved settings.",

			["Save"]					= "Save",
			["Reset"]					= "Reset Clock",
		},
	
	OnLoad = function(this)
			-- List events to catch
			local listenTo = { "VARIABLES_LOADED", }
			
			-- Loop events to register
			for _,e in ipairs(listenTo) do
				this:RegisterEvent(e);
			end
			
			-- Language support
			local gamelang = GetLanguage():upper();

			if (gamelang ~= "ENUS" and gamelang ~= "ENEU") then
				d303Fix.SafeLoadFile(d303Fix.Path.."Locales/"..gamelang..".GUI.lua");
			end;
		end,
		
	OnEvent = function(event, arg1)
			if event == "VARIABLES_LOADED" then
				-- d303Fix is loaded before Addon Manages, so we need to do a litle trick
				d303Fix_GUI.AddonManagerInit()
			end
		end,
		
	AddonManagerInit = function()
			if AddonManager then
				local addon = {
					name = "d303Fix",
					version = d303Fix.Version,
					author = "DR4CUL4",
					description = "Game patch 3.0.3 Fix",
					icon = d303Fix.Path.."Textures/d303Fix.tga",
					category = "Other",
					configFrame = d303Fix_Config_Frame,
					slashCommand = "/dt /dtis /dtss",
					--miniButton = dAFKMiniButton, -- Currently not implemented
					--disableScript = nil,
					--enableScript = nil,
				}
				
				-- Register addon using proper method
				if AddonManager.RegisterAddonTable then
					AddonManager.RegisterAddonTable(addon)
				else
					AddonManager.RegisterAddon(addon.name, addon.description, addon.icon, addon.category, 
						addon.configFrame, addon.slashCommand, addon.miniButton, addon.version, addon.author);
				end
			end
		end,

	OnEnter_ItemShop_Offset = function(this)
			GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT", 4, 0);
			GameTooltip:ClearLines();
			GameTooltip:SetText(d303Fix_GUI.Strings.ItemShopOffsetTip, 1, 1, 1);
			GameTooltip:Show();
		end,
		
	OnEnter_Reset = function(this)
			GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT", 4, 0);
			GameTooltip:ClearLines();
			GameTooltip:SetText(d303Fix_GUI.Strings.ResetTip, 1, 1, 1);
			GameTooltip:Show();
		end,
		
	OnEnter_Save = function(this)
			GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT", 4, 0);
			GameTooltip:ClearLines();
			GameTooltip:SetText(d303Fix_GUI.Strings.SaveTip, 1, 1, 1);
			GameTooltip:Show();
		end,
		
	ConfigLabls = function()
			d303Fix_Config_Frame_Title:SetText("d303Fix "..d303Fix.Version)
			
			d303Fix_Config_ItemShop_Enable_Label:SetText(d303Fix_GUI.Strings.ItemShopEnable)
			d303Fix_Config_ItemShop_Offset_Label:SetText(d303Fix_GUI.Strings.ItemShopOffset)
			d303Fix_Config_ScreenShot_Enable_Label:SetText(d303Fix_GUI.Strings.ScreenShotEnable)
			d303Fix_Config_ScreenShot_Enable_Auto_Label:SetText(d303Fix_GUI.Strings.ScreenShotEnableAuto)
			d303Fix_Config_ScreenShot_Enable_OnFail_Label:SetText(d303Fix_GUI.Strings.ScreenShotEnableOnFail)

			d303Fix_Config_Save:SetText(d303Fix_GUI.Strings.Save)
			d303Fix_Config_Reset:SetText(d303Fix_GUI.Strings.Reset)
		end,
		
	ConfigFill = function()
			d303Fix_Config_ItemShop_Enable:SetChecked(d303Fix.ItemShop)
			d303Fix_Config_ItemShop_Offset:SetValue(d303Fix.ItemShopOffset)
			d303Fix_Config_ScreenShot_Enable:SetChecked(d303Fix.ScreenShot)
			d303Fix_Config_ScreenShot_Enable_Auto:SetChecked(d303Fix.ScreenShotAuto)
			d303Fix_Config_ScreenShot_Enable_OnFail:SetChecked(d303Fix.ScreenShotOnFail)
		end,

	Reset = function()
			d303Fix_GUI.ConfigFill();
			d303Fix.Reset();
		end,

	Save = function()
			d303Fix.ItemShop			= d303Fix_Config_ItemShop_Enable:IsChecked()
			d303Fix.ItemShopOffset		= d303Fix_Config_ItemShop_Offset:GetValue()
			d303Fix.ScreenShot			= d303Fix_Config_ScreenShot_Enable:IsChecked()
			d303Fix.ScreenShotAuto		= d303Fix_Config_ScreenShot_Enable_Auto:IsChecked()
			d303Fix.ScreenShotOnFail	= d303Fix_Config_ScreenShot_Enable_OnFail:IsChecked()
			
			d303Fix.Events_FuncTable.SAVE_VARIABLES();
		end,
}