
-- ###################################
-- ##                               ##
-- ##  Main Ultimate Mail Mod Menu  ##
-- ##                               ##
-- ###################################

local hideMailFrame = true;

local function SetupTabs(this)
  local i, tab, tabBody, title;

  for i = 1, 3 do
    tab = getglobal(this:GetName().."Tab"..i.."Button");
    tabBody = getglobal(this:GetName().."Tab"..i);
    title = getglobal("UMM_MENU_TAB"..i);
    tab:ClearAllAnchors();
    if (i == 1) then
      tab:SetAnchor("TOPLEFT", "TOPLEFT", this:GetName(), 10, 30);
    else
      tab:SetAnchor("TOPLEFT", "TOPRIGHT", this:GetName().."Tab"..(i-1).."Button", 0, 0);
    end
    tab:SetText(title);
    PanelTemplates_TabResize(tab, 9.5/GetUIScale())
    tab:Show();
    tabBody:ClearAllAnchors();
    tabBody:SetAnchor("TOPLEFT", "TOPLEFT", "UMMFrameBody", 5, 5);
  end
end

function UMMMenuSelectTab(id)
  local i, tab, tabBody;

  for i = 1, 3 do
    tab = getglobal("UMMFrameTab"..i.."Button");
    tabBody = getglobal("UMMFrameTab"..i);
    if (i == id) then
      UIPanelTab_SetActiveState(tab, true);
      tabBody:Show();
    else
      UIPanelTab_SetActiveState(tab, false);
      tabBody:Hide();
    end
  end
end

function UMMMenuTabTemplate_OnLoad(this)
  this:RegisterForClicks("LeftButton", "RightButton");
end

function UMMMenuTabTemplate_OnClick(this)
  UMMMenuSelectTab(this:GetID());
end

function UMMFrame_OnLoad(this)
  getglobal(this:GetName().."Title"):SetText("|cff"..UMMColor.Medium..UMM_TITLE.."|r");
  SetupTabs(this);

  this.CheckSetting = function(self, checkBox, entry)
    if (checkBox:IsChecked()) then
      UMMSettings:Set(entry, true);
    else
      UMMSettings:Set(entry, false);
    end
  end;

end

function UMMFrame_OnShow(this)
  UMMFriends:Load();
  UMMGlobalInboxLoadTimeout = 2.3;
  getglobal(this:GetName().."Tab1TOC"):HideTOC();
  getglobal(this:GetName().."Tab1Tools"):Hide();
  getglobal(this:GetName().."Tab1Tools"):SetOption(1);
  getglobal(this:GetName().."Tab1InfoLabel"):SetText("|cff"..UMMColor.Medium..UMM_INBOX_LOADING.."|r");
  UMMNormalBar:Init();
  UMMNormalBar:Show();
  if (hideMailFrame) then
    MailFrame:ClearAllAnchors();
    MailFrame:SetAnchor("TOPRIGHT", "TOPLEFT", "UIParent", 0, 110);
  end
  UMMBagManager:Load();
  UMMFriends:Load();
  UMMMenuSelectTab(1);
  if (UMMConfig.Settings.AudioWarning == true) then
    getglobal(this:GetName().."SettingAudioAlert"):SetChecked(1);
  else
    getglobal(this:GetName().."SettingAudioAlert"):SetChecked(nil);
  end
end

function UMMFrame_OnHide(this)
  HideUIPanel(MailFrame);
  UMMMailManager:StopAutomation();
  UMMMailManager:Clear();
  UMMFriends:Clear();
  if (hideMailFrame) then
    MailFrame:ClearAllAnchors();
    MailFrame:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", 0, 110);
  end
  getglobal(this:GetName().."Tab1Tools"):Hide();
  getglobal(this:GetName().."Tab1TOC"):HideTOC();
  getglobal(this:GetName().."Tab2Composer"):ClearAllEditFocus();
  getglobal(this:GetName().."Tab3Status"):Clear();
end
