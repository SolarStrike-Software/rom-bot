
-- ###########################
-- ##                       ##
-- ##  Miscellaneous Tools  ##
-- ##                       ##
-- ###########################

-- ### Locale Loader ###

local LOCALE_PATH = "Interface/AddOns/UltimateMailMod/Locales/";

local function LoadLUAFile(fileName)
  local func, err = loadfile(fileName);
  if err then
    return false, err;
  else
    dofile(fileName);
    return true;
  end
end

local locale = string.sub(GetLanguage(), 1, 2);
LoadLUAFile(LOCALE_PATH.."EN.lua")
if locale ~= "EN" then
	LoadLUAFile(LOCALE_PATH..locale..".lua")
end

-- ### Miscellaneous Public Functions ###

function UMMPrompt(strMessage)
  local prefix = "|cff"..UMMColor.Header.."[|r|cff"..UMMColor.Medium..UMM_PROMPT.."|r|cff"..UMMColor.Header.."] |r";
  local msgColor = "|cff"..UMMColor.Bright;
  DEFAULT_CHAT_FRAME:AddMessage(prefix..msgColor..strMessage.."|r");
end

local function Pad3Zero(v)
  local wrk = ""..v.."";
  if (string.len(wrk) == 1) then
    wrk = "00"..v.."";
  elseif (string.len(wrk) == 2) then
    wrk = "0"..v.."";
  end
  return ""..wrk.."";
end

function UMMFormatNumber(n)
  local MONEY_DIVIDER = 1000;
  local result, value, giga, mega, kilo, rest;

  value = n;

  mega = math.floor(value / (MONEY_DIVIDER * MONEY_DIVIDER));
  kilo = math.floor((value - (mega * (MONEY_DIVIDER * MONEY_DIVIDER))) / MONEY_DIVIDER);
  rest = math.mod(value, MONEY_DIVIDER);
  if (mega > 999) then
    value = mega;
    local dummy = math.floor(value / (MONEY_DIVIDER * MONEY_DIVIDER));
    giga = math.floor((value - (dummy * (MONEY_DIVIDER * MONEY_DIVIDER))) / MONEY_DIVIDER);
    mega = math.mod(value, MONEY_DIVIDER);
  else
    giga = 0;
  end

  result = "";
  if (giga > 0) then
    result = result .. giga .. ",";
  end
  if (mega > 0) then
    if (giga > 0) then
      result = result .. Pad3Zero(mega);
    else
      result = result .. mega;
    end
    result = result .. ",";
  elseif (giga > 0) then
    result = result .. "000,";
  end
  if (kilo > 0) then
    if (mega > 0) then
      result = result .. Pad3Zero(kilo);
    else
      result = result .. kilo;
    end
    result = result .. ",";
  elseif (mega > 0 or giga > 0) then
    result = result .. "000,";
  end
  if (rest > 0) then
    if (kilo > 0) then
      result = result .. Pad3Zero(rest);
    else
      result = result .. rest;
    end
  elseif (kilo > 0 or mega > 0 or giga > 0) then
    result = result .. "000";
  end

  return result;
end

-- Global timing

UMMGlobalTimeout = 0;
UMMGlobalFailTimeout = 0;
UMMGlobalTimeoutCallFunction = nil;
UMMGlobalFailTimeoutCallFunction = nil;
UMMGlobalInboxLoadTimeout = 0;

UMM_GLOBAL_AUTOMATION_WAITTIME    = 0.3;
UMM_GLOBAL_AUTOMATION_WAITTIMEOUT = 10;
UMM_AUTOMATION_BEFORE_DELETE_WAITTIME = 1.0;
UMM_AUTOMATION_DELETE_WAITTIME    = 0.15;

function UMMSetGlobalFailTimeout(callFunction)
  UMMGlobalFailTimeoutCallFunction = callFunction;
  UMMGlobalFailTimeout = UMM_GLOBAL_AUTOMATION_WAITTIMEOUT;
end

function UMMSetGlobalTimeout(callFunction, deleteTimer)
  UMMGlobalTimeoutCallFunction = callFunction;
  if (deleteTimer) then
    UMMGlobalTimeout = UMM_AUTOMATION_DELETE_WAITTIME;
  else
    UMMGlobalTimeout = UMM_GLOBAL_AUTOMATION_WAITTIME;
  end
  UMMSetGlobalFailTimeout(callFunction);
end

function UMMAutoResizeWidth(widget, minwidth)
	-- For use with buttons. Don't know if it can be used with other widgets.
	local textWidth = widget:GetNormalText():GetDisplayWidth() + 20
	if minwidth and textWidth < minwidth then
		textWidth = minwidth
	end

	widget:SetWidth(textWidth)
	widget:SetText(widget:GetText())
end
