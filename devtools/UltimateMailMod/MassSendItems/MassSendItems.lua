-- #######################
-- ##                   ##
-- ##  Mass Send Items  ##
-- ##                   ##
-- #######################

-- #### Mass Send Status Frame #####

function UMMMassSendItemsStatusItemTemplate_OnLoad(this)

  this.SetData = function(self, recipient, mailObject, modeEdit)
    getglobal(self:GetName().."Recipient"):SetText("|cff"..UMMFriends:GetColor(recipient)..recipient.."|r");
    local subject = mailObject.Name.." ("..mailObject.Count..")";
    getglobal(self:GetName().."Subject"):SetText("|cff"..UMMColor.White..subject.."|r");
    local button = getglobal(self:GetName().."Button");
    SetItemButtonTexture(button, mailObject.Icon);
    SetItemButtonCount(button, 0);
    getglobal(self:GetName().."Status"):Hide();
    if (modeEdit) then
      getglobal(self:GetName().."COD"):Show();
      if (mailObject.CODAmount > 0) then
        getglobal(self:GetName().."COD"):SetText(mailObject.CODAmount);
      else
        getglobal(self:GetName().."COD"):SetText("");
      end
    else
      getglobal(self:GetName().."COD"):Hide();
    end
  end;

  this.SetStatus = function(self, status)
    getglobal(self:GetName().."COD"):Hide();
    getglobal(self:GetName().."Status"):Show();
    if (string.lower(status) == "sending") then
      getglobal(self:GetName().."Status"):SetText("|cff"..UMMColor.Green..UMM_MSI_STATUS_SENDING.."|r");
    elseif (string.lower(status) == "queued") then
      getglobal(self:GetName().."Status"):SetText("|cff"..UMMColor.Yellow..UMM_MSI_STATUS_QUEUED.."|r");
    end
  end;

end

