
-- ##########################
-- ##                      ##
-- ##  Recipient Handling  ##
-- ##                      ##
-- ##########################

UMMFriends = {
  
  List = {};
  
  AddFriend = function(self, name, type, online)
    if (self.List[name] == nil) then
      self.List[name] = {};
      self.List[name].Guild  = false;
      self.List[name].Friend = false;
      self.List[name].Own    = false;
      self.List[name].Online = false;
    end
    if (string.lower(type) == "friend") then
      self.List[name].Friend = true;
    end
    if (string.lower(type) == "guild") then
      self.List[name].Guild = true;
    end
    if (string.lower(type) == "own") then
      self.List[name].Own = true;
    end
    if (online) then
      self.List[name].Online = true;
    else
      self.List[name].Online = false;
    end
  end;
  
  IsFriend = function(self, name)
    if (self.List[name] == nil) then
      return nil;
    else
      return true;
    end
  end;
  
  GetFriendType = function(self, name)
    if (self.List[name] == nil) then
      return "Other";
    else
      if (self.List[name].Own == true) then
        return "Character";
      elseif (self.List[name].Guild == true) then
        return "Guildie";
      elseif (self.List[name].Friend == true) then
        return "Friend";
      else
        return "Other";
      end
    end
  end;
  
  GetColor = function(self, name, onlineOverride)
    if (self.List[name] == nil) then
      return UMMColor.Yellow;
    else
      if (self.List[name].Own == true) then
        return UMMColor.Own;
      elseif (self.List[name].Guild == true) then
        if (not onlineOverride) then
          if (self.List[name].Online == true) then
            return UMMColor.Green;
          else
            return UMMColor.DarkGrey;
          end
        else
          return UMMColor.Green;
        end
      elseif (self.List[name].Friend == true) then
        if (not onlineOverride) then
          if (self.List[name].Online == true) then
            return UMMColor.Cyan;
          else
            return UMMColor.DarkGrey;
          end
        else
          return UMMColor.Cyan;
        end
      else
        return UMMColor.Yellow;
      end
    end
  end;
  
  Load = function(self)
    self.List = {};
    -- Start with own characters
    self:AddFriend(UnitName("player"), "own");
    for index = 1, table.getn(UMMConfig.Characters) do
      self:AddFriend(UMMConfig.Characters[index], "own");
    end
    if (UMM_OwnCharacters) then
      for index = 1, table.getn(UMM_OwnCharacters) do
        self:AddFriend(UMM_OwnCharacters[index], "own");
      end
    end
    
    -- Now add "Friends"
    local friendCount = GetFriendCount("Friend");
    
    for index = 1, friendCount do
      local name, groupID, online, eachOther, unmodifiable, top, killMeCount, revengeCount, relationType, relationLv = GetFriendInfo("Friend", index);
      self:AddFriend(name, "Friend", online);
    end
    
    -- Now add "Guildies" if any
    if (IsInGuild()) then
      local guildCount = GetNumGuildMembers();
      for index = 1, guildCount do
        local name, rank, class, level, subClass, subLevel, isHeader, isCollapsed, dbid, guildTitle, IsOnLine, LogOutTime, Zone, Note = GetGuildRosterInfo(index);
        self:AddFriend(name, "Guild", IsOnLine);
      end
    end
  end;
  
  Clear = function(self)
    self.List = {};
  end;
  
};

local ListSlotCount = 28;

