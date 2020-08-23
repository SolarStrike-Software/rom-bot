
-- ##############################################
-- ##                                          ##
-- ##  Ultimate Mail Mod                       ##
-- ##                                          ##
-- ##  By: Shardea of Siochain[EN]             ##
-- ##      shardea@azureorder.dk               ##
-- ##      www.azureorder.dk                   ##
-- ##                                          ##
-- ##  Runes of Magic Mail system replacement  ##
-- ##  Offers a more mail minded interface     ##
-- ##  and mass send abilities.                ##
-- ##                                          ##
-- ##  Modified by Rock5                       ##
-- ##  Based on mod by slayblaze               ##
-- ##                                          ##
-- ##############################################

UMM_ROCK5_VERSION = 1.31

UMM_VERSION = {
  Major     = 1,
  Minor     = 6,
  Revision  = 5,
  Build     = 1676;
}

-- ##### Local Variables #####

local ModEnabled  = false;

-- ##### Memory Cleanup #####

local SETTING_GarbageCollectTime  = 900; -- seconds
local GarbageCollectionTimeout    = SETTING_GarbageCollectTime;

local function CheckGarbageCollection()
  if (GetPlayerCombatState()) then
    GarbageCollectionTimeout = 1;
  else
    collectgarbage();
    GarbageCollectionTimeout = SETTING_GarbageCollectTime;
  end
end


-- ##### New Mail Icon Handling #####

function UMMNewMailButton_OnLoad(this)

  this.flashLevel = 0;

  this.CheckStatus = function(self, silent)
    local number = UMMSettings:NewMail();
    if (number) then
      if (number > 0) then
        getglobal(self:GetName().."Flash"):Show();
        self:Show();
        if (not silent) then
          self.flashLevel = 1;
          WarningFrame:AddMessage(UMM_NOTIFY_NEWMAILARRIVED, 0.48, 0.69, 0.86);
          if (UMMSettings:Get("AudioWarning") == true) then
            -- Play the sound warning if settings allow it
            PlaySoundByPath("Interface/Addons/UltimateMailMod/Sound/NewMail.wav")
          end
        end
      else
        self:Hide();
      end
    else
      self:Hide();
    end
  end;

  this.Enter = function(self)
    local number = UMMSettings:NewMail();
    if (number ~= nil) then
      if (number > 0) then
        GameTooltip:ClearLines();
        GameTooltip:ClearAllAnchors();
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", 0, 0);
        GameTooltip:AddLine("|cff"..UMMColor.Header..UMM_NOTIFY_TOOLTIP_TITLE.."|r");
        if (number == 1) then
          GameTooltip:AddLine("|cff"..UMMColor.Bright..UMM_NOTIFY_TOOLTIP_NEWMAIL.."|r");
        else
          GameTooltip:AddLine("|cff"..UMMColor.Bright..string.format(UMM_NOTIFY_TOOLTIP_NEWMAILS, number).."|r");
        end
        GameTooltip:AddLine("|cff"..UMMColor.Dark..UMM_NOTIFY_TOOLTIP_MOVETIP.."|r");
        GameTooltip:Show();
      end
    end
  end;

  this.Leave = function(self)
    GameTooltip:Hide();
  end;

  this.Update = function(self, this, elapsedTime)
    if (self.flashLevel > 0) then
      self.flashLevel = self.flashLevel - elapsedTime;
      if (self.flashLevel >= 0 and self.flashLevel <= 1) then
        getglobal(self:GetName().."Flash"):SetAlpha(self.flashLevel);
      end
      if (self.flashLevel <= 0) then
        self.flashLevel = 0;
      end
    end
  end;

end

-- ##### Master Frame Handling ######