function UMMMassSendItemsStatusTemplate_OnLoad(this)

  this.priv_SendTable   = nil;
  this.priv_Offset      = 0;
  this.priv_Recipient   = nil;
  this.priv_CODMode     = nil;
  this.priv_AutoRunning = nil;
  this.priv_SendCount   = 0;
  this.priv_SendTotal   = 0;
  this.priv_MyName      = nil;

  this.AutoDisableTabs = function(self)
    for i = 1, 3 do
      getglobal("UMMFrameTab"..i.."Button"):Disable();
    end
  end;

  this.AutoEnableTabs = function(self)
    for i = 1, 3 do
      getglobal("UMMFrameTab"..i.."Button"):Enable();
    end
  end;

  this.Clear = function(self)
    self.priv_SendTable   = nil;
    self.priv_Offset      = 0;
    self.priv_Recipient   = nil;
    self.priv_CODMode     = nil;
    self.priv_AutoRunning = nil;
    self.priv_SendCount   = 0;
    self.priv_SendTotal   = 0;
    self.priv_MyName      = nil;
  end;

  this.Refresh = function(self)
    for idx = 1, 18 do
      local index = idx + self.priv_Offset;
      local mail = getglobal(self:GetName().."Mail"..idx);
      if (index <= table.getn(self.priv_SendTable)) then
        mail:SetData(self.priv_Recipient, self.priv_SendTable[index], self.priv_CODMode);
        if (not self.priv_CODMode) then
          if (idx == 1) then
            mail:SetStatus("Sending");
          else
            mail:SetStatus("Queued");
          end
        end
        mail:Show();
      else
        mail:Hide();
      end
    end
    if (self.priv_CODMode) then
      if (table.getn(self.priv_SendTable) > 18) then
        getglobal(self:GetName().."Scroll"):SetMaxValue(table.getn(self.priv_SendTable) - 18);
        getglobal(self:GetName().."Scroll"):SetValue(self.priv_Offset);
        getglobal(self:GetName().."Scroll"):Show();
      else
        getglobal(self:GetName().."Scroll"):Hide();
      end
    end
  end;

  this.ScrollChanged = function(self, this)
    self.priv_Offset = this:GetValue();
    self:Refresh();
  end;

  this.DefineCOD = function(self, id, value)
    local index = id + self.priv_Offset;
    local cash = 0;
    if (value ~= nil and value ~= "") then
      local money = string.format("%d", value + 1);
      cash = money - 1;
    end;
    if (index >= 1 and index <= table.getn(self.priv_SendTable)) then
      self.priv_SendTable[index].CODAmount = cash;
    end
  end;

  this.AutoSend = function(self)
    if (self.priv_SendCount < self.priv_SendTotal) then
      self.priv_SendCount = self.priv_SendCount + 1;
      UMMNormalBar:SetStatus(string.format(UMM_MSI_SEND_STATUS, self.priv_SendCount, self.priv_SendTotal));
      self.priv_Offset = self.priv_SendCount - 1;
      self:Refresh();
      UMMMailComposer:Clear();
      UMMMailComposer:SetComposer(self.priv_MyName);
      UMMMailComposer:Recipient(self.priv_Recipient);
      UMMMailComposer:Subject(self.priv_SendTable[self.priv_SendCount].Name.." ("..self.priv_SendTable[self.priv_SendCount].Count..")");
      local body = string.format(UMM_MSI_SEND_MAILBODY, self.priv_Recipient, UnitName("player"), "UMM v"..UMM_VERSION.Major.."."..UMM_VERSION.Minor.."."..UMM_VERSION.Revision.." ("..UMM_VERSION.Build..")");
      UMMMailComposer:Body(body);
      UMMMailComposer:DefinedCODAmount(self.priv_SendTable[self.priv_SendCount].CODAmount);
      UMMMailComposer:AttachedItemIndex(self.priv_SendTable[self.priv_SendCount].Index);
      local result = UMMMailComposer:Send();
    else
      UMMNormalBar:SetStatus("");
      UMMNormalBar:Show();
      self:Clear();
      self:Hide();
    end
  end;

  this.StartSending = function(self)
    self:AutoDisableTabs();
    self.priv_CODMode = nil;
    self.priv_SendCount = 0;
    self.priv_SendTotal = table.getn(self.priv_SendTable);
    self.priv_MyName = self:GetName();
    self.priv_AutoRunning = true;
    UMMNormalBar:Hide();
    self:AutoSend();
  end;

  this.SendCompleted = function(self)
    if (self.priv_AutoRunning) then
      UMMSetGlobalTimeout(self:GetName());
    end
  end;

  this.TimeOut = function(self)
    if (self.priv_AutoRunning) then
      self:AutoSend();
    end
  end;

  this.TimeOutFailed = function(self)
    UMMNormalBar:SetStatus("");
    UMMNormalBar:Show();
    self:Clear();
    self:Hide();
  end;

  this.BuildSendList = function(self)
    self.priv_SendTable = {};
    for i = 1, 180 do
      if (UMMBagManager.ItemList[i].Marked == true) then
        if (UMMBagManager.ItemList[i].Bound == true) then
          -- Skip bound items
        else
          local newItem = {};
          newItem.Index = 0;
          newItem.Icon = "";
          newItem.Count = 0;
          newItem.Name = "";
          newItem.Link = "";
          newItem.CODAmount = 0;
          newItem.Index = UMMBagManager.ItemList[i].Index;
          newItem.Icon = UMMBagManager.ItemList[i].Icon;
          newItem.Count = UMMBagManager.ItemList[i].Count;
          newItem.Name = UMMBagManager.ItemList[i].Name;
          newItem.Link = UMMBagManager.ItemList[i].Link;
          table.insert(self.priv_SendTable, newItem);
        end
      end
    end
    self.priv_Offset = 0;
  end;

  this.Send = function(self)
    self.priv_CODMode = nil;
    self:BuildSendList();
    getglobal(this:GetName().."Status"):SetText("|cff"..UMMColor.White..UMM_MSI_STATUS.."|r");
    self.priv_Recipient = getglobal(this:GetParent():GetName().."RecipientRecipient"):GetText();
    getglobal(this:GetName().."Cancel"):Hide();
    getglobal(this:GetName().."Send"):Hide();
    self:Show();
    self:Refresh();
    self:StartSending();
  end;

  this.ShowCODEditor = function(self)
    self.priv_CODMode = true;
    self:BuildSendList();
    getglobal(this:GetName().."Status"):SetText("|cff"..UMMColor.White..UMM_MSI_COD.."|r");
    self.priv_Recipient = getglobal(this:GetParent():GetName().."RecipientRecipient"):GetText();
    getglobal(this:GetName().."Cancel"):Show();
    getglobal(this:GetName().."Send"):Show();
    self:Show();
    self:Refresh();
  end;

  this.CancelCOD = function(self)
    self.priv_SendTable = nil;
    self.priv_Offset = 0;
    self.priv_Recipient = nil;
    self.priv_CODMode = nil;
    self:Hide();
  end;

  for i = 1, 18 do
    local button = getglobal(this:GetName().."Mail"..i);
    button:ClearAllAnchors();
    button:SetAnchor("TOPLEFT", "TOPLEFT", this:GetName(), 5, ((i * 25) - 25) + 20);
  end
  getglobal(this:GetName().."Recipient"):SetText("|cff"..UMMColor.White..UMM_MSI_ADDRESSEE.."|r");
  getglobal(this:GetName().."Subject"):SetText("|cff"..UMMColor.White..UMM_MSI_SUBJECT.."|r");
  getglobal(this:GetName().."Status"):SetText("");
  getglobal(this:GetName().."Send"):SetText(UMM_MSI_BUTTON_SEND);
  getglobal(this:GetName().."Cancel"):SetText(UMM_MSI_BUTTON_CANCEL);

