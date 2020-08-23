
-- ####################
-- ##                ##
-- ##  Mail Manager  ##
-- ##                ##
-- ####################

UMMMailManager = {

  MailCount             = 0;
  InboxOffset           = 0;
  InboxTotalMoney       = 0;
  InboxTotalDiamonds    = 0;
  Mails                 = {};

  -- Private stuff
  lastMailCount         = 0;
  priv_Shown            = nil;
  priv_AutoRunning      = nil;
  priv_AutoType         = nil;
  priv_TagTable         = nil;
  priv_AutoTakeFilter   = nil;
  priv_Locked           = nil;
  priv_LockItem         = nil;
  priv_LockMoney        = nil;
  priv_LockFrame        = nil;
  priv_LockReturnFrame  = nil;
  priv_TakeAutoDelete   = nil;
  priv_TakeLastDelete   = nil;
  priv_TakeDeleteIndex  = 0;

  InboxRefresh = function(self)
    -- This function reads the contents of the inbox
    local newMails = false;
    local newMailCount = 0;

    self.Mails = nil;
    self.Mails = {};
    self.InboxTotalMoney = 0;
    self.InboxTotalDiamonds = 0;
    self.lastMailCount = self.MailCount;
    self.MailCount = GetInboxNumItems();
    if (self.lastMailCount ~= self.MailCount) then
      self.lastMailCount = self.MailCount;
      self.InboxOffset = 0;
    end
    for index = 1, self.MailCount do
      local packageIcon, sender, subject, COD, moneyMode, money, daysLeft, paperStyle, items, wasRead, wasReturned, canReply = GetInboxHeaderInfo(index);
      local newMail = {};
      newMail.Author = sender;
      newMail.Subject = subject;
      newMail.DaysLeft = daysLeft;
      newMail.WasRead = false;
      newMail.WasReturned = false;
      newMail.CanReply = false;
      newMail.CODAmount = 0;
      newMail.AttachedItems = 0;
      newMail.AttachedMoney = 0;
      newMail.AttachedDiamonds = 0;
      newMail.Tagged = false;
      if (wasRead) then
        newMail.WasRead = true;
      else
        newMail.WasRead = false;
        newMails = true;
        newMailCount = newMailCount + 1;
      end
      if (wasReturned) then
        newMail.WasReturned = true;
      else
        newMail.WasReturned = false;
      end
      if (canReply) then
        newMail.CanReply = true;
      else
        newMail.CanReply = false;
      end
      if (COD) then
        if money and (money > 0) then
          newMail.CODAmount = money;
        else
          newMail.CODAmount = 0;
        end
        newMail.AttachedMoney = 0;
        newMail.AttachedDiamonds = 0;
      else
        newMail.CODAmount = 0;
        if money and (money > 0) then
          if (string.lower(moneyMode) == "account") then
            newMail.AttachedMoney = 0;
            newMail.AttachedDiamonds = money;
          else
            newMail.AttachedMoney = money;
            newMail.AttachedDiamonds = 0;
          end
        else
          newMail.AttachedMoney = 0;
          newMail.AttachedDiamonds = 0;
        end
      end
      if items and (items > 0) then
        newMail.AttachedItems = items;
      else
        newMail.AttachedItems = 0;
      end
      if (packageIcon == nil or packageIcon == "") then
        if (newMail.WasRead) then
          if (newMail.AttachedDiamonds > 0) then
            newMail.Icon = "interface/icons/skill_war_new60-4";
          elseif (newMail.AttachedMoney > 0) then
            newMail.Icon = "interface/icons/coin_02";
          else
            newMail.Icon = "interface/icons/quest_letter02";
          end
        else
          if (newMail.AttachedDiamonds > 0) then
            newMail.Icon = "interface/icons/crystal_01";
          elseif (newMail.AttachedMoney > 0) then
            newMail.Icon = "interface/icons/coin_03";
          else
            newMail.Icon = "interface/icons/quest_letter07";
          end
        end
      else
        newMail.Icon = packageIcon;
      end
      self.InboxTotalMoney = self.InboxTotalMoney + newMail.AttachedMoney;
      self.InboxTotalDiamonds = self.InboxTotalDiamonds + newMail.AttachedDiamonds;
      if (self.priv_AutoRunning) then
        if (self.priv_TagTable) then
          if (self.priv_TagTable[index]) then
            newMail.Tagged = self.priv_TagTable[index].Tagged;
          end
        end
      end
      self.Mails[index] = newMail;
    end
    if (newMails == true) then
      UMMSettings:NewMail(newMailCount);
      getglobal("UMMNewMailButton"):CheckStatus(true);
    else
      UMMSettings:NoNewMail();
      getglobal("UMMNewMailButton"):CheckStatus(true);
    end
	getglobal("UMMFrameTab1TOCMailCountLabel"):SetText(UMM_INBOX_LABEL_MAILCOUNT..": "..tostring(self.MailCount))
  end; -- InboxRefresh()

  GetTagCount = function(self)
    local tagCount = 0;

    for mi = 1, self.MailCount do
      if (self.Mails[mi].Tagged == true) then
        tagCount = tagCount + 1;
      end
    end
    return tagCount;
  end;

  GetSelectedMailIndex = function(self)
    local index = 0;

    if (self.priv_Shown) then
      if (self:GetTagCount() == 1) then
        for mi = 1, self.MailCount do
          if (self.Mails[mi].Tagged == true) then
            index = mi;
          end
        end
      end
    end

    return index;
  end;

  GetSelectedMail = function(self)
    local mailObject = nil;

    if (self.priv_Shown) then
      if (self:GetTagCount() == 1) then
        for mi = 1, self.MailCount do
          if (self.Mails[mi].Tagged == true) then
            mailObject = self.Mails[mi];
          end
        end
      end
    end

    return mailObject;
  end;

  Tag = function(self, mailIndex)
    if (self.priv_Shown) then
      if (mailIndex >= 1 and mailIndex <= self.MailCount) then
        self.Mails[mailIndex].Tagged = true;
      end
    end
  end;

  UnTag = function(self, mailIndex)
    if (self.priv_Shown) then
      if (mailIndex >= 1 and mailIndex <= self.MailCount) then
        self.Mails[mailIndex].Tagged = false;
      end
    end
  end;

  TagByID = function(self, id)
    if (self.priv_Shown) then
      local mailIndex = id + self.InboxOffset;
      if (mailIndex >= 1 and mailIndex <= self.MailCount) then
        self.Mails[mailIndex].Tagged = true;
      end
    end
  end;

  ToggleTagByID = function(self, id)
    if (self.priv_Shown) then
      local mailIndex = id + self.InboxOffset;
      if (mailIndex >= 1 and mailIndex <= self.MailCount) then
        if (self.Mails[mailIndex].Tagged == true) then
          self.Mails[mailIndex].Tagged = false;
        else
          self.Mails[mailIndex].Tagged = true;
        end
      end
    end
  end;

  UnTagByID = function(self, id)
    if (self.priv_Shown) then
      local mailIndex = id + self.InboxOffset;
      if (mailIndex >= 1 and mailIndex <= self.MailCount) then
        self.Mails[mailIndex].Tagged = false;
      end
    end
  end;

  UnTagAll = function(self)
    if (self.priv_Shown) then
      for mi = 1, self.MailCount do
        self.Mails[mi].Tagged = false;
      end
    end
  end;

  UpdateItemQueueLength = function(self)
    local queuedItems = 0;
    local itemName, iconPath, stackAmount, unknown = GetItemQueueInfo(1);
    while (itemName ~= nil) do
      queuedItems = queuedItems + 1;
      itemName, iconPath, stackAmount, unknown = GetItemQueueInfo(queuedItems + 1);
    end;
    self.ItemQueueLength = queuedItems;
  end;

  UpdateBagSlots = function(self)
	local occupiedSlots, totalSlots = GetBagCount();
	self.MaxUseBagSlots = totalSlots - occupiedSlots;
	if self.MaxUseBagSlots > 5 then
	  self.MaxUseBagSlots = 5;
	end;
  end;

  TryAutoTakeMail = function(self)
    if (self.priv_AutoRunning and self.priv_AutoType == "Take" and self.priv_TakeDeleteIndex ~= -1) then
      if (self.MaxUseBagSlots - self.ItemQueueLength > 0) then
        self:AutoTakeMail();
      end;
    end;
  end;

  GetAttachments = function(self, mailIndex, acceptCOD, parentFrame, returnFrame)
    self.priv_LockFrame = nil;
    self.priv_Locked = nil;
    self.priv_LockItem = nil;
    self.priv_LockMoney = nil;
    if (self.Mails[mailIndex].CODAmount > 0) then
      if (acceptCOD) then
        self.priv_LockFrame = parentFrame;
        self.priv_Locked = true;
        self.priv_LockItem = true;
        self.priv_LockMoney = nil;
        local bodyText, texture, isTakeable, isInvoice = GetInboxText(mailIndex);
        TakeInboxItem(mailIndex);
		self.ItemQueueLength = self.ItemQueueLength + self.Mails[mailIndex].AttachedItems;
        self.Mails[mailIndex].AttachedItems = 0;
        self.Mails[mailIndex].AttachedMoney = 0;
        self.Mails[mailIndex].AttachedDiamonds = 0;
        self.Mails[mailIndex].CODAmount = 0;
        getglobal("UMMFrameTab1TOC"):RefreshTOC();
        return true;
      else
        UMMPrompt("|r|cff"..UMMColor.Red..UMM_VIEWER_ATTACHMENT_NOT_ACCEPTED);
        WarningFrame:AddMessage(UMM_VIEWER_ATTACHMENT_NOT_ACCEPTED);
        return nil;
      end
    else
      self.priv_LockFrame = parentFrame;
      self.priv_LockReturnFrame = returnFrame;
      self.priv_Locked = true;
      if (self.Mails[mailIndex].AttachedItems > 0) then
        self.priv_LockItem = true;
      else
        self.priv_LockItem = nil;
      end
      if (self.Mails[mailIndex].AttachedMoney > 0 or self.Mails[mailIndex].AttachedDiamonds > 0) then
        self.priv_LockMoney = true;
      else
        self.priv_LockMoney = nil;
      end
      local bodyText, texture, isTakeable, isInvoice = GetInboxText(mailIndex);
      TakeInboxItem(mailIndex);
      self.ItemQueueLength = self.ItemQueueLength + self.Mails[mailIndex].AttachedItems;
      self.Mails[mailIndex].AttachedItems = 0;
      self.Mails[mailIndex].AttachedMoney = 0;
      self.Mails[mailIndex].AttachedDiamonds = 0;
      getglobal("UMMFrameTab1TOC"):RefreshTOC();
      return true;
    end
  end;

  ShowInbox = function(self)
    self.priv_Shown = true;
  end;

  HideInbox = function(self)
    self.priv_Shown = nil;
  end;

  InboxShown = function(self)
    if (self.priv_Shown) then
      return true;
    else
      return nil;
    end
  end;

  ReplyToMail = function(self, mailIndex)
    local mailObject = self.Mails[mailIndex];
    UMMMenuSelectTab(2);
    UMMFrameTab2Viewer:Display("UMMFrameTab2Composer", mailIndex, mailObject);
    UMMFrameTab2Composer:SetReply(mailObject.Author, mailObject.Subject);
  end;

  ReturnMail = function(self, mailIndex)
    local result = nil;
    local canReturn = nil;
    if (self.Mails[mailIndex].CODAmount + self.Mails[mailIndex].AttachedItems + self.Mails[mailIndex].AttachedMoney + self.Mails[mailIndex].AttachedDiamonds > 0) then
      if (self.Mails[mailIndex].CanReply == true) then
        canReturn = true;
      end
    end
    if (canReturn == true) then
      self:RemoveInboxTOCItem(mailIndex);
      ReturnInboxItem(mailIndex);
      self:InboxRefresh();
      getglobal("UMMFrameTab1TOC"):RefreshTOC();
      result = true;
    else
      UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_CANTRETURN);
      WarningFrame:AddMessage(UMM_ERROR_CANTRETURN);
    end

    return result;
  end;

  DeleteMail = function(self, mailIndex)
    local result = nil;
    local objectCount = 0;
    local packageIcon, sender, subject, COD, moneyMode, money, daysLeft, paperStyle, items, wasRead, wasReturned, canReply = GetInboxHeaderInfo(mailIndex);
    if money and (money > 0) then
      objectCount = objectCount + 1;
    end
    if items and (items > 0) then
      objectCount = objectCount + 1;
    end
    if (self.Mails[mailIndex].CODAmount + self.Mails[mailIndex].AttachedItems + self.Mails[mailIndex].AttachedMoney + self.Mails[mailIndex].AttachedDiamonds + objectCount > 0) then
      UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_CANTDELETE);
      WarningFrame:AddMessage(UMM_ERROR_CANTDELETE);
    else
      self:RemoveInboxTOCItem(mailIndex);
      DeleteInboxItem(mailIndex);
      self:InboxRefresh();
      getglobal("UMMFrameTab1TOC"):RefreshTOC();
      result = true;
    end

    return result;
  end;

  -- ### Automation ###

  AutoDisableTabs = function(self)
    for i = 1, 3 do
      getglobal("UMMFrameTab"..i.."Button"):Disable();
    end
  end;

  AutoEnableTabs = function(self)
    for i = 1, 3 do
      getglobal("UMMFrameTab"..i.."Button"):Enable();
    end
  end;

  ClearAutomationLock = function(self)
    self.priv_Locked = nil;
    self.priv_LockItem = nil;
    self.priv_LockMoney = nil;
    self.priv_LockFrame = nil;
    self.priv_LockReturnFrame = nil;
  end;

  StopAutomation = function(self, forced)
    self:UnTagAll();
    self:InboxRefresh();
    self.priv_AutoRunning = nil;
    self.priv_AutoType = nil;
    self.priv_TagTable = nil;
    self.priv_AutoTakeFilter = nil;
    self.priv_TakeAutoDelete = nil;
    self.priv_TakeLastDelete = nil;
    self.priv_TakeDeleteIndex = 0;
    self:ClearAutomationLock();
    self:AutoEnableTabs();
    if (forced) then
      getglobal("UMMFrameTab1TOC"):UnLock();
      UMMNormalBar:SetStatus("");
      UMMNormalBar:Show();
      UMMFrameTab1TOC:ShowInboxStatus();
    end
  end;

  CanMassReturn = function(self)
    local result = nil;

    if (self.priv_Shown) then
      for mi = 1, self.MailCount do
        if (self.Mails[mi].Tagged == true) then
          if (self.Mails[mi].CODAmount + self.Mails[mi].AttachedItems + self.Mails[mi].AttachedMoney + self.Mails[mi].AttachedDiamonds > 0) then
            if (self.Mails[mi].CanReply == true) then
              result = true;
            end
          end
        end
      end
    end
    if (self.priv_AutoRunning) then
      result = nil;
    end

    return result;
  end;

  CanMassDelete = function(self)
    local result = nil;

    if (self.priv_Shown) then
      for mi = 1, self.MailCount do
        if (self.Mails[mi].Tagged == true) then
          if (self.Mails[mi].CODAmount + self.Mails[mi].AttachedItems + self.Mails[mi].AttachedMoney + self.Mails[mi].AttachedDiamonds == 0) then
            result = true;
          end
        end
      end
    end
    if (self.priv_AutoRunning) then
      result = nil;
    end

    return result;
  end;

  TagMailsByTakeOptions = function(self)
    if (self.priv_AutoRunning) then
      self:UnTagAll();
      if (self.priv_Shown) then
        local filter = 0;
        for i = 1, 4 do
          if (getglobal("UMMFrameTab1ToolsOption"..i):IsChecked()) then
            filter = i;
          end
        end
        if (filter > 0) then
          for mi = 1, self.MailCount do
            self.Mails[mi].Tagged = false;
            if (self.Mails[mi].CODAmount == 0) then
              -- Skip any mails with C.O.D. amounds
              if (filter == 1) then
                -- Everything
                if (self.Mails[mi].AttachedMoney + self.Mails[mi].AttachedItems + self.Mails[mi].AttachedDiamonds > 0) then
                  self.Mails[mi].Tagged = true;
                end
              elseif (filter == 2) then
                -- Items
                if (self.Mails[mi].AttachedMoney == 0 and self.Mails[mi].AttachedItems > 0 and self.Mails[mi].AttachedDiamonds == 0) then
                  self.Mails[mi].Tagged = true;
                end
              elseif (filter == 3) then
                -- Money
                if (self.Mails[mi].AttachedMoney > 0 and self.Mails[mi].AttachedItems == 0 and self.Mails[mi].AttachedDiamonds == 0) then
                  self.Mails[mi].Tagged = true;
                end
              elseif (filter == 4) then
                -- Diamonds
                if (self.Mails[mi].AttachedMoney == 0 and self.Mails[mi].AttachedItems == 0 and self.Mails[mi].AttachedDiamonds > 0) then
                  self.Mails[mi].Tagged = true;
                end
              end
            end
          end
        end
      end
    end
  end;

  MassTagMails = function(self, keyword)
    self:UnTagAll();
    for mi = 1, self.MailCount do
      self.Mails[mi].Tagged = false;
      if (string.lower(keyword) == "chars") then
        if (UMMFriends:GetFriendType(self.Mails[mi].Author) == "Character") then
          self.Mails[mi].Tagged = true;
        end
      elseif (string.lower(keyword) == "guildies") then
        if (UMMFriends:GetFriendType(self.Mails[mi].Author) == "Guildie") then
          self.Mails[mi].Tagged = true;
        end
      elseif (string.lower(keyword) == "friends") then
        if (UMMFriends:GetFriendType(self.Mails[mi].Author) == "Friend") then
          self.Mails[mi].Tagged = true;
        end
      elseif (string.lower(keyword) == "other") then
        if (UMMFriends:GetFriendType(self.Mails[mi].Author) == "Other") then
          self.Mails[mi].Tagged = true;
        end
      elseif (string.lower(keyword) == "empty") then
        if (self.Mails[mi].AttachedMoney == 0 and self.Mails[mi].AttachedItems == 0 and self.Mails[mi].AttachedDiamonds == 0) then
          self.Mails[mi].Tagged = true;
        end
      end
    end
  end;

  CopyTagTable = function(self)
    if (self.priv_AutoRunning) then
      self.priv_TagTable = {};
      for mi = 1, self.MailCount do
        local tag = {};
        tag.Tagged = false;
        if (self.Mails[mi].Tagged == true) then
          tag.Tagged = true;
        end
        self.priv_TagTable[mi] = tag;
      end
    end
  end;

  RemoveInboxTOCItem = function(self, mailIndex)
    if (mailIndex > 0) then
      local newIB = {};
      local newTT = {};
      local newCount = 0;
      for index = 1, self.MailCount do
        if (index == mailIndex) then
          -- Skip this one - it's the one we'r deleting
        else
          newCount = newCount + 1;
          newIB[newCount] = self.Mails[index];
          if (self.priv_AutoRunning) then
            newTT[newCount] = self.priv_TagTable[index];
          end
        end
      end
      self.MailCount = newCount;
      self.Mails = newIB;
      if (self.priv_AutoRunning) then
        self.priv_TagTable = newTT;
      end
    end
  end;

  AutoDeleteMail = function(self)
    if (self.priv_AutoRunning) then
      -- First find the index of the first tagged mail
      local mailIndex = 0;
      for mi = 1, self.MailCount do
        if (self.Mails[mi].Tagged == true) then
          if (mailIndex == 0) then
            mailIndex = mi;
          end
        end
      end
      -- Now figure out if it has anything attached to it preventing it from being deleted
      if (mailIndex > 0) then
        local objectCount = 0;
        local packageIcon, sender, subject, COD, moneyMode, money, daysLeft, paperStyle, items, wasRead, wasReturned, canReply = GetInboxHeaderInfo(mailIndex);
        if money and (money > 0) then
          objectCount = objectCount + 1;
        end
        if items and (items > 0) then
          objectCount = objectCount + 1;
        end
        if (self.Mails[mailIndex].CODAmount + self.Mails[mailIndex].AttachedItems + self.Mails[mailIndex].AttachedMoney + self.Mails[mailIndex].AttachedDiamonds + objectCount > 0) then
          UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_CANTDELETE);
          WarningFrame:AddMessage(UMM_ERROR_CANTDELETE);
          self.Mails[mailIndex].Tagged = false;
          self.priv_TagTable[mailIndex].Tagged = false;
          UMMSetGlobalTimeout("UMMMailManager");
        else
          self:RemoveInboxTOCItem(mailIndex);
          DeleteInboxItem(mailIndex);
          self:InboxRefresh();
          getglobal("UMMFrameTab1TOC"):RefreshTOC();
          UMMSetGlobalTimeout("UMMMailManager", true);
        end
      else
        -- We'r done
        self:StopAutomation();
        getglobal("UMMFrameTab1TOC"):UnLock();
        UMMNormalBar:Show();
        UMMFrameTab1TOC:ShowInboxStatus();
      end
    end
  end;

  AutoReturnMail = function(self)
    if (self.priv_AutoRunning) then
      -- First find the index of the first tagged mail
      local mailIndex = 0;
      for mi = 1, self.MailCount do
        if (self.Mails[mi].Tagged == true) then
          if (mailIndex == 0) then
            mailIndex = mi;
          end
        end
      end
      -- Now figure out if it can be returned or not
      if (mailIndex > 0) then
        local canReturn = nil;
        if (self.Mails[mailIndex].CODAmount + self.Mails[mailIndex].AttachedItems + self.Mails[mailIndex].AttachedMoney + self.Mails[mailIndex].AttachedDiamonds > 0) then
          if (self.Mails[mailIndex].CanReply == true) then
            canReturn = true;
          end
        end
        if (canReturn == true) then
          self:RemoveInboxTOCItem(mailIndex);
          ReturnInboxItem(mailIndex);
          UMMSetGlobalTimeout("UMMMailManager");
        else
          UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_CANTRETURN);
          WarningFrame:AddMessage(UMM_ERROR_CANTRETURN);
          self.Mails[mailIndex].Tagged = false;
          self.priv_TagTable[mailIndex].Tagged = false;
          UMMSetGlobalTimeout("UMMMailManager");
        end
      else
        -- We'r done
        self:StopAutomation();
        getglobal("UMMFrameTab1TOC"):UnLock();
        UMMNormalBar:Show();
        UMMFrameTab1TOC:ShowInboxStatus();
      end
    end
  end;

  AutoTakeMail = function(self)
    if (self.priv_AutoRunning) then
      -- First find the index of the first tagged mail
      local mailIndex = 0;
      for mi = 1, self.MailCount do
        if (self.Mails[mi].Tagged == true) then
          local canTake = nil;
          if (self.priv_AutoTakeFilter == 1) then
            -- Everything
            if (self.Mails[mi].AttachedItems + self.Mails[mi].AttachedMoney + self.Mails[mi].AttachedDiamonds > 0) then
              canTake = true;
            end
          elseif (self.priv_AutoTakeFilter == 2) then
            -- Items only
            if (self.Mails[mi].AttachedItems > 0 and self.Mails[mi].AttachedMoney == 0 and self.Mails[mi].AttachedDiamonds == 0) then
              canTake = true;
            end
          elseif (self.priv_AutoTakeFilter == 3) then
            -- Money only
            if (self.Mails[mi].AttachedItems == 0 and self.Mails[mi].AttachedMoney > 0 and self.Mails[mi].AttachedDiamonds == 0) then
              canTake = true;
            end
          elseif (self.priv_AutoTakeFilter == 4) then
            -- Diamonds only
            if (self.Mails[mi].AttachedItems == 0 and self.Mails[mi].AttachedMoney == 0 and self.Mails[mi].AttachedDiamonds > 0) then
              canTake = true;
            end
          end
          if (canTake) then
            if (mailIndex == 0) then
              mailIndex = mi;
            end
          end
        end
      end
      -- Now figure out if it can be looted
      if (mailIndex > 0) then
        if (self.Mails[mailIndex].CODAmount > 0) then
          UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_CANTTAKECOD);
          WarningFrame:AddMessage(UMM_ERROR_CANTTAKECOD);
          self.Mails[mailIndex].Tagged = false;
          self.priv_TagTable[mailIndex].Tagged = false;
          UMMSetGlobalTimeout("UMMMailManager");
        else
          local canTake = nil;
          if (self.priv_AutoTakeFilter == 1) then
            -- Everything
            if (self.Mails[mailIndex].AttachedItems + self.Mails[mailIndex].AttachedMoney + self.Mails[mailIndex].AttachedDiamonds > 0) then
              canTake = true;
            end
          elseif (self.priv_AutoTakeFilter == 2) then
            -- Items only
            if (self.Mails[mailIndex].AttachedItems > 0 and self.Mails[mailIndex].AttachedMoney == 0 and self.Mails[mailIndex].AttachedDiamonds == 0) then
              canTake = true;
            end
          elseif (self.priv_AutoTakeFilter == 3) then
            -- Money only
            if (self.Mails[mailIndex].AttachedItems == 0 and self.Mails[mailIndex].AttachedMoney > 0 and self.Mails[mailIndex].AttachedDiamonds == 0) then
              canTake = true;
            end
          elseif (self.priv_AutoTakeFilter == 4) then
            -- Diamonds only
            if (self.Mails[mailIndex].AttachedItems == 0 and self.Mails[mailIndex].AttachedMoney == 0 and self.Mails[mailIndex].AttachedDiamonds > 0) then
              canTake = true;
            end
          end
          if (canTake) then
            if (self:GetAttachments(mailIndex, nil, nil, nil)) then
              --
            else
              -- This instance should never happen
            end
            if (not self.priv_TakeAutoDelete) then
              self.Mails[mailIndex].Tagged = false;
              if (self.priv_TagTable) then
                self.priv_TagTable[mailIndex].Tagged = false;
              else
                return;
              end
            end
            getglobal("UMMFrameTab1TOC"):RefreshTOC();
            UMMSetGlobalFailTimeout("UMMMailManager");
          else
            UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_CANTTAKE);
            WarningFrame:AddMessage(UMM_ERROR_CANTTAKE);
            if (not self.priv_TakeAutoDelete) then
              self.Mails[mailIndex].Tagged = false;
              self.priv_TagTable[mailIndex].Tagged = false;
            end
            UMMSetGlobalTimeout("UMMMailManager");
          end
        end
      else
        if (self.priv_TakeAutoDelete) then
          -- We'r done taking everything - now let's delete the mails we just emptied
          UMMNormalBar:SetStatus(UMM_INBOX_STATUS_PREPARETAKEDELETE);
          UMMGlobalTimeoutCallFunction = "UMMMailManager";
          UMMGlobalTimeout = UMM_AUTOMATION_BEFORE_DELETE_WAITTIME;
          self.priv_TakeDeleteIndex = -1;
        else
          -- We'r done
          self:StopAutomation();
          getglobal("UMMFrameTab1TOC"):UnLock();
          UMMNormalBar:Show();
          UMMFrameTab1TOC:ShowInboxStatus();
        end
      end
    end
  end;

  StartAutomation = function(self, action)
    self.priv_AutoRunning = true;
    self:AutoDisableTabs();
    if (string.lower(action) == "take") then
      if (self:GetTagCount() == 0) then
        self:TagMailsByTakeOptions();
        UMMFrameTab1TOC:RefreshTOC();
      end
      local filter = 0;
      for i = 1, 4 do
        if (getglobal("UMMFrameTab1ToolsOption"..i):IsChecked()) then
          filter = i;
        end
      end
      self.priv_AutoTakeFilter = filter;
      if (self:GetTagCount() > 0) then
        getglobal("UMMFrameTab1TOC"):Lock();
        UMMNormalBar:Hide();
        UMMNormalBar:SetStatus(UMM_INBOX_STATUS_TAKEALLTAGGED);
        if (getglobal("UMMFrameTab1ToolsCheckTakeDeleteEmpty"):IsChecked()) then
          self.priv_TakeAutoDelete = true;
        else
          self.priv_TakeAutoDelete = nil;
        end
        self:CopyTagTable();
        self.priv_AutoType = "Take";