function UMMMasterFrame_OnEvent(event, arg1, arg2, arg3, arg4)
  if (event == "VARIABLES_LOADED") then
    ModEnabled = true;
    UMMBagManager:Load();
    UMMSettings:Init();
    if (AddonManager) then
      -- Skip displaying the prompt for those running AddonManager
    else
      UMMPrompt(UMM_TITLE.." v"..UMM_VERSION.Major.."."..UMM_VERSION.Minor.."."..UMM_VERSION.Revision.." ("..UMM_VERSION.Build..")"..UMM_LOADED);
    end
  end
  if (event == "LOADING_END") then
    UMMSettings:CheckCharacter();
    UMMNewMailButton:CheckStatus();
  end
  if (event == "MAIL_SHOW") then
    if (ModEnabled == true) then
      UMMSettings:CheckCharacter();
      ShowUIPanel(UMMFrame);
    end
  end
  if (event == "MAIL_INBOX_UPDATE") then
    if (ModEnabled == true) then
      -- Reload the inbox
      UMMMailManager:InboxRefresh();
      UMMGlobalInboxLoadTimeout = 0;
      if (UMMMailManager:InboxShown()) then
        UMMFrameTab1TOC:RefreshTOC();
        UMMFrameTab1TOC:ShowInboxStatus();
      end
    end
  end
  if (event == "MAIL_SEND_INFO_UPDATE") then
    if (ModEnabled == true) then
      -- Inform the MailManager that the send info has been updated
      UMMMailComposer:SendInfoUpdated();
    end
  end
  if (event == "MAIL_SEND_SUCCESS") then
    if (ModEnabled == true) then
      -- Inform the MailManager that the mail was sent successfully
      UMMMailComposer:SendCompleted("ok");
	  GetKeyboardFocus():ClearFocus()
    end
  end
  if (event == "MAIL_FAILED") then
    if (ModEnabled == true) then
      -- Inform the MailManager that the mail send failed
      UMMMailComposer:SendCompleted("failed");
    end
  end
  if (event == "PLAYER_BAG_CHANGED") then
    if (ModEnabled == true) then
      -- Have the BagManager reload all items
      UMMBagManager:Load();
      -- Inform the MailManager to unlock an item
      UMMMailManager:UnLock("Item");
      -- If the Mass Send Items tab is visible then refresh the view
      UMMMailManager:AttachmentSucceeded();
      -- Re-populate bag display in Mass Send Items
      UMMFrameTab3Bags:PopulateBags();
    end
  end
  if (event == "PLAYER_MONEY") then
    if (ModEnabled == true) then
      -- Inform the MailManager to unlock for money
      UMMMailManager:UnLock("Money");
    end
  end
  if (event == "CHAT_MSG_SYSTEM" and TEXT("SYS_NEW_MAIL") == arg1) then
    if (ModEnabled == true) then
      -- Pop the "New Mail" icon
      UMMSettings:NewMail(1);
      UMMNewMailButton:CheckStatus();
    end
  end
  if (event == "WARNING_MESSAGE") then
    if (ModEnabled == true) then
      if (TEXT("SYS_GAMEMSGEVENT_750") == arg1 or TEXT("ASK_BACKPACK_FULL") == arg1) then
		for index = 1, 180 do
		  if (UMMBagManager.ItemList[index].Empty == true) then
			return;
		  end
		end
        UMMPrompt("|r|cff"..UMMColor.Red..BAG_OVERFLOW);
        UMMMailManager:StopAutomation();
        UMMSetGlobalFailTimeout("UMMMailManager");
        UMMGlobalFailTimeout = 0.75;
      end
    end
  end
  if (event == "ITEMQUEUE_INSERT" or
      event == "ITEMQUEUE_UPDATE") then
    if (ModEnabled == true) then
      UMMMailManager:UpdateItemQueueLength();
    end;
  end;
  if (event == "BAG_ITEM_UPDATE") then
    if (ModEnabled == true) then
      UMMMailManager:UpdateBagSlots();
    end;
  end;
end