end

function UMMMassSendItemsStatusTemplate_OnShow(this)
  getglobal(this:GetParent():GetName().."Action"):Hide();
  getglobal(this:GetParent():GetName().."Recipient"):Hide();
  getglobal(this:GetParent():GetName().."Bags"):Hide();
  getglobal(this:GetParent():GetName().."Mark"):Hide();
end

function UMMMassSendItemsStatusTemplate_OnHide(this)
  UMMBagManager:ClearMarks();
  getglobal(this:GetParent():GetName().."Action"):Show();
  getglobal(this:GetParent():GetName().."Recipient"):Show();
  getglobal(this:GetParent():GetName().."Bags"):Show();
  getglobal(this:GetParent():GetName().."Mark"):Show();
  getglobal(this:GetParent():GetName().."Bags"):PopulateBags();
  getglobal(this:GetParent():GetName().."RecipientRecipient"):SetText("");
  this:AutoEnableTabs();
end

-- ##### Bags #####

function UMMMassSendItemsBagsTemplate_OnLoad(this)

  this.priv_Shown = nil;

  this.GetItem = function(self, bagIndex, slotIndex)
    local index = (bagIndex * 30) - 30;
    index = index + slotIndex;
    return UMMBagManager.ItemList[index];
  end;

  this.GetBagLink = function(self, bagIndex, slotIndex)
    local result = nil;
    local index = (bagIndex * 30) - 30;
    index = index + slotIndex;
    local item = UMMBagManager.ItemList[index];
    if (item) then
      if (item.Empty == false) then
        result = item.Link;
      end
    end

    return result;
  end;

  this.ToggleMark = function(self, bagIndex, slotIndex)
    local index = (bagIndex * 30) - 30;
    index = index + slotIndex;
    if (UMMBagManager.ItemList[index].Empty == false) then
      if (UMMBagManager.ItemList[index].Bound == false) then
        if (UMMMailComposer:ItemIsBound(UMMBagManager.ItemList[index].Index)) then
          UMMBagManager.ItemList[index].Bound = true;
        end
      end
      if (UMMBagManager.ItemList[index].Marked == true) then
        UMMBagManager.ItemList[index].Marked = false;
      else
        UMMBagManager.ItemList[index].Marked = true;
      end
      if (UMMBagManager.ItemList[index].Marked == true) then
        getglobal(self:GetName().."Bag"..bagIndex.."Slot"..slotIndex.."MarkBorder"):SetColor(1, 1, 0.2);
        getglobal(self:GetName().."Bag"..bagIndex.."Slot"..slotIndex.."MarkBorder"):Show();
        if (UMMBagManager.ItemList[index].Bound == true) then
          getglobal(self:GetName().."Bag"..bagIndex.."Slot"..slotIndex.."Invalid"):Show();
          getglobal(self:GetName().."Bag"..bagIndex.."Slot"..slotIndex.."MarkBorder"):Hide();
          UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_CANTSENDBOUND);
          WarningFrame:AddMessage(UMM_ERROR_CANTSENDBOUND);
        end
      else
        getglobal(self:GetName().."Bag"..bagIndex.."Slot"..slotIndex.."MarkBorder"):Hide();
        getglobal(self:GetName().."Bag"..bagIndex.."Slot"..slotIndex.."Invalid"):Hide();
      end
    end
    getglobal(self:GetParent():GetName().."Action"):CheckStatus();
  end;

  this.PopulateBags = function(self)
    if (self.priv_Shown and UMMFrame:IsVisible()) then
      local index = 0;
      for bagIndex = 1, 6 do
        for slotIndex = 1, 30 do
          index = index + 1;
          local button = getglobal(self:GetName().."Bag"..bagIndex.."Slot"..slotIndex);
          getglobal(button:GetName().."Invalid"):Hide();
          getglobal(button:GetName().."QualityBorder"):Hide();
          getglobal(button:GetName().."MarkBorder"):Hide();
          local item = self:GetItem(bagIndex, slotIndex);
          if (item) then
            if (item.Empty == true) then
              SetItemButtonTexture(button, nil);
              SetItemButtonCount(button, 0);
              button:Disable();
            else
              local itemColor = string.sub(item.Link, string.find(item.Link, "|c%x%x%x%x%x%x%x%x") + 4, string.find(item.Link, "|c%x%x%x%x%x%x%x%x") + 9);
              local R, G, B = tonumber(string.sub(itemColor, 1, 2), 16), tonumber(string.sub(itemColor, 3, 4), 16), tonumber(string.sub(itemColor, 5, 6), 16);
              if (R == 255 and G == 255 and B == 255) then
                -- Skip white items
                getglobal(button:GetName().."QualityBorder"):Hide();
              else
                getglobal(button:GetName().."QualityBorder"):SetColor(R / 255, G / 255, B / 255);
                getglobal(button:GetName().."QualityBorder"):SetAlpha(0.65);
                getglobal(button:GetName().."QualityBorder"):Show();
              end
              SetItemButtonTexture(button, item.Icon);
              SetItemButtonCount(button, item.Count);
              if (item.Marked == true) then
                getglobal(button:GetName().."MarkBorder"):SetColor(1, 1, 0.2);
                getglobal(button:GetName().."MarkBorder"):Show();
              end
              button:Enable();
            end
          else
            button:Disable();
          end
        end
      end
    end
    getglobal(this:GetParent():GetName().."Action"):CheckStatus();
  end;

  this.ShowBags = function(self)
    self.priv_Shown = true;
    self:PopulateBags();
  end;

  this.HideBags = function(self)
    self.priv_Shown = nil;
  end;

  local sizeX, sizeY;
  local x, y, b;

  sizeX = 255;
  sizeY = 215;
  b = 0;
  for y = 1, 2 do
    for x = 1, 3 do
      b = b + 1;
      local bag = getglobal(this:GetName().."Bag"..b);
      bag:ClearAllAnchors();
      bag:SetAnchor("TOPLEFT", "TOPLEFT", this:GetName(), ((x * sizeX) - sizeX) + 5, ((y * sizeY) - sizeY) + 5);
      bag:Show();
    end
  end
