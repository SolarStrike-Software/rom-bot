-- #############
-- ##         ##
-- ##  Inbox  ##
-- ##         ##
-- #############

local mailSlotCount = 18; -- Number of slots in the inbox TOC

function UMMInboxTOCTemplate_OnLoad(this)

  this.RefreshTOC = function(self)
    local offset = UMMMailManager.InboxOffset;
    for i = 1, mailSlotCount do
      local button = _G[self:GetName().."Mail"..i]
      index = i + offset;
      if (index <= UMMMailManager.MailCount) then
        local mail = UMMMailManager.Mails[index];
        if (mail.Tagged == true) then
          _G[button:GetName().."Tagged"]:Show()
        else
          _G[button:GetName().."Tagged"]:Hide()
        end
        getglobal(button:GetName().."Author"):SetText("|cff"..UMMFriends:GetColor(mail.Author, true)..(mail.Author or "").."|r");
        local buttonIcon = getglobal(button:GetName().."Button");
        SetItemButtonTexture(buttonIcon, mail.Icon);
        if (mail.AttachedMoney > 0 or mail.AttachedDiamonds > 0) then
          getglobal(button:GetName().."Subject"):Hide();
          getglobal(button:GetName().."SmallSubject"):Show();
          if (mail.AttachedMoney > 0) then
            getglobal(button:GetName().."AttachedMoney"):Show();
            getglobal(button:GetName().."AttachedDiamonds"):Hide();
            getglobal(button:GetName().."AttachedMoney"):SetAmount(mail.AttachedMoney, "gold");
          elseif (mail.AttachedDiamonds > 0) then
            getglobal(button:GetName().."AttachedMoney"):Hide();
            getglobal(button:GetName().."AttachedDiamonds"):Show();
            getglobal(button:GetName().."AttachedDiamonds"):SetAmount(mail.AttachedDiamonds, "diamond");
          end
          if (mail.WasRead == true) then
            getglobal(button:GetName().."SmallSubject"):SetText("|cff"..UMMColor.Grey..mail.Subject.."|r");
          else
            getglobal(button:GetName().."SmallSubject"):SetText("|cff"..UMMColor.White..mail.Subject.."|r");
          end
        else
          getglobal(button:GetName().."Subject"):Show();
          getglobal(button:GetName().."SmallSubject"):Hide();
          getglobal(button:GetName().."AttachedMoney"):Hide();
          getglobal(button:GetName().."AttachedDiamonds"):Hide();
          if (mail.CODAmount > 0) then
            getglobal(button:GetName().."Subject"):SetText("|cff"..UMMColor.Yellow..mail.Subject.."|r");
          else
            if (mail.WasRead == true) then
              getglobal(button:GetName().."Subject"):SetText("|cff"..UMMColor.Grey..mail.Subject.."|r");
            else
              getglobal(button:GetName().."Subject"):SetText("|cff"..UMMColor.White..mail.Subject.."|r");
            end
          end
        end
        local DaysLeft = mail.DaysLeft;
        local DaysLeftColor = UMMColor.Green;
        if (DaysLeft < 1.0) then
          DaysLeft = DaysLeft * 24;
          DaysLeft = string.format("%d", DaysLeft);
          if (DaysLeft == 1) then
            DaysLeft = DaysLeft.." "..HOUR;
          else
            DaysLeft = DaysLeft.." "..HOURS;
          end
          DaysLeftColor = UMMColor.Red;
        else
          DaysLeft = string.format("%d", DaysLeft) + 1;
          if (DaysLeft == 1) then
            DaysLeft = DaysLeft.." "..DAY;
            DaysLeftColor = UMMColor.Red;
          elseif (DaysLeft == 2) then
            DaysLeft = DaysLeft.." "..DAYS;
            DaysLeftColor = UMMColor.Yellow;
          else
            DaysLeft = DaysLeft.." "..DAYS;
            DaysLeftColor = UMMColor.Green;
          end
        end
        getglobal(button:GetName().."DaysLeft"):SetText("|cff"..DaysLeftColor..DaysLeft.."|r");
        button:Show();
      else
        button:Hide();
      end
    end

    if (UMMMailManager.InboxTotalMoney > 0) then
      getglobal(self:GetParent():GetName().."ToolsTotalMoneyLabel"):Show();
      getglobal(self:GetParent():GetName().."ToolsTotalMoney"):SetAmount(UMMMailManager.InboxTotalMoney, "gold");
    else
      getglobal(self:GetParent():GetName().."ToolsTotalMoneyLabel"):Hide();
      getglobal(self:GetParent():GetName().."ToolsTotalMoney"):Hide();
    end
    if (UMMMailManager.InboxTotalDiamonds > 0) then
      getglobal(self:GetParent():GetName().."ToolsTotalDiamondsLabel"):Show();
      getglobal(self:GetParent():GetName().."ToolsTotalDiamonds"):SetAmount(UMMMailManager.InboxTotalDiamonds, "diamond");
    else
      getglobal(self:GetParent():GetName().."ToolsTotalDiamondsLabel"):Hide();
      getglobal(self:GetParent():GetName().."ToolsTotalDiamonds"):Hide();
    end

    if (UMMMailManager.MailCount > mailSlotCount) then
      getglobal(self:GetName().."Scroll"):SetMaxValue(UMMMailManager.MailCount - mailSlotCount);
      getglobal(self:GetName().."Scroll"):SetValue(UMMMailManager.InboxOffset);
      getglobal(self:GetName().."Scroll"):Show();
    else
      getglobal(self:GetName().."Scroll"):Hide();
    end

    if (UMMMailManager.MailCount == 0) then
      getglobal(self:GetParent():GetName().."Tools"):Hide();
      getglobal(self:GetParent():GetName().."InfoLabel"):SetText("|cff"..UMMColor.Medium..UMM_INBOX_EMPTY.."|r");
    else
      getglobal(self:GetParent():GetName().."InfoLabel"):SetText("");
      if (getglobal(self:GetParent():GetName().."Viewer"):IsVisible()) then
      else
        getglobal(self:GetParent():GetName().."Tools"):CheckSelection();
      end
    end
  end;

  this.ScrollChanged = function(self)
    UMMMailManager.InboxOffset = getglobal(self:GetName().."Scroll"):GetValue();
    self:RefreshTOC();
  end;

  this.ViewerClosed = function(self)
    UMMMailManager:UnTagAll();
    self:RefreshTOC();
    getglobal(self:GetParent():GetName().."Tools"):CheckSelection();
  end;

  this.HideTOC = function(self)
    for i = 1, mailSlotCount do
      getglobal(self:GetName().."Mail"..i):Hide();
    end
    getglobal(self:GetName().."Scroll"):Hide();
    getglobal(self:GetParent():GetName().."Tools"):Hide();
  end;

  this.ShowInboxStatus = function(self)
    if (UMMMailManager.MailCount == 0) then
      getglobal(self:GetParent():GetName().."InfoLabel"):SetText("|cff"..UMMColor.Medium..UMM_INBOX_EMPTY.."|r");
      getglobal(self:GetParent():GetName().."Tools"):Hide();
    else
      getglobal(self:GetParent():GetName().."InfoLabel"):SetText("");
    end
  end;

  this.Lock = function(self)
    for i = 1, mailSlotCount do
      getglobal(self:GetName().."Mail"..i):Disable();
    end
    getglobal(self:GetName().."Scroll"):Disable();
    getglobal(self:GetParent():GetName().."Tools"):Lock();
  end;

  this.UnLock = function(self)
    for i = 1, mailSlotCount do
      getglobal(self:GetName().."Mail"..i):Enable();
    end
    getglobal(self:GetName().."Scroll"):Enable();
    getglobal(self:GetParent():GetName().."Tools"):UnLock();
  end;

  for i = 1, mailSlotCount do
    local mail = getglobal(this:GetName().."Mail"..i);
    mail:ClearAllAnchors();
    mail:SetAnchor("TOPLEFT", "TOPLEFT", this:GetName(), 0, ((i * 25) - 25));
    mail:Hide();
  end
