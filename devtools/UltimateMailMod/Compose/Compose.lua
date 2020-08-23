
-- #########################
-- ##                     ##
-- ##  New Mail Composer  ##
-- ##                     ##
-- #########################

UMMMailComposer = {

  priv_Recipient          = nil;
  priv_Subject            = nil;
  priv_Body               = nil;
  priv_DefinedCODAmount   = 0;
  priv_AttachedMoney      = 0;
  priv_AttachedItemIndex  = 0;
  priv_ComposerReturn     = nil;

  priv_AutoRunning        = nil;
  priv_AutoBuildNext      = nil;

  ItemIsBound = function(self, index)
    local result = nil;

    local itemLink = GetBagItemLink(index);
    if (itemLink) then
      UMMTooltip:SetHyperLink(itemLink);
      UMMTooltip:Hide();
      for i = 1, 40 do
        local lineLeft = getglobal("UMMTooltipTextLeft"..i);
        local lineRight = getglobal("UMMTooltipTextRight"..i);
        local textLeft, textRight = "", "";
        if (lineLeft:IsVisible()) then
          textLeft = lineLeft:GetText();
        end
        if (lineRight:IsVisible()) then
          textRight = lineRight:GetText();
        end
        if (textLeft == nil) then
          textLeft = "";
        end
        if (textRight == nil) then
          textRight = "";
        end
        local tipLine = textLeft.." "..textRight;
        if (string.find(tipLine, UMM_TOOLTIP_BOUND)) then
          result = true;
        end
      end
    end

    return result;
  end;

  Clear = function(self)
    self.priv_Recipient = nil;
    self.priv_Subject = nil;
    self.priv_Body = nil;
    self.priv_DefinedCODAmount = 0;
    self.priv_AttachedMoney = 0;
    self.priv_AttachedItemIndex = 0;
    self.priv_ComposerReturn = nil;
    self.priv_AutoRunning = nil;
    self.priv_AutoBuildNext = nil;
  end;

  SetComposer = function(self, frameName)
    self.priv_ComposerReturn = frameName;
  end;

  Recipient = function(self, value)
    if (value) then
      self.priv_Recipient = value;
    else
      return self.priv_Recipient;
    end
  end;

  Subject = function(self, value)
    if (value) then
      self.priv_Subject = value;
    else
      return self.priv_Subject;
    end
  end;

  Body = function(self, value)
    if (value) then
      self.priv_Body = value;
    else
      return self.priv_Body;
    end
  end;

  DefinedCODAmount = function(self, value)
    if (value) then
      self.priv_DefinedCODAmount = value;
    else
      return self.priv_DefinedCODAmount;
    end
  end;

  AttachedMoney = function(self, value)
    if (value) then
      self.priv_AttachedMoney = value;
    else
      return self.priv_AttachedMoney;
    end
  end;

  AttachedItemIndex = function(self, value)
    if (value) then
      self.priv_AttachedItemIndex = value;
    else
      return self.priv_AttachedItemIndex;
    end
  end;

  AutoBuildMail = function(self)
    UMMGlobalFailTimeout = 0;
    if (self.priv_AutoBuildNext == "Item") then
      if (self.priv_DefinedCODAmount > 0) then
        self.priv_AutoBuildNext = "COD";
      elseif (self.priv_AttachedMoney > 0) then
        self.priv_AutoBuildNext = "Money";
      else
        self.priv_AutoBuildNext = "Send";
      end
      PickupBagItem(self.priv_AttachedItemIndex);
      ClickSendMailItemButton();
    elseif (self.priv_AutoBuildNext == "Money" or self.priv_AutoBuildNext == "COD") then
      if (self.priv_AttachedMoney > 0) then
        SetSendMailMoney(self.priv_AttachedMoney, 0);
      elseif (self.priv_DefinedCODAmount > 0) then
        SetSendMailCOD(self.priv_DefinedCODAmount, 0);
      end
      self.priv_AutoBuildNext = "Done";
      SendMail(self.priv_Recipient, self.priv_Subject, self.priv_Body);
    elseif (self.priv_AutoBuildNext == "Send") then
      self.priv_AutoBuildNext = "Done";
      SendMail(self.priv_Recipient, self.priv_Subject, self.priv_Body);
    end
    UMMSetGlobalFailTimeout("UMMMailComposer");
  end;

  -- Method that sends the composed mail
  -- Return values :
  --   0 = Mail seems to be in order and an attempt to send the mail was made
  --   1 = Recipient is the same as the current character: can't send
  --   2 = Subject is empty: can't send
  --   3 = Attached item is bound: can't send
  Send = function(self)
    local resultCode = 0;
    -- Figure out of the recipient is self
    if (self.priv_Recipient == UnitName("player")) then
      resultCode = 1;
    end
    if (resultCode == 0) then
      -- Check that there's a subject
      if (self.priv_Subject == "" or self.priv_Subject == "nil") then
        resultCode = 2;
      end
    end
    if (resultCode == 0) then
      -- Check if there's an attached item and if it's bound
      if (self.priv_AttachedItemIndex > 0) then
        if (self:ItemIsBound(self.priv_AttachedItemIndex)) then
          resultCode = 3;
        end
      end
    end
    if (resultCode == 0) then
      -- Ok - everything seems to be in order - go on and send the mail
      self.priv_AutoRunning = true;
      if (self.priv_AttachedItemIndex > 0) then
        self.priv_AutoBuildNext = "Item";
      elseif (self.priv_AttachedMoney > 0) then
        self.priv_AutoBuildNext = "Money";
      elseif (self.priv_DefinedCODAmount > 0) then
        self.priv_AutoBuildNext = "COD";
      else
        self.priv_AutoBuildNext = "Send";
      end
      self:AutoBuildMail();
    end
    return resultCode;
  end;

  SendInfoUpdated = function(self)
    if (self.priv_AutoRunning) then
      self:AutoBuildMail();
    end
  end;

  SendCompleted = function(self, status)
    UMMGlobalFailTimeout = 0;
    if (self.priv_AutoRunning) then
      if (self.priv_ComposerReturn) then
        local frame = getglobal(self.priv_ComposerReturn);
        frame:SendCompleted(status);
      end
    end
    self:Clear();
  end;

  TimeOutFailed = function(self)
    self:Clear();
  end;

};