end

function UMMMassSendItemsBagsTemplate_OnShow(this)
  this:ShowBags();
end

function UMMMassSendItemsBagsTemplate_OnHide(this)
  this:HideBags();
end

-- ##### Bag #####

function UMMMassSendItemsBagTemplate_OnLoad(this)
  local x, y, i;

  i = 0;
  for y = 1, 5 do
    for x = 1, 6 do
      i = i + 1;
      local btn = getglobal(this:GetName().."Slot"..i);
      btn:ClearAllAnchors();
      btn:SetAnchor("TOPLEFT", "TOPLEFT", this:GetName(), ((x * 40) - 40) + 10, ((y * 40) - 40) + 10);
      btn:Show();
    end
  end
end

-- ##### Bag Slot Buttons ####

function UMMMassSendItemsSlotTemplate_OnEnter(this)
  local slotIndex = this:GetID();
  local bagIndex = this:GetParent():GetID();
  local itemLink = this:GetParent():GetParent():GetBagLink(bagIndex, slotIndex);
  if (itemLink) then
    GameTooltip:ClearLines();
    GameTooltip:ClearAllAnchors();
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT", 0, 0);
    GameTooltip:SetHyperLink(itemLink);
    GameTooltip:Show();
  end
end

function UMMMassSendItemsSlotTemplate_OnClick(this)
  local slotIndex = this:GetID();
  local bagIndex = this:GetParent():GetID();
  this:GetParent():GetParent():ToggleMark(bagIndex, slotIndex);
end

function UMMMassSendItemsSlotTemplate_OnLeave(this)
  if (GameTooltip:IsVisible()) then
    GameTooltip:Hide();
  end
