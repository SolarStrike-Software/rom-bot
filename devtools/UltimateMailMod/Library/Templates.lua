
-- #################################
-- ##                             ##
-- ##  General Purpose Templates  ##
-- ##                             ##
-- #################################

function UMMListTemplate_Init(this, type)
  getglobal(this:GetName()..type):SetAlpha(0.2);
  getglobal(this:GetName()..type):Hide();
end

function UMMMoneyFrameTemplate_OnLoad(this)

  this.SetAmount = function(self, amount, color)
    if (color) then
      if (string.lower(color) == "gold") then
        getglobal(self:GetName().."Amount"):SetText("|cff"..UMMColor.Yellow..UMMFormatNumber(amount).."|r");
      elseif (string.lower(color) == "diamond") then
        getglobal(self:GetName().."Amount"):SetText("|cff"..UMMColor.Bright..UMMFormatNumber(amount).."|r");
      end
    else
      getglobal(self:GetName().."Amount"):SetText("|cff"..UMMColor.White..UMMFormatNumber(amount).."|r");
    end
    self:Show();
  end;

end

UMMNormalBar = {

  priv_Initialized = nil;

  Hide = function(self)
    getglobal("UMMFrameModVersion"):Hide();
    getglobal("UMMFrameSettingAudioAlert"):Hide();
    getglobal("UMMFrameStatus"):SetText("");
    getglobal("UMMFrameStatus"):Show();
  end;

  Show = function(self)
    getglobal("UMMFrameModVersion"):Show();
    getglobal("UMMFrameSettingAudioAlert"):Show();
    getglobal("UMMFrameStatus"):SetText("");
    getglobal("UMMFrameStatus"):Hide();
  end;

  SetStatus = function(self, text)
    getglobal("UMMFrameStatus"):SetText("|cff"..UMMColor.Medium..text.."|r");
  end;

  Init = function(self)
    if (not self.priv_Initialized) then
      getglobal("UMMFrameSettingAudioAlertLabel"):SetText("|cff"..UMMColor.Medium..UMM_SETTINGS_AUDIOWARNING.."|r");

	  local versionstring = "|cff"..UMMColor.Header.."v"..UMM_VERSION.Major.."."..UMM_VERSION.Minor.."."..UMM_VERSION.Revision.." ("..UMM_VERSION.Build..")|r"
      getglobal("UMMFrameModVersion"):SetText(versionstring.. " - Rock5 Mod v"..UMM_ROCK5_VERSION);
      self.priv_Initialized = true;
    end
  end;

};
