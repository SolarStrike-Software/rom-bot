
-- ###################
-- ##               ##
-- ##  Mail Viewer  ##
-- ##               ##
-- ###################

function UMMMailViewerTemplate_OnLoad(this)
  
  this.priv_ParentFrameName = nil;
  this.priv_ViewIndex       = 0;
  this.priv_Attachments     = {};
  
  this.ClearAttachments = function(self)
    self.priv_Attachments = {};
  end;
  
  this.AddAttachment = function(self, type, icon, count)
    local newItem = {};
    newItem.Type = string.lower(type);
    newItem.Icon = icon;
    newItem.Count = count;
    newItem.Link = link;
    table.insert(self.priv_Attachments, newItem);
  end;
  
  this.ShowAttachments = function(self, CODAmount)
    if (CODAmount) then
      getglobal(self:GetName().."FooterAttachmentLabel"):SetText("|cff"..UMMColor.Yellow..UMM_VIEWER_ATTACHMENTCOD.."|r");
    else
      getglobal(self:GetName().."FooterAttachmentLabel"):SetText("|cff"..UMMColor.White..UMM_VIEWER_ATTACHED.."|r");
    end
    getglobal(self:GetName().."FooterAttachmentLabel"):Show();
    local previous = getglobal(self:GetName().."FooterAttachmentLabel");
    for a = 1, 2 do
      local button = getglobal(self:GetName().."FooterAttachment"..a);
      button:Hide();
    end
    local moneyFrame = getglobal(self:GetName().."FooterMoneyFrame");
    moneyFrame:Hide();
    local diamondFrame = getglobal(self:GetName().."FooterDiamondFrame");
    diamondFrame:Hide();
    local codCheck = getglobal(self:GetName().."FooterAcceptCODCheck");
    codCheck:Hide();
    local goldAttached = false;
    local goldValue = 0;
    local diamondsAttached = false;
    local diamondValue = 0;
    for a = 1, table.getn(self.priv_Attachments) do
      local button = getglobal(self:GetName().."FooterAttachment"..a);
      SetItemButtonTexture(button, self.priv_Attachments[a].Icon);
      if (self.priv_Attachments[a].Type == "item") then
        SetItemButtonCount(button, self.priv_Attachments[a].Count);
      else
        SetItemButtonCount(button, 0);
      end
      if (self.priv_Attachments[a].Type == "gold") then
        goldAttached = true;
        goldValue = self.priv_Attachments[a].Count;
      elseif (self.priv_Attachments[a].Type == "diamond") then
        diamondsAttached = true;
        diamondValue = self.priv_Attachments[a].Count;
      end
      button:ClearAllAnchors();
      button:SetAnchor("LEFT", "RIGHT", previous:GetName(), 10, 0);
      button:Show();
      previous = button;
    end
    if (goldAttached == true) then
      moneyFrame:ClearAllAnchors();
      moneyFrame:SetAnchor("LEFT", "RIGHT", previous:GetName(), 10, 0);
      moneyFrame:SetAmount(goldValue, "gold");
    elseif (diamondsAttached == true) then
      diamondFrame:ClearAllAnchors();
      diamondFrame:SetAnchor("LEFT", "RIGHT", previous:GetName(), 10, 0);
      diamondFrame:SetAmount(diamondValue, "diamond");
    elseif CODAmount and (CODAmount > 0) then
      moneyFrame:ClearAllAnchors();
      moneyFrame:SetAnchor("LEFT", "RIGHT", previous:GetName(), 10, 10);
      moneyFrame:SetAmount(CODAmount);
      codCheck:ClearAllAnchors();
      codCheck:SetAnchor("LEFT", "RIGHT", previous:GetName(), 0, -10);
      getglobal(codCheck:GetName().."Label"):SetText("|cff"..UMMColor.White..UMM_VIEWER_ATTACHMENTACCEPT.."|r");
      codCheck:SetChecked(nil);
      codCheck:Show();
    end
    getglobal(self:GetName().."Footer"):Show();
  end;
  
  this.Display = function(self, parentFrame, mailIndex, mailObject)
    if (mailObject ~= nil) then
      self.priv_ViewIndex = mailIndex;
      self.priv_ParentFrameName = parentFrame;
      getglobal(self:GetName().."BodyFrameInput"):ClearFocus();
      getglobal(self:GetName().."HeaderAuthor"):SetText("|cff"..UMMFriends:GetColor(mailObject.Author)..mailObject.Author.."|r");
      getglobal(self:GetName().."HeaderSubject"):SetText("|cff"..UMMColor.White..mailObject.Subject.."|r");
      getglobal(self:GetName().."BodyFrameInput"):SetText(mailObject.Body);
      local bodyText, texture, isTakeable, isInvoice = GetInboxText(mailIndex);
      UMMMailManager:InboxRefresh();
      UMMMailManager.Mails[self.priv_ViewIndex].Tagged = true;
      getglobal(self:GetName().."BodyFrameInput"):SetText(bodyText);
      if (mailObject.CanReply == true) then
        getglobal(self:GetName().."Reply"):Enable();
      else
        getglobal(self:GetName().."Reply"):Disable();
      end
      if (mailObject.CODAmount + mailObject.AttachedMoney + mailObject.AttachedItems + mailObject.AttachedDiamonds > 0) then
        if (mailObject.WasReturned == true) then
          getglobal(self:GetName().."Return"):Disable();
        else
          if (mailObject.CanReply == true) then
            getglobal(self:GetName().."Return"):Enable();
          else
            getglobal(self:GetName().."Return"):Disable();
          end
        end
        getglobal(self:GetName().."Delete"):Disable();
        getglobal(self:GetName().."FooterAcceptCODCheck"):Hide();
        self:ClearAttachments();
        if (mailObject.CODAmount > 0) then
          -- C.O.D. mails
          local name, itemTexture, count = GetInboxItem(mailIndex, 1);
          self:AddAttachment("Item", itemTexture, count);
          self:ShowAttachments(mailObject.CODAmount);
        else
          if (mailObject.AttachedItems > 0 and mailObject.AttachedMoney > 0) then
            -- Gold & Item
            local name, itemTexture, count, link = GetInboxItem(mailIndex, 1);
            self:AddAttachment("Item", itemTexture, count);
            self:AddAttachment("Gold", "interface/icons/coin_03", mailObject.AttachedMoney);
            self:ShowAttachments();
          elseif (mailObject.AttachedItems > 0) then
            -- Item
            local name, itemTexture, count, link = GetInboxItem(mailIndex, 1);
            self:AddAttachment("Item", itemTexture, count);
            self:ShowAttachments();
          elseif (mailObject.AttachedMoney > 0) then
            -- Money
            self:AddAttachment("Gold", "interface/icons/coin_03", mailObject.AttachedMoney);
            self:ShowAttachments();
          elseif (mailObject.AttachedDiamonds > 0) then
            -- Diamonds
            self:AddAttachment("Diamond", "interface/icons/crystal_01", mailObject.AttachedDiamonds);
            self:ShowAttachments();
          end
        end
      else
        getglobal(self:GetName().."Footer"):Hide();
        getglobal(self:GetName().."Return"):Disable();
        getglobal(self:GetName().."Delete"):Enable();
      end
      self:Show();
    else
      self:Hide();
    end
  end;
  
  this.AttachmentOnEnter = function(self, this)
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetInboxItem(self.priv_ViewIndex)
        GameTooltip:Show()
  end

  this.AttachmentOnClick = function(self, this)
    local acceptCOD = false;
    if (UMMMailManager.Mails[self.priv_ViewIndex].CODAmount > 0) then
      if (getglobal(self:GetName().."FooterAcceptCODCheck"):IsChecked()) then
        acceptCOD = true;
      end
    end
    if (UMMMailManager:GetAttachments(self.priv_ViewIndex, acceptCOD, self:GetName())) then
      getglobal(self:GetName().."Reply"):Disable();
      getglobal(self:GetName().."Return"):Disable();
      getglobal(self:GetName().."Delete"):Disable();
      getglobal(self:GetName().."Close"):Disable();
    else
      -- COD not accepted - message already shown
    end
  end;
  
  this.AttachmentOnLeave = function(self, this)
     GameTooltip:Hide()
  end

  this.RefreshViewer = function(self)
    -- Refresh after attachment action ...
    local mailObject = UMMMailManager.Mails[self.priv_ViewIndex]
    local parentName = self.priv_ParentFrameName
    local mailIndex = self.priv_ViewIndex
    self:Display(parentName, mailIndex, mailObject)
    getglobal(self:GetName().."Close"):Enable()
  end

  this.SignalViewerClosed = function(self)
    self:ClearAttachments()
    getglobal(self:GetName().."BodyFrameInput"):ClearFocus()
    getglobal(self.priv_ParentFrameName):ViewerClosed();
    self.priv_ParentFrameName = nil;
  end;
  
  this.ButtonClick = function(self, action)
    if (string.lower(action) == "reply") then
      UMMMailManager:ReplyToMail(self.priv_ViewIndex);
      self:Hide();
    elseif (string.lower(action) == "return") then
      if (UMMMailManager:ReturnMail(self.priv_ViewIndex)) then
        self:Hide();
      end
    elseif (string.lower(action) == "delete") then
      if (UMMMailManager:DeleteMail(self.priv_ViewIndex)) then
        self:Hide();
      end
    elseif (string.lower(action) == "close") then
      self:Hide();
    end
  end;
  
  this.InitView = function(self)
    getglobal(self:GetName().."HeaderAuthorLabel"):SetText("|cff"..UMMColor.Grey..UMM_VIEWER_LABEL_FROM.."|r");
    getglobal(self:GetName().."HeaderSubjectLabel"):SetText("|cff"..UMMColor.Grey..UMM_VIEWER_LABEL_SUBJECT.."|r");
    getglobal(self:GetName().."Reply"):SetText(UMM_VIEWER_BUTTON_REPLY);
    getglobal(self:GetName().."Return"):SetText(UMM_VIEWER_BUTTON_RETURN);
    getglobal(self:GetName().."Delete"):SetText(UMM_VIEWER_BUTTON_DELETE);
    getglobal(self:GetName().."Close"):SetText(UMM_VIEWER_BUTTON_CLOSE);
    getglobal(self:GetName().."FooterAttachmentLabel"):SetText("|cff"..UMMColor.White..UMM_VIEWER_ATTACHED.."|r");
    getglobal(self:GetName().."FooterAcceptCODCheckLabel"):SetText("|cff"..UMMColor.White..UMM_VIEWER_ATTACHMENTACCEPT.."|r");
    -- Disable the buttons except Close
    getglobal(self:GetName().."Reply"):Disable();
    getglobal(self:GetName().."Return"):Disable();
    getglobal(self:GetName().."Delete"):Disable();
    getglobal(self:GetName().."Footer"):Hide();
  end;
  
  this:InitView();
  
end

function UMMMailViewerTemplate_OnHide(this)
  this:SignalViewerClosed();
end