function UMMMasterFrame_OnLoad(this)
  this:RegisterEvent("VARIABLES_LOADED");
  this:RegisterEvent("LOADING_END");
  this:RegisterEvent("MAIL_SHOW");
  this:RegisterEvent("MAIL_INBOX_UPDATE");
  this:RegisterEvent("MAIL_SEND_INFO_UPDATE");
  this:RegisterEvent("MAIL_SEND_SUCCESS");
  this:RegisterEvent("MAIL_FAILED");
  this:RegisterEvent("CLOSE_INBOX_ITEM");
  this:RegisterEvent("PLAYER_BAG_CHANGED");
  this:RegisterEvent("CHAT_MSG_SYSTEM");
  this:RegisterEvent("CHAT_MSG_SYSTEM_GET");
  this:RegisterEvent("WARNING_MESSAGE");
  this:RegisterEvent("PLAYER_MONEY");
-- new:
  this:RegisterEvent("ITEMQUEUE_INSERT");
  this:RegisterEvent("ITEMQUEUE_UPDATE");
  this:RegisterEvent("BAG_ITEM_UPDATE");
  UMMFrame_OnLoad(UMMFrame);
end

local TimeSinceLastUpdate = 0;

function UMMMasterFrame_OnUpdate(this, elapsedTime)
  UMMMailManager:TryAutoTakeMail();
  if (isShown == nil) then
    if (MailFrame:IsVisible()) then
    else
      if (UMMFrame:IsVisible()) then
        HideUIPanel(UMMFrame);
        UMMComposeConfirm:Clear();
      end
    end
  end
  TimeSinceLastUpdate = TimeSinceLastUpdate + elapsedTime;
  if (TimeSinceLastUpdate >= 1) then
    TimeSinceLastUpdate = 0;
    GarbageCollectionTimeout = GarbageCollectionTimeout - 1;
    if (GarbageCollectionTimeout == 0) then
      CheckGarbageCollection();
    end
  end
  if (UMMGlobalTimeoutCallFunction ~= nil) then
    if (UMMGlobalTimeout > 0) then
      UMMGlobalTimeout = UMMGlobalTimeout - elapsedTime;
      if (UMMGlobalTimeout <= 0) then
        UMMGlobalTimeout = 0;
        UMMGlobalFailTimeout = 0;
        getglobal(UMMGlobalTimeoutCallFunction):TimeOut();
      end
    end
  end
  if (UMMGlobalFailTimeoutCallFunction ~= nil) then
    if (UMMGlobalFailTimeout > 0) then
      UMMGlobalFailTimeout = UMMGlobalFailTimeout - elapsedTime;
      if (UMMGlobalFailTimeout <= 0) then
        UMMGlobalFailTimeout = 0;
        UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_AUTOMATIONFAILED);
        getglobal(UMMGlobalFailTimeoutCallFunction):TimeOutFailed();
        if (UMMFrameTab3Status:IsVisible()) then
          UMMFrameTab3Status:Hide();
        end
      end
    end
  end
  if (UMMGlobalInboxLoadTimeout > 0) then
    UMMGlobalInboxLoadTimeout = UMMGlobalInboxLoadTimeout - elapsedTime;
    if (UMMGlobalInboxLoadTimeout <= 0) then
      UMMGlobalInboxLoadTimeout = 0;
      UMMMasterFrame_OnEvent("MAIL_INBOX_UPDATE");
    end
  end
end

-- ##### Slash command handling #####

SLASH_UMM1 = "/umm";
SlashCmdList["UMM"] = function(editBox, msg)
  if (not msg or msg == "") then
    UMMPrompt(UMM_SLASH_HELP1);
    UMMPrompt(UMM_SLASH_HELP2);
    UMMPrompt(UMM_SLASH_HELP3);
  elseif (string.lower(msg) == "sound") then
    if (UMMSettings:Get("AudioWarning") == true) then
      UMMSettings:Set("AudioWarning", false);
      UMMPrompt(UMM_SLASH_AUDIODISABLED);
    else
      UMMSettings:Set("AudioWarning", true);
      UMMPrompt(UMM_SLASH_AUDIOENABLED);
    end
  elseif (string.lower(msg) == "reset") then
    UMMConfig.Characters = {};
    UMMSettings:CheckCharacter();
    UMMSettings:Save();
    UMMPrompt(UMM_SLASH_CHARSRESET);
  end
end
