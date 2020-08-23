
-- ##  Global Configuration  ##

UMMConfig = nil;

UMMSettings = {
  
  Save = function(self)
    SaveVariables("UMMConfig");
  end;
  
  Set = function(self, entry, value)
    if (UMMConfig == nil) then
      self:Init();
    end
    UMMConfig.Settings[entry] = value;
    self:Save();
  end;
  
  Get = function(self, entry)
    if (UMMConfig.Settings ~= nil) then
      if (UMMConfig.Settings[entry]) then
        return UMMConfig.Settings[entry];
      else
        return nil;
      end
    else
      return nil;
    end
  end;
  
  Init = function(self)
    if (UMMConfig == nil) then
      UMMConfig = {};
    end
    if (UMMConfig.Settings == nil) then
      UMMConfig.Settings = {};
      self:Set("AudioWarning", true);
      self:Set("DeleteDelay", 1.0);
    end
    if (UMMConfig.NewMail == nil) then
      UMMConfig.NewMail = {};
    end
    if (UMMConfig.Characters == nil) then
      UMMConfig.Characters = {};
    end
    self:Save();
  end;

  CheckCharacter = function(self)
    if (UMMConfig == nil) then
      self:Init();
    end
    local name = UnitName("player");
    if (name ~= nil and name ~= "") then
      local found = nil;
      for index = 1, table.getn(UMMConfig.Characters) do
        if (UMMConfig.Characters[index] == name) then
          found = true;
          break;
        end
      end
      if (not found) then
        table.insert(UMMConfig.Characters, name);
        table.sort(UMMConfig.Characters);
      end
    end
    self:Save();
  end;
  
  NewMail = function(self, number)
    if (number == nil) then
      local name = UnitName("player");
      if (name ~= nil and name ~= "") then
        return UMMConfig.NewMail[name];
      else
        return 0;
      end
    else
      if (UMMConfig == nil) then
        self:Init();
      end
      local name = UnitName("player");
      if (name ~= nil and name ~= "") then
        UMMConfig.NewMail[name] = number;
      end
      self:Save();
    end
  end;
  
  NoNewMail = function(self)
    if (UMMConfig == nil) then
      self:Init();
    end
    local name = UnitName("player");
    if (name ~= nil and name ~= "") then
      UMMConfig.NewMail[name] = 0;
    end
    self:Save();
  end;
  
};