end

function UMMInboxTOCTemplate_OnShow(this)
  UMMFriends:Load();
  UMMBagManager:Load();
  UMMMailManager:ShowInbox();
  getglobal(this:GetName().."Scroll"):SetValue(UMMMailManager.InboxOffset);
  this:RefreshTOC();
  if (UMMMailManager.MailCount == 0) then
    getglobal(this:GetParent():GetName().."Tools"):Hide();
  else
    getglobal(this:GetParent():GetName().."Tools"):Show();
  end
end

function UMMInboxTOCTemplate_OnHide(this)
  this:HideTOC();
  UMMMailManager:HideInbox();
end

function UMMInboxToolsTemplate_OnLoad(this)

  this.SetOption = function(self, id)
    for i = 1, 4 do
      getglobal(self:GetName().."Option"..i):SetChecked(nil);
      getglobal(self:GetName().."Option"..i.."Label"):SetText("|cff"..UMMColor.Grey.._G["UMM_INBOX_OPTION_"..i].."|r")
    end
    getglobal(self:GetName().."Option"..id):SetChecked(1);
    getglobal(self:GetName().."Option"..id.."Label"):SetText("|cff"..UMMColor.White..getglobal("UMM_INBOX_OPTION_"..id).."|r");
  end;

  this.CheckSelection = function(self, viewer)
    local tagCount = UMMMailManager:GetTagCount();
    if (tagCount == 0) then
      if (UMMMailManager.MailCount > 0) then
        self:Show();
      else
        self:Hide();
      end
      getglobal(self:GetName().."ButtonReturn"):Disable();
      getglobal(self:GetName().."ButtonDelete"):Disable();
    elseif (tagCount == 1) then
      if (viewer) then
        self:Hide();
      else
        self:Show();
        if (UMMMailManager:CanMassReturn()) then
          getglobal(self:GetName().."ButtonReturn"):Enable();
        else
          getglobal(self:GetName().."ButtonReturn"):Disable();
        end
        if (UMMMailManager:CanMassDelete()) then
          getglobal(self:GetName().."ButtonDelete"):Enable();
        else
          getglobal(self:GetName().."ButtonDelete"):Disable();
        end
      end
    else
      self:Show();
      if (UMMMailManager:CanMassReturn()) then
        getglobal(self:GetName().."ButtonReturn"):Enable();
      else
        getglobal(self:GetName().."ButtonReturn"):Disable();
      end
      if (UMMMailManager:CanMassDelete()) then
        getglobal(self:GetName().."ButtonDelete"):Enable();
      else
        getglobal(self:GetName().."ButtonDelete"):Disable();
      end
      if (getglobal(self:GetParent():GetName().."Viewer"):IsVisible()) then
        getglobal(self:GetParent():GetName().."Viewer"):Hide();
      end
    end
  end;

  this.ButtonClick = function(self, action)
    if (string.lower(action) == "tagchars") then
      UMMMailManager:MassTagMails("chars");
      getglobal(self:GetParent():GetName().."TOC"):RefreshTOC();
    elseif (string.lower(action) == "tagguildies") then
      UMMMailManager:MassTagMails("guildies");
      getglobal(self:GetParent():GetName().."TOC"):RefreshTOC();
    elseif (string.lower(action) == "tagfriends") then
      UMMMailManager:MassTagMails("friends");
      getglobal(self:GetParent():GetName().."TOC"):RefreshTOC();
    elseif (string.lower(action) == "tagother") then
      UMMMailManager:MassTagMails("other");
      getglobal(self:GetParent():GetName().."TOC"):RefreshTOC();
    elseif (string.lower(action) == "tagempty") then
      UMMMailManager:MassTagMails("empty");
      getglobal(self:GetParent():GetName().."TOC"):RefreshTOC();
    else
      UMMMailManager:StartAutomation(action);
    end
    self:CheckSelection();
  end;

  this.Lock = function(self)
    getglobal(self:GetName().."ButtonTake"):Disable();
    getglobal(self:GetName().."ButtonReturn"):Disable();
    getglobal(self:GetName().."ButtonDelete"):Disable();
    for i = 1, 4 do
      getglobal(self:GetName().."Option"..i):Disable();
    end
    getglobal(self:GetName().."ButtonTagChars"):Disable();
    getglobal(self:GetName().."ButtonTagFriends"):Disable();
    getglobal(self:GetName().."ButtonTagGuildies"):Disable();
    getglobal(self:GetName().."ButtonTagOther"):Disable();
    getglobal(self:GetName().."ButtonTagEmpty"):Disable();
    getglobal(self:GetName().."CheckTakeDeleteEmpty"):Disable();
  end;

  this.UnLock = function(self)
    getglobal(self:GetName().."ButtonTake"):Enable();
    for i = 1, 4 do
      _G[self:GetName().."Option"..i]:Enable()
	end
    getglobal(self:GetName().."ButtonTagChars"):Enable();
    getglobal(self:GetName().."ButtonTagFriends"):Enable();
    getglobal(self:GetName().."ButtonTagGuildies"):Enable();
    getglobal(self:GetName().."ButtonTagOther"):Enable();
    getglobal(self:GetName().."ButtonTagEmpty"):Enable();
    getglobal(self:GetName().."CheckTakeDeleteEmpty"):Enable();
    self:CheckSelection();
  end;

  this.InitView = function(self)
    for i = 1, 5 do
      getglobal(self:GetName().."HelpLabel"..i):SetText("|cff"..UMMColor.White..getglobal("UMM_HELP_INBOX_LINE"..i).."|r");
    end
    for i = 1, 4 do
      getglobal(self:GetName().."Option"..i.."Label"):SetText("|cff"..UMMColor.White..getglobal("UMM_INBOX_OPTION_"..i).."|r");
    end

    getglobal(self:GetName().."TotalMoneyLabel"):SetText("|cff"..UMMColor.Yellow..UMM_INBOX_LABEL_TOTALMONEY.."|r");
    getglobal(self:GetName().."TotalDiamondsLabel"):SetText("|cff"..UMMColor.Bright..UMM_INBOX_LABEL_TOTALDIAMONDS.."|r");
    getglobal(self:GetName().."CheckTakeDeleteEmptyLabel"):SetText("|cff"..UMMColor.White..UMM_INBOX_CHECK_DELETEDONE.."|r");
    getglobal(self:GetName().."MassTagLabel"):SetText("|cff"..UMMColor.White..UMM_INBOX_LABEL_MASSTAG.."|r");
    getglobal(self:GetName().."ButtonTagChars"):SetText(UMM_INBOX_BUTTON_TAGCHARS);
    getglobal(self:GetName().."ButtonTagFriends"):SetText(UMM_INBOX_BUTTON_TAGFRIENDS);
    getglobal(self:GetName().."ButtonTagGuildies"):SetText(UMM_INBOX_BUTTON_TAGGUILDIES);
    getglobal(self:GetName().."ButtonTagOther"):SetText(UMM_INBOX_BUTTON_TAGOTHER);
    getglobal(self:GetName().."ButtonTagEmpty"):SetText(UMM_INBOX_BUTTON_TAGEMPTY);
    getglobal(self:GetName().."ButtonTake"):SetText(UMM_INBOX_BUTTON_TAKE);
    getglobal(self:GetName().."ButtonReturn"):SetText(UMM_INBOX_BUTTON_RETURN);
    getglobal(self:GetName().."ButtonReturnLabel"):SetText("|cff"..UMMColor.White..UMM_HELP_INBOX_RETURNTAGGED.."|r");
    getglobal(self:GetName().."ButtonDelete"):SetText(UMM_INBOX_BUTTON_DELETE);
    getglobal(self:GetName().."ButtonDeleteLabel"):SetText("|cff"..UMMColor.White..UMM_HELP_INBOX_DELETETAGGED.."|r");

    getglobal(self:GetName().."TotalMoneyLabel"):Hide();
    getglobal(self:GetName().."TotalDiamondsLabel"):Hide();
    getglobal(self:GetName().."TotalMoney"):Hide();
    getglobal(self:GetName().."TotalDiamonds"):Hide();

    self:SetOption(1);
    getglobal(self:GetName().."CheckTakeDeleteEmpty"):SetChecked(1);
    getglobal(self:GetName().."ButtonReturn"):Disable();
    getglobal(self:GetName().."ButtonDelete"):Disable();
  end;

  this:InitView();