function UMMComposeMailTemplate_OnLoad(this)

  this.AttachBagSlotIndex = 0;
  this.AttachItemLink     = nil;
  this.AttachItemIcon     = nil;
  this.AttachItemCount    = 0;
  this.AttachMoney        = 0;
  this.CODMoney           = 0;
  this.AutoSubject        = nil;

  this.CheckSendStatus = function(self)
    local recipient = getglobal(self:GetName().."HeaderAuthor"):GetText();
    local subject = getglobal(self:GetName().."HeaderSubject"):GetText();
    if (subject == nil or subject == "" and not self.AutoSubject) then
      if (getglobal(self:GetName().."FooterOptionMoney"):IsChecked()) then
        self.AutoSubject = true;
      end
    end
    if (self.AutoSubject) then
      if (getglobal(self:GetName().."FooterOptionMoney"):IsChecked()) then
        local money = getglobal(self:GetName().."FooterMoney"):GetText();
        if (money ~= nil and money ~= "") then
          local crap = string.format("%d", money + 1);
          crap = crap - 1;
          if (crap > 0) then
            subject = UMM_COMPOSER_AUTOSUBJECT..UMMFormatNumber(money);
            getglobal(self:GetName().."HeaderSubject"):SetText(subject);
          end
        else
          self.AutoSubject = nil;
          getglobal(self:GetName().."HeaderSubject"):SetText("");
        end
      end
    end
    if (recipient ~= nil and recipient ~= "" and subject ~= nil and subject ~= "") then
      getglobal(self:GetName().."Send"):Enable();
    else
      getglobal(self:GetName().."Send"):Disable();
    end
    if (self.AttachBagSlotIndex == 0) then
      getglobal(self:GetName().."FooterOptionCOD"):Disable();
    else
      getglobal(self:GetName().."FooterOptionCOD"):Enable();
    end
  end;

  this.SetRecipient = function(self, name)
    getglobal(self:GetName().."HeaderAuthor"):SetText(name);
    self:CheckSendStatus();
  end;

  this.SetSubject = function(self, subject)
    getglobal(self:GetName().."HeaderSubject"):SetText(subject);
    self:CheckSendStatus();
  end;

  this.SetBody = function(self, body)
    getglobal(self:GetName().."BodyFrameInput"):SetText(body);
    self:CheckSendStatus();
  end;

  this.SetReply = function(self, name, subject)
    getglobal(self:GetParent():GetName().."Own"):Hide();
    getglobal(self:GetParent():GetName().."Friends"):Hide();
    getglobal(self:GetParent():GetName().."Guildies"):Hide();
    self:SetRecipient(name);
    self:SetSubject(subject);
    getglobal(self:GetParent():GetName().."ViewerReply"):Disable();
    getglobal(self:GetParent():GetName().."ViewerReturn"):Disable();
    getglobal(self:GetParent():GetName().."ViewerDelete"):Disable();
    getglobal(self:GetParent():GetName().."ViewerClose"):Disable();
    getglobal(self:GetParent():GetName().."ViewerFooterAttachment1"):Disable();
    getglobal(self:GetParent():GetName().."ViewerFooterAttachment2"):Disable();
    getglobal(self:GetParent():GetName().."ViewerFooterAcceptCODCheck"):Disable();
  end;

  this.SetOption = function(self, type, dontFocus)
    if (string.lower(type) == "money") then
      getglobal(self:GetName().."FooterOptionMoney"):SetChecked(1);
      getglobal(self:GetName().."FooterMoney"):SetText("");
      getglobal(self:GetName().."FooterMoney"):Show();
      getglobal(self:GetName().."FooterOptionCOD"):SetChecked(nil);
      getglobal(self:GetName().."FooterCOD"):SetText("");
      getglobal(self:GetName().."FooterCOD"):Hide();
    elseif (string.lower(type) == "cod") then
      getglobal(self:GetName().."FooterOptionMoney"):SetChecked(nil);
      getglobal(self:GetName().."FooterMoney"):SetText("");
      getglobal(self:GetName().."FooterMoney"):Hide();
      getglobal(self:GetName().."FooterOptionCOD"):SetChecked(1);
      getglobal(self:GetName().."FooterCOD"):SetText("");
      getglobal(self:GetName().."FooterCOD"):Show();
    end
  end;

  this.ClearMail = function(self, full)
    if (full) then
      getglobal(self:GetName().."HeaderAuthor"):SetText("");
    end
    self.AttachBagSlotIndex = 0;
    self.AttachItemLink     = nil;
    self.AttachItemIcon     = nil;
    self.AttachItemCount    = 0;
    self.AttachMoney        = 0;
    self.CODMoney           = 0;
    self.AutoSubject        = nil;
    SetItemButtonTexture(getglobal(self:GetName().."FooterAttachment"), nil);
    SetItemButtonCount(getglobal(self:GetName().."FooterAttachment"), nil);

    getglobal(self:GetName().."HeaderSubject"):SetText("");
    getglobal(self:GetName().."BodyFrameInput"):SetText("");
    self:SetOption("money", true);
    self:CheckSendStatus();

    getglobal(self:GetParent():GetName().."Own"):Show();
    getglobal(self:GetParent():GetName().."Friends"):Show();
    if (IsInGuild()) then
      getglobal(self:GetParent():GetName().."Guildies"):Show();
    else
      getglobal(self:GetParent():GetName().."Guildies"):Hide();
    end
    getglobal(self:GetParent():GetName().."Viewer"):Hide();
    UMMMailComposer:Clear();
  end;

  this.ClearAllEditFocus = function(self)
    getglobal(self:GetName().."HeaderAuthor"):ClearFocus();
    getglobal(self:GetName().."HeaderSubject"):ClearFocus();
    getglobal(self:GetName().."BodyFrameInput"):ClearFocus();
    getglobal(self:GetName().."FooterMoney"):ClearFocus();
    getglobal(self:GetName().."FooterCOD"):ClearFocus();
  end;

  this.DisableComposer = function(self)
    self:ClearAllEditFocus();
    getglobal(self:GetName().."HeaderAuthor"):Disable();
    getglobal(self:GetName().."HeaderSubject"):Disable();
    getglobal(self:GetName().."Reset"):Disable();
    getglobal(self:GetName().."Send"):Disable();
    getglobal(self:GetName().."BodyFrameInput"):Disable();
    getglobal(self:GetName().."FooterAttachment"):Disable();
    getglobal(self:GetName().."FooterOptionMoney"):Disable();
    getglobal(self:GetName().."FooterOptionCOD"):Disable();
    getglobal(self:GetName().."FooterMoney"):Disable();
    getglobal(self:GetName().."FooterCOD"):Disable();
  end;

  this.EnableComposer = function(self)
    getglobal(self:GetName().."HeaderAuthor"):Enable();
    getglobal(self:GetName().."HeaderSubject"):Enable();
    getglobal(self:GetName().."Reset"):Enable();
    getglobal(self:GetName().."Send"):Enable();
    getglobal(self:GetName().."BodyFrameInput"):Enable();
    getglobal(self:GetName().."FooterAttachment"):Enable();
    getglobal(self:GetName().."FooterOptionMoney"):Enable();
    getglobal(self:GetName().."FooterOptionCOD"):Enable();
    getglobal(self:GetName().."FooterMoney"):Enable();
    getglobal(self:GetName().."FooterCOD"):Enable();
  end;

  this.Send = function(self)
    local recipient = getglobal(self:GetName().."HeaderAuthor"):GetText();
    local subject = getglobal(self:GetName().."HeaderSubject"):GetText();
    local body = getglobal(self:GetName().."BodyFrameInput"):GetText();
    UMMMailComposer:Clear();
    UMMMailComposer:SetComposer(self:GetName());
    UMMMailComposer:Recipient(recipient);
    UMMMailComposer:Subject(subject);
    UMMMailComposer:Body(body);
    if (getglobal(self:GetName().."FooterOptionCOD"):IsChecked()) then
      local money = getglobal(self:GetName().."FooterCOD"):GetText();
      if (money ~= nil and money ~= "") then
        local cash = string.format("%d", money + 1);
        cash = cash - 1;
        if (cash > 0) then
          UMMMailComposer:DefinedCODAmount(cash);
        end
      end
    else
      local money = getglobal(self:GetName().."FooterMoney"):GetText();
      if (money ~= nil and money ~= "") then
        local cash = string.format("%d", money + 1);
        cash = cash - 1;
        if (cash > 0) then
          UMMMailComposer:AttachedMoney(cash);
        end
      end
    end
    if (self.AttachBagSlotIndex > 0) then
      UMMMailComposer:AttachedItemIndex(self.AttachBagSlotIndex);
    end
    local result = UMMMailComposer:Send();
    if (result == 0) then
      self:DisableComposer();
    elseif (result == 1) then
      -- Recipient
      UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_CANTSENDSELF);
      WarningFrame:AddMessage(UMM_ERROR_CANTSENDSELF);
    elseif (result == 2) then
      -- Subject
      UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_NOSUBJECT);
      WarningFrame:AddMessage(UMM_ERROR_NOSUBJECT);
    elseif (result == 3) then
      -- Bound
      UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_CANTSENDBOUND);
      WarningFrame:AddMessage(UMM_ERROR_CANTSENDBOUND);
      self:RemoveAttachment();
    end
  end;

  this.SendCompleted = function(self, status)
    self:EnableComposer();
    if (status == "ok") then
      self:ClearMail();
    end
  end;

  this.RemoveAttachment = function(self)
    self.AttachBagSlotIndex = 0;
    self.AttachItemLink     = nil;
    self.AttachItemIcon     = nil;
    self.AttachItemCount    = 0;
    SetItemButtonTexture(getglobal(self:GetName().."FooterAttachment"), nil);
    SetItemButtonCount(getglobal(self:GetName().."FooterAttachment"), nil);
    self:SetOption("money", true);
    getglobal(self:GetName().."FooterOptionCOD"):Disable();
  end;

  this.AttachItem = function(self)
    local bagSlotIndex = 0;

	local slotIndex = GetCursorItemInfo();

    if (slotIndex ~= nil and slotIndex ~= "") then
      local bsi = string.format("%d", slotIndex + 1);
      bsi = bsi - 1;
      bagSlotIndex = bsi;
    else
      bagSlotIndex = -1;
    end
    if (bagSlotIndex == -1) then
      -- Do nothing
    elseif (bagSlotIndex == 0) then
      UMMPrompt("|r|cff"..UMMColor.Reg.."Internal Frogster bag error ! Please expand your backpack and move a few items.");
    else
      local item = UMMBagManager:GetItem(bagSlotIndex);
      if (item) then
        if (not item.Empty == true) then
          self:RemoveAttachment();
          self.AttachBagSlotIndex = bagSlotIndex;
          self.AttachItemLink = item.Link;
          self.AttachItemIcon = item.Icon;
          self.AttachItemCount = item.Count;
          SetItemButtonTexture(getglobal(self:GetName().."FooterAttachment"), self.AttachItemIcon);
          SetItemButtonCount(getglobal(self:GetName().."FooterAttachment"), self.AttachItemCount);
          PickupBagItem(bagSlotIndex);
          if (item.Count > 1) then
            self:SetSubject(item.Name.." ("..item.Count..")");
          else
            self:SetSubject(item.Name);
          end
          getglobal(self:GetName().."FooterOptionCOD"):Enable();
        end
      end
    end
  end;

  this.AttachEnter = function(self)
    if (self.AttachItemLink ~= nil) then
      GameTooltip:ClearAllAnchors();
      GameTooltip:SetAnchor("TOPLEFT", "BOTTOMRIGHT", self:GetName().."FooterAttachment", 2, 0);
      GameTooltip:Show();
      GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", 0, 0);
      GameTooltip:SetHyperLink(self.AttachItemLink);
    end
  end;

  this.AttachLeave = function(self)
    GameTooltip:Hide();
  end;

  this.ViewerClosed = function(self)
    -- Place holder for return signal when the viewer is closed.
  end;

  getglobal(this:GetName().."HeaderAuthorLabel"):SetText("|cff"..UMMColor.White..UMM_COMPOSER_ADDRESSEE.."|r");
  getglobal(this:GetName().."HeaderSubjectLabel"):SetText("|cff"..UMMColor.White..UMM_COMPOSER_SUBJECT.."|r");
  getglobal(this:GetName().."Reset"):SetText(UMM_COMPOSER_BUTTON_RESET);
  UMMAutoResizeWidth(getglobal(this:GetName().."Reset"),70)
  getglobal(this:GetName().."Send"):SetText(UMM_COMPOSER_BUTTON_SEND);
  UMMAutoResizeWidth(getglobal(this:GetName().."Send"),70)
  getglobal(this:GetName().."FooterAttachmentLabel"):SetText("|cff"..UMMColor.White..UMM_COMPOSER_ATTACHMENT.."|r");
  getglobal(this:GetName().."FooterOptionMoneyLabel"):SetText("|cff"..UMMColor.White..UMM_COMPOSER_SENDGOLD.."|r");
  getglobal(this:GetName().."FooterOptionCODLabel"):SetText("|cff"..UMMColor.White..UMM_COMPOSER_SENDCOD.."|r");