--        self:AutoTakeMail();
		self:UpdateItemQueueLength();
		self:UpdateBagSlots();
		self:TryAutoTakeMail();
      else
        UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_NOTHINGTAGGED);
        WarningFrame:AddMessage(UMM_ERROR_NOTHINGTAGGED);
        self:StopAutomation(true);
      end
    elseif (string.lower(action) == "return") then
      if (self:GetTagCount() > 0) then
        getglobal("UMMFrameTab1TOC"):Lock();
        UMMNormalBar:Hide();
        UMMNormalBar:SetStatus(UMM_INBOX_STATUS_RETURNTAGGED);
        self:CopyTagTable();
        self.priv_AutoType = "Return";
        self:AutoReturnMail();
      else
        UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_NOTHINGTAGGED);
        WarningFrame:AddMessage(UMM_ERROR_NOTHINGTAGGED);
        self:StopAutomation(true);
      end
    elseif (string.lower(action) == "delete") then
      if (self:GetTagCount() > 0) then
        getglobal("UMMFrameTab1TOC"):Lock();
        UMMNormalBar:Hide();
        UMMNormalBar:SetStatus(UMM_INBOX_STATUS_DELETETAGGED);
        self:CopyTagTable();
        self.priv_AutoType = "Delete";
        self:AutoDeleteMail();
      else
        UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_NOTHINGTAGGED);
        WarningFrame:AddMessage(UMM_ERROR_NOTHINGTAGGED);
        self:StopAutomation(true);
      end
    elseif (string.lower(action) == "send") then
      -- Composer - single mail
    elseif (string.lower(action) == "masssend") then
      -- Mass Send Items
    end
  end;

  AttachmentSucceeded = function(self)
    if (self.priv_AutoRunning) then
      getglobal("UMMFrameTab1TOC"):RefreshTOC();