end

function UMMInboxTOCButtonTemplate_OnEnter(this)
    _G[this:GetName().."Hover"]:Show()
    local index = this:GetID() + UMMMailManager.InboxOffset
	if (IsShiftKeyDown()) then
		local packageIcon, sender, subject, COD, moneyMode, money, daysLeft, paperStyle, items, wasRead, wasReturned, canReply = GetInboxHeaderInfo(index)
		if items and (items > 0) then
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:SetInboxItem(index)
			GameTooltip:Show()
		end
	end
end

function UMMInboxTOCButtonTemplate_OnLeave(this)
  _G[this:GetName().."Hover"]:Hide()
  GameTooltip:Hide()
end

function UMMInboxTOCButtonTemplate_OnClick(this)
  if (IsCtrlKeyDown()) then
    UMMMailManager:ToggleTagByID(this:GetID());
    UMMFrameTab1Tools:CheckSelection();
  else
    UMMMailManager:UnTagAll();
    UMMMailManager:TagByID(this:GetID());
    UMMFrameTab1Tools:CheckSelection(true);
    UMMFrameTab1Tools:Hide();
    UMMFrameTab1Viewer:Display(this:GetParent():GetName(), UMMMailManager:GetSelectedMailIndex(), UMMMailManager:GetSelectedMail());
    UMMFrameTab1Viewer:Show();
  end
  UMMFrameTab1TOC:RefreshTOC();
end

function UMMInboxTOCButtonTemplate_OnLeave(this)
  getglobal(this:GetName().."Hover"):Hide();
end