end

-- ##### Action Frame #####

function UMMMassSendItemsActionTemplate_OnLoad(this)

  this.CheckStatus = function(self)
    local mailCount = 0;
    local someBound = nil;
    local recipient = getglobal(this:GetParent():GetName().."RecipientRecipient"):GetText();
    if (recipient ~= "" and recipient ~= nil) then
      recipient = string.gsub(recipient, " ", "");
      if (recipient ~= "" and recipient ~= nil) then
      else
        recipient = "";
      end
    else
      recipient = "";
    end

    for i = 1, 180 do
      if (UMMBagManager.ItemList[i].Marked == true) then
        mailCount = mailCount + 1;
        if (UMMBagManager.ItemList[i].Bound == true) then
          someBound = true;
        end
      end
    end

    if (someBound) then
      getglobal(this:GetName().."Label"):SetText("|cff"..UMMColor.Red..UMM_ERROR_CANTSENDBOUND.."|r");
      getglobal(this:GetName().."Send"):Disable();
      getglobal(this:GetName().."COD"):Disable();
    else
      if (mailCount > 0) then
        getglobal(this:GetName().."Label"):SetText("|cff"..UMMColor.White..string.format(UMM_MSI_MAILSTOSEND, mailCount).."|r");
        if (recipient == "") then
          getglobal(this:GetName().."Send"):Disable();
          getglobal(this:GetName().."COD"):Disable();
        else
          getglobal(this:GetName().."Send"):Enable();
          getglobal(this:GetName().."COD"):Enable();
        end
      else
        getglobal(this:GetName().."Label"):SetText("");
        getglobal(this:GetName().."Send"):Disable();
        getglobal(this:GetName().."COD"):Disable();
      end
    end
  end;

  this.Send = function(self)
    getglobal(self:GetParent():GetName().."Status"):Send();
  end;

  this.COD = function(self)
    getglobal(self:GetParent():GetName().."Status"):ShowCODEditor();
  end;

  getglobal(this:GetName().."Send"):SetText(UMM_MSI_BUTTON_SEND);
  UMMAutoResizeWidth(getglobal(this:GetName().."Send"),70)
  getglobal(this:GetName().."COD"):SetText(UMM_MSI_BUTTON_COD);
  UMMAutoResizeWidth(getglobal(this:GetName().."COD"),70)

end

function UMMMassSendItemsActionTemplate_OnShow(this)
  this:CheckStatus();
end

function UMMMassSendItemsActionTemplate_OnHide(this)

end

-- ##### Recipient Frame #####

function UMMMassSendItemsRecipientTemplate_OnLoad(this)

  this.HideBody = function(self)
    getglobal(self:GetParent():GetName().."Action"):Hide();
    getglobal(self:GetParent():GetName().."Bags"):Hide();
    getglobal(self:GetParent():GetName().."Mark"):Hide();
    getglobal(self:GetParent():GetName().."People"):Show();
  end;

  this.ShowBody = function(self)
    getglobal(self:GetParent():GetName().."Action"):Show();
    getglobal(self:GetParent():GetName().."Bags"):Show();
    getglobal(self:GetParent():GetName().."Mark"):Show();
    getglobal(self:GetParent():GetName().."People"):Hide();
  end;

  this.SelectDone = function(self)
    self:ShowBody();
  end;

  this.FindRecipient = function(self)
    if (getglobal(self:GetParent():GetName().."Bags"):IsVisible()) then
      self:HideBody();
    else
      self:ShowBody();
    end
  end;

  this.CheckSendStatus = function(self)
    getglobal(self:GetParent():GetName().."Action"):CheckStatus();
  end;

  this.Reset = function(self)
    UMMBagManager:ClearMarks();
    getglobal(this:GetParent():GetName().."Bags"):PopulateBags();
    getglobal(this:GetName().."Recipient"):SetText("");
  end;

  getglobal(this:GetName().."Find"):SetText(UMM_MSI_BUTTON_ADDRESSEE);
  UMMAutoResizeWidth(getglobal(this:GetName().."Find"),50)
  getglobal(this:GetName().."Reset"):SetText(UMM_MSI_BUTTON_RESET);
  UMMAutoResizeWidth(getglobal(this:GetName().."Reset"),50)

end

function UMMMassSendItemsRecipientTemplate_OnShow(this)

end