--      UMMSetGlobalTimeout("UMMMailManager");
    end
  end;

  AttachmentFailed = function(self)
    if (self.priv_AutoRunning) then
      self:StopAutomation(true);
      getglobal("UMMFrameTab1TOC"):RefreshTOC();
    end
  end;

  UnLock = function(self, type, forced)
    if (forced) then
      self.priv_Locked = true;
      self.priv_LockItem = nil;
      self.priv_LockMoney = nil;
    end
    if (self.priv_Locked == true) then
      if (string.lower(type) == "item") then
        self.priv_LockItem = nil;
      end
      if (string.lower(type) == "money") then
        self.priv_LockMoney = nil;
      end
      if (not self.priv_LockItem and not self.priv_LockMoney) then
        if (self.priv_LockFrame) then
          getglobal(self.priv_LockFrame):RefreshViewer();
        end
        if (self.priv_LockReturnFrame) then
          getglobal(self.priv_LockReturnFrame):ReturnUnLocked();
        end
        if (self.priv_LockFrame == nil and self.priv_LockReturnFrame == nil) then
          getglobal("UMMFrameTab1TOC"):RefreshTOC();
          UMMSetGlobalTimeout("UMMMailManager");
        end
        self:ClearAutomationLock();
      end
    end
  end;

  ReturnUnLocked = function(self)
    if (self.priv_AutoRunning) then
      if (self.priv_AutoType == "Take") then