end

function UMMComposeMailTemplate_OnShow(this)
  this:ClearMail(true);
  this:CheckSendStatus();
end

function UMMComposeMailTemplate_OnHide(this)
  this:ClearMail();
  this:EnableComposer();
  this:ClearAllEditFocus();
end

function UMMComposeMailTemplateButton_OnClick(this, action)
  if (string.lower(action) == "reset") then
    this:GetParent():ClearMail();
  elseif (string.lower(action) == "send") then
    local moneyAttached = nil;
    local money = getglobal(this:GetParent():GetName().."FooterMoney"):GetText();
    if (money ~= nil and money ~= "") then
      local cash = string.format("%d", money + 1);
      cash = cash - 1;
      if (cash > 0) then
        moneyAttached = tonumber(cash);
      end
    end
    if (moneyAttached) then
      local recipient = getglobal(this:GetParent():GetName().."HeaderAuthor"):GetText();
      UMMComposeConfirm:Clear();
      UMMComposeConfirm:AddLine(UMM_COMPOSER_CONFIRM_TEXT1);
      UMMComposeConfirm:AddLine(string.format(UMM_COMPOSER_CONFIRM_TEXT2, recipient));
      UMMComposeConfirm:SetMoney(moneyAttached);
      UMMComposeConfirm:AddButton(UMM_COMPOSER_CONFIRM_YES, function()
        this:GetParent():Send();
      end);
      UMMComposeConfirm:AddButton(UMM_COMPOSER_CONFIRM_NO);
      UMMComposeConfirm:Pop();
    else
      this:GetParent():Send();
    end
  end
end

function UMMComposeTemplate_OnShow(this)
  UMMFriends:Load();
end

function UMMComposeTemplate_OnHide(this)
  getglobal(this:GetName().."Composer"):EnableComposer();
  getglobal(this:GetName().."Composer"):ClearAllEditFocus();
  UMMComposeConfirm:Clear();
end