function UMMMassSendItemsRecipientTemplate_OnHide(this)
  getglobal(this:GetName().."Recipient"):ClearFocus();
end

-- ##### People Columns #####

function UMMMassSendItemsPeopleTemplate_OnShow(this)
  UMMFriends:Load();
  local recipientName = this:GetParent():GetName().."RecipientRecipient";
  local recipientFrame = this:GetParent():GetName().."Recipient";

  local listFrame = getglobal(this:GetName().."Own")
  listFrame:ClearAllAnchors();
  listFrame:SetAnchor("TOPLEFT", "TOPLEFT", this:GetName(), 0, 0);
  listFrame:SetTarget(recipientName);
  listFrame:SetSelectDone(recipientFrame);
  listFrame:SetupList("own");
  listFrame:Show();

  local listFrame = getglobal(this:GetName().."Friends")
  listFrame:ClearAllAnchors();
  listFrame:SetAnchor("TOPLEFT", "TOPLEFT", this:GetName(), 145, 0);
  listFrame:SetTarget(recipientName);
  listFrame:SetSelectDone(recipientFrame);
  listFrame:SetupList("friend");
  listFrame:Show();

  local listFrame = getglobal(this:GetName().."Guildies")
  if (IsInGuild()) then
    listFrame:ClearAllAnchors();
    listFrame:SetAnchor("TOPLEFT", "TOPLEFT", this:GetName(), 290, 0);
    listFrame:SetTarget(recipientName);
    listFrame:SetSelectDone(recipientFrame);
    listFrame:SetupList("guild");
    listFrame:Show();
  else
    listFrame:Hide();
  end
end

-- ##### Bottom Mark Button Bar #####

function UMMMassSendItemsMarkButtonsTemplate_OnLoad(this)

  this.ButtonClick = function(self, id)
    local type = UMMItemDB:GetTypeByID(id);
    for index = 1, 180 do
      if (UMMBagManager.ItemList[index].Empty == true) then
        -- Skip empty slots
      else
        if (UMMItemDB:IsItem(type, UMMBagManager.ItemList[index].Link)) then
          UMMBagManager.ItemList[index].Marked = true;
        end
      end
    end
    getglobal(this:GetParent():GetName().."Bags"):PopulateBags();
  end;

  this.ButtonEnter = function(self, this)
    local title = getglobal("UMM_MSI_MARK_TOOLTIP"..this:GetID());
    if (title) then
      GameTooltip:ClearLines();
      GameTooltip:ClearAllAnchors();
      GameTooltip:SetOwner(this, "ANCHOR_TOP", 0, 0);
      GameTooltip:AddLine("|cff"..UMMColor.Medium..title.."|r");
      GameTooltip:AddLine("|cff"..UMMColor.Bright..UMM_MSI_MARK_TOOLTIPCLICK.."|r");
      GameTooltip:Show();
    end
  end;

  this.ButtonLeave = function(self, id)
    GameTooltip:Hide();
  end;

  getglobal(this:GetName().."Label"):SetText("|cff"..UMMColor.White..UMM_MSI_MARK_LABEL.."|r");
  local shiftX = 45;
  for index = 1, 11 do
    local button = getglobal(this:GetName().."Button"..index);
    button:ClearAllAnchors();
    button:SetAnchor("LEFT", "LEFT", this:GetName(), ((index * 65) - 65) + 5 + shiftX, 0);
    button:SetText(getglobal("UMM_MSI_MARKBUTTON"..index));
  end

end

-- ##### Main Mass Send Items Frame #####

function UMMMassSendItemsTemplate_OnShow(this)
  UMMFriends:Load();
  getglobal(this:GetName().."Action"):Show();
  getglobal(this:GetName().."Recipient"):Show();
  getglobal(this:GetName().."Bags"):Show();
  getglobal(this:GetName().."Mark"):Show();
  getglobal(this:GetName().."Status"):Hide();
  getglobal(this:GetName().."People"):Hide();
end

function UMMMassSendItemsTemplate_OnHide(this)
  getglobal(this:GetName().."Action"):Hide();
  getglobal(this:GetName().."RecipientRecipient"):SetText("");
  getglobal(this:GetName().."RecipientRecipient"):ClearFocus();
  getglobal(this:GetName().."Recipient"):Hide();
  getglobal(this:GetName().."Bags"):Hide();
  getglobal(this:GetName().."Mark"):Hide();
  getglobal(this:GetName().."Status"):Hide();
end