--        self:AutoTakeMail();
      end
    end
  end;

  TimeOutFailed = function(self)
    self:StopAutomation(true);
    getglobal("UMMFrameTab1TOC"):RefreshTOC();
  end;

  TimeOut = function(self)
    if (self.priv_AutoRunning) then
      if (self.priv_AutoType == "Take" and self.priv_TakeDeleteIndex == -1) then
        self:StopAutomation();
        getglobal("UMMFrameTab1TOC"):UnLock();
        UMMNormalBar:Show();
        self:StartAutomation("Delete");
      else
        if (self.priv_AutoType == "Take") then
          getglobal("UMMFrameTab1TOC"):RefreshTOC();
--          self:AutoTakeMail();
        elseif (self.priv_AutoType == "Return") then
          getglobal("UMMFrameTab1TOC"):RefreshTOC();
          self:AutoReturnMail();
        elseif (self.priv_AutoType == "Delete") then
          getglobal("UMMFrameTab1TOC"):RefreshTOC();
          self:AutoDeleteMail();
        end
      end
    end
  end;

  Clear = function(self)
	self.ItemQueueLength = 0;
    self.MailCount = 0;
    self.InboxOffset = 0;
    self.InboxTotalMoney = 0;
    self.InboxTotalDiamonds = 0;
    self.Mails = {};
    self.lastMailCount = 0;
    self.priv_Shown = nil;

    self.priv_Locked = nil;
    self.priv_LockItem = nil;
    self.priv_LockMoney = nil;
    self.priv_LockFrame = nil;
    self.priv_LockReturnFrame = nil;

    self.priv_TakeAutoDelete = nil;
    self.priv_TakeLastDelete = nil;
    self.priv_TakeDeleteIndex = 0;

    self.priv_AutoRunning = nil;
    self.priv_AutoType = nil;
    self.priv_TagTable = nil;
    self.priv_AutoTakeFilter = nil;

    self:StopAutomation(true);
  end;

}; -- MailManager