function UMMRecipientListTemplate_OnLoad(this)
  
  this.BaseColor    = UMMColor.Yellow;
  this.BaseTitle    = "";
  this.Own          = nil;
  this.Friend       = nil;
  this.Guild        = nil;
  this.Target       = nil;
  this.NameList     = {};
  this.MultiSelect  = nil;
  this.offset       = 0;
  this.hideFunc     = nil;
  
  this.Refresh = function(self)
    for idx = 1, ListSlotCount do
      index = idx + self.offset;
      local button = getglobal(self:GetName().."ListName"..idx);
      if (index <= table.getn(self.NameList)) then
        local name = self.NameList[index];
        local color = self.BaseColor;
        if (UMMFriends.List[name].Online == true) then
          color = self.BaseColor;
        else
          if (self.Own == true) then
            color = self.BaseColor;
          else
            color = UMMColor.DarkGrey;
          end
        end
        getglobal(button:GetName().."Name"):SetText("|cff"..color..self.NameList[index].."|r");
        button:Show();
      else
        button:Hide();
      end
    end
  end;
  
  this.ScrollChanged = function(self, scrollObject)
    self.offset = scrollObject:GetValue();
    self:Refresh();
  end;
  
  this.SetupList = function(self, type)
    if (string.lower(type) == "own") then
      self.BaseColor = UMMColor.Own;
      self.BaseTitle = UMM_RECIPIENT_OWN;
      self.Own = true;
    elseif (string.lower(type) == "friend") then
      self.BaseColor = UMMColor.Cyan;
      self.BaseTitle = UMM_RECIPIENT_FRIEND;
      self.Friend = true;
    elseif (string.lower(type) == "guild") then
      self.BaseColor = UMMColor.Green;
      self.BaseTitle = UMM_RECIPIENT_GUILD;
      self.Guild = true;
    else
      self.BaseColor = UMMColor.Yellow;
      self.BaseTitle = "?????";
    end
    getglobal(self:GetName().."HeaderTitle"):SetText("|cff"..self.BaseColor..self.BaseTitle.."|r");
    
    self.NameList = {};
    for name in pairs(UMMFriends.List) do
      if (self.Guild == true) then
        if (UMMFriends.List[name].Guild == true) then
          table.insert(self.NameList, name);
        end
      elseif (self.Friend == true) then
        if (UMMFriends.List[name].Friend == true) then
          table.insert(self.NameList, name);
        end
      elseif (self.Own == true) then
        if (UMMFriends.List[name].Own == true) then
          table.insert(self.NameList, name);
        end
      end
    end
    table.sort(self.NameList);
    if (self.Own == true) then
      -- Rebuild the list according to hardwired list
      if (UMM_OwnCharacters) then
        if (table.getn(UMM_OwnCharacters) > 0) then
          local newList = {};
          -- First add the names on the hardwired list ...
          for index = 1, table.getn(UMM_OwnCharacters) do
            local name = UMM_OwnCharacters[index];
            table.insert(newList, name);
            UMMFriends:AddFriend(name, "own");
          end
          -- Now loop through any other names found / stored
          for index = 1, table.getn(self.NameList) do
            local name = self.NameList[index];
            local found = nil;
            for nl = 1, table.getn(newList) do
              if (string.lower(name) == string.lower(newList[nl])) then
                found = true;
                break;
              end
            end
            if (not found) then
              table.insert(newList, name);
              UMMFriends:AddFriend(name, "own");
            end
          end
          -- Now copy the new list
          self.NameList = {};
          for index = 1, table.getn(newList) do
            local name = newList[index];
            table.insert(self.NameList, name);
          end
          newList = nil;
        end
      end
    end
    
    for idx = 1, ListSlotCount do
      local button = getglobal(self:GetName().."ListName"..idx);
      button:ClearAllAnchors();
      button:SetAnchor("TOPLEFT", "TOPLEFT", self:GetName().."List", 10, ((idx * 15) - 15) + 10);
    end
    
    if (table.getn(self.NameList) > ListSlotCount) then
      getglobal(self:GetName().."ListScroll"):SetMaxValue(table.getn(self.NameList) - ListSlotCount);
      getglobal(self:GetName().."ListScroll"):SetValue(self.offset);
      getglobal(self:GetName().."ListScroll"):Show();
    else
      getglobal(self:GetName().."ListScroll"):Hide();
    end
    
    self:Refresh();
  end;
  
  this.SetSelectDone = function(self, funcName)
    self.hideFunc = funcName;
  end;
  
  this.SetTarget = function(self, targetName)
    self.Target = targetName;
  end;
  
  this.Hover = function(self, id)
    getglobal(self:GetName().."ListName"..id.."Hover"):Show();
  end;
  
  this.UnHover = function(self, id)
    getglobal(self:GetName().."ListName"..id.."Hover"):Hide();
  end;
  
  this.Click = function(self, id)
    if (self.MultiSelect == true) then
      
    else
      index = id + self.offset;
      if (index <= table.getn(self.NameList)) then
        getglobal(self.Target):SetText(self.NameList[index]);
        if (self.hideFunc) then
          getglobal(self.hideFunc):SelectDone();
        end
      end
    end
  end;
  
end

function UMMRecipientNameSelectorTemplate_OnEnter(this)
  local id = this:GetID();
  this:GetParent():GetParent():Hover(id);
end

function UMMRecipientNameSelectorTemplate_OnClick(this)
  local id = this:GetID();
  this:GetParent():GetParent():Click(id);
end

function UMMRecipientNameSelectorTemplate_OnLeave(this)
  local id = this:GetID();
  this:GetParent():GetParent():UnHover(id);
end

