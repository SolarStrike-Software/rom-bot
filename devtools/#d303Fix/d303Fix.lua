--[[
	d303Fix v0.9 by DRACULA
	Released under to public domain - http://en.wikipedia.org/wiki/Public_Domain
]]

-- Remove older version of d303Fix
if d303Fix and (not d303Fix.NumVer or d303Fix.NumVer < 9) then
	d303Fix = nil
end

-- Declare if it's not declared
if not d303Fix then
	-- Slash commands
	SLASH_d303FixIS1 = "/dtis";
	SLASH_d303FixIS2 = "/osis";
	SLASH_d303FixSS1 = "/dtss";
	SLASH_d303FixSS2 = "/osss";

	-- Slash commands handling
	SlashCmdList["d303FixIS"] = function(editBox, msg) d303Fix.SwitchFunc(d303Fix.ItemShop_FuncTable, msg) end;
	SlashCmdList["d303FixSS"] = function(editBox, msg) d303Fix.SwitchFunc(d303Fix.ScreenShot_FuncTable, msg) end;

	-- Saved variables
	d303Fix_ScreenShot			= true;
	d303Fix_ScreenShotAuto		= false;
	d303Fix_ScreenShotOnFail	= false;
	d303Fix_ItemShop			= true;
	d303Fix_ItemShopOffset		= 2;

	d303Fix = {
		Version					= "v0.9",
		NumVer					= 9,
		Path					= "Interface/AddOns/#d303Fix/",
		
		startTime				= math.floor(GetTime()),
		baseTime				= 0,
		timeSetFromItemShop		= false,
		itemShopRetries			= 10,
		itemShopTimer			= 0,
		
		ScreenShot				= true,
		ScreenShotAuto			= false,
		ScreenShotOnFail		= false,
		ItemShop				= true,
		ItemShopOffset			= 2,
		
		ItemShop_FuncTable = {
			["help"]	= function (msg) d303Fix.print(d303Fix.Strings.Header..d303Fix.Strings.ItemShop.Help) end,
			["on"]		= function (msg) d303Fix.ItemShop = true  d303Fix.print(d303Fix.Strings.Header..d303Fix.Strings.ItemShop.On) end,
			["off"]		= function (msg) d303Fix.ItemShop = false d303Fix.print(d303Fix.Strings.Header..d303Fix.Strings.ItemShop.Off) end,
			default		= function (msg) if (msg ~= nil and msg ~= "") then d303Fix.SetItemShopOffset(tonumber(msg)); end; d303Fix.Reset(); end,
		},
		
		ScreenShot_FuncTable = {
			["help"]	= function (msg) d303Fix.print(d303Fix.Strings.Header..d303Fix.Strings.ScreenShot.Help) end,
			["on"]		= function (msg) d303Fix.ScreenShot = true  d303Fix.print(d303Fix.Strings.Header..d303Fix.Strings.ScreenShot.On)	end,
			["off"]		= function (msg) d303Fix.ScreenShot = false d303Fix.print(d303Fix.Strings.Header..d303Fix.Strings.ScreenShot.Off)	end,
			["auto"]	= function (msg) d303Fix.ScreenShotAuto		= not d303Fix.ScreenShotAuto;	d303Fix.print(d303Fix.Strings.Header..d303Fix.Strings.ScreenShot.Auto..d303Fix.Strings.ScreenShot[d303Fix.ScreenShotAuto and "Yes" or "No"]..".") end,
			["fail"]	= function (msg) d303Fix.ScreenShotOnFail	= not d303Fix.ScreenShotOnFail;	d303Fix.print(d303Fix.Strings.Header..d303Fix.Strings.ScreenShot.OnFail..d303Fix.Strings.ScreenShot[d303Fix.ScreenShotOnFail and "Yes" or "No"]..".") end,
			default		= function (msg) TakeScreenshot() end,
		},

		Events_FuncTable = {
			["CHAT_MSG_SYSTEM"]		= function (event, arg1) 
					-- Take screen shot if enabled
					if d303Fix.ScreenShot and string.find(string.lower(arg1), "screenshot") then 
						d303Fix.SetClockFromSystemEvent(arg1)
					end 
				end,
			["LOADING_END"]			= function (event)
					-- Force Item Shop to init
					if d303Fix_ItemShop and not d303Fix.timeSetFromItemShop then
						ItemMallFrame:Show();
						ItemMallFrame:Hide();
					end
					if d303Fix_ScreenShot and d303Fix_ScreenShotAuto and not d303Fix.timeSetFromItemShop then
						TakeScreenshot()
					end
				end,
			["VARIABLES_LOADED"]	= function (event)
					for _,v in ipairs(d303Fix.variablesToSave) do
						d303Fix[v] = (_G["d303Fix_"..v] == nil) and d303Fix[v] or _G["d303Fix_"..v]
					end
				end,
			["SAVE_VARIABLES"]		= function (event)
					for _,v in ipairs(d303Fix.variablesToSave) do
						_G["d303Fix_"..v] = d303Fix[v]
					end
				end,
			default					= nil,
		},
		
		Strings = {
			Header			= "[|cff00ff00d303Fix|r] ",
			Init			= "Loaded with date and time: %s.\
	Type |cff00ff00/dtis help|r or |cff00ff00/dtss help|r to get more info abour slash commands.",
			NoFn			= "Function \"%s\" is not available.",
			OsRedeclared	= "os object is already declared. Replacing.",
			
			ItemShop = {
				On			= "Item Shop will be probed in order to set date and time.",
				Off			= "Item Shop will not be probed in order to set date and time.",
				Offset		= "Offset of time probed from Item Shop set to %d hour(s).",
				Attempt		= "Attempt to extract time info from Item Shop.",
				Success		= "Date and time set to: %s with %d hour offset using info from Item Shop: \"%s\".",
				Fail		= "Attempt to extract time info from Item Shop failed. %d retries remaining.",
				Help		= "Item Shop related commands:\
	- |cff00ff00/dtis help|r - Display this info.\
	- |cff00ff00/dtis off|r - Disable ability to set time from Item Shop.\
	- |cff00ff00/dtis on|r - Enable ability to set time from Item Shop.\
	- |cff00ff00/dtis [hours]|r - Set offset in hours when probing time from Item Shop.\
	- |cff00ff00/dtis|r - Reset clock (and if enabled set clock again).",
			},
			
			ScreenShot = {
				On			= "Screenshot will set date and time.",
				Off			= "Screenshot will not set date and time.",
				OnFail		= "Screenshot will be taken to set date and time when ItemShop probing fails: ",
				Auto		= "Screenshot will be taken to set date and time during login: ",
				Yes 		= "yes",
				No			= "no",
				Attempt		= "Attempt to extract time info from Screenshot name.",
				Success		= "Date and time set to: %s using Screenshot name",
				Help		= "Screenshot related commands:\
	- |cff00ff00/dtss help|r - Display this info.\
	- |cff00ff00/dtss off|r - Disable ability to set time from Screenshot name.\
	- |cff00ff00/dtss on|r - Enable ability to set time from Screenshot name.\
	- |cff00ff00/dtss auto|r - Toggle ability to set time from Screenshot name on login.\
	- |cff00ff00/dtss fail|r - Toggle ability to set time from Screenshot name when ItemShop probing fails.\
	- |cff00ff00/dtss|r - Take a screenshot (regardles of oprion above).",
			},
			
			MonthsShort		= { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", },
			MonthsFull		= { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December", },
		
			WeekDaysShort	= { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", },
			WeekDaysFull	= { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", },
		},

		secondsInMonth = {	2678400, 2419200, 2678400, 2592000, 2678400, 2592000, 2678400, 2678400, 2592000, 2678400, 2592000, 2678400,
							2678400, 2505600, 2678400, 2592000, 2678400, 2592000, 2678400, 2678400, 2592000, 2678400, 2592000, 2678400, },
						
		secondsRepresentation = {	second	= 1,		min		= 60,		hour	= 3600,
									day		= 86400,	year	= 31536000,	lyear	= 31622400, },

		--[[ -- http://wiki.ptokax.ch/doku.php/scriptinghelp/osdate
			”%a”	The abbreviated weekday name. Example: Thu.
			”%A”	The full weekday name. Example: Thursday.
			”%b”	The abbreviated month name. Example: Sep.
			”%B”	The full month name. Example: September.
			”%d”	The two-digit day of the month padded with leading zeroes if applicable. Example: 09.
			”%e”	The day of the month space padded if applicable. Example: 9.
			”%H”	The two-digit military time hour padded with a zero if applicable. Example: 16.
			”%I”	The two-digit hour on a 12-hour clock padded with a zero if applicable. Example: 04.
			”%j”	The three-digit day of the year padded with leading zeroes if applicable. Example: 040.
			”%k”	The two-digit military time hour padded with a space if applicable. Example: 9.
			”%l”	The hour on a 12-hour clock padded with a space if applicable. Example: 4.
			”%m”	The two-digit month padded with a leading zero if applicable. Example: 09.
			”%M”	The two-digits minute padded with a leading zero if applicable. Example: 02.
			”%p”	Either AM or PM. Language dependent.
			”%S”	The two-digit second padded with a zero if applicable. Example: 04.
			”%w”	The numeric day of the week ranging from 0 to 6 where 0 is Sunday. Example: 0.
			”%x”	The language-aware standard date representation. For most languages, this is just the same as %B %d, %Y. Example: September 06, 2002.
			”%X”	The language-aware time representation. For most languages, this is just the same as %I:%M %p. Example: 04:31 PM.
			”%y”	The two-digit year padded with a leading zero if applicable. Example: 01.
			”%Y”	The four-digit year. Example: 2001.
		]]
		patterns = {
			["%a"]	= function (str,key,t) return string.gsub(str, "%"..key, d303Fix.Strings.WeekDaysShort[tonumber(t.wday )]) end,
			["%A"]	= function (str,key,t) return string.gsub(str, "%"..key, d303Fix.Strings.WeekDaysFull[tonumber(t.wday)]) end,
			["%b"]	= function (str,key,t) return string.gsub(str, "%"..key, d303Fix.Strings.MonthsShort[tonumber(t.month)] or "Unknown") end,
			["%B"]	= function (str,key,t) return string.gsub(str, "%"..key, d303Fix.Strings.MonthsFull[tonumber(t.month)] or "Unknown") end,
			["%c"]	= function (str,key,t) return string.gsub(str, "%"..key, string.format("%04d-%02d-%02d %02d:%02d:%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)) end,
			["%d"]	= function (str,key,t) return string.gsub(str, "%"..key, string.format("%02d", t.day)) end,
			["%H"]	= function (str,key,t) return string.gsub(str, "%"..key, string.format("%02d", t.hour)) end,
			["%I"]	= function (str,key,t) return string.gsub(str, "%"..key, string.format("%02d", ((t.hour == 0) and (t.hour+12) or ((t.hour>12) and (t.hour-12) or (t.hour))))) end,
			["%M"]	= function (str,key,t) return string.gsub(str, "%"..key, string.format("%02d", t.min)) end,
			["%m"]	= function (str,key,t) return string.gsub(str, "%"..key, string.format("%02d", t.month)) end,
			["%p"]	= function (str,key,t) return string.gsub(str, "%"..key, (((t.hour / 12) >= 1) and "pm" or "am")) end,
			["%S"]	= function (str,key,t) return string.gsub(str, "%"..key, string.format("%02d", t.sec)) end,
			["%w"]	= function (str,key,t) return string.gsub(str, "%"..key, d303Fix.Strings.WeekDaysFull[tonumber(t.wday)] or "Unknown") end,
			["%x"]	= function (str,key,t) return string.gsub(str, "%"..key, string.format("%04d-%02d-%02d", t.year, t.month, t.day)) end,
			["%X"]	= function (str,key,t) return string.gsub(str, "%"..key, string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)) end,
			["%Y"]	= function (str,key,t) return string.gsub(str, "%"..key, string.format("%04d", t.year)) end,
			["%y"]	= function (str,key,t) return string.gsub(str, "%"..key, string.sub(string.format("%04d", t.year), 3)) end,
		},
		
		conversion = {
			["number"]	= function(param) d303Fix.baseTime = param - GetTime(); return true end,
			["table"]	= function(param) d303Fix.baseTime = d303Fix.time(param) - GetTime(); return true end,
			["string"]	= function(param) if string.len(param) == 19 then
								-- Assume format 'yyyy-MM-dd HH:mm:ss'
								local _, _, y, m, d, h, M, s = string.find(param, "(%d+)-(%d+)-(%d+)%s+(%d+):(%d+):(%d+)");
								d303Fix.baseTime = d303Fix.time( { year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = tonumber(h), min = tonumber(M), sec = tonumber(s) } ) - GetTime()
								return true
							elseif string.len(param) == 15 then
								-- Assume format 'yyyyMMdd_HHmmss'
								--                1   5 7  0 2 4							
								d303Fix.baseTime = d303Fix.time({	["year"] 	=	tonumber(string.sub(param, 1, 4)),		["month"] 	=	tonumber(string.sub(param, 5, 6)),		["day"] 	=	tonumber(string.sub(param, 7, 8)),
																	["hour"] 	=	tonumber(string.sub(param, 10, 11)),	["min"] 	=	tonumber(string.sub(param, 12, 13)),	["sec"] 	=	tonumber(string.sub(param, 14, 15)),	}) - GetTime()
								return true
							else
								return false
							end
						end,
		},
		
		variablesToSave = { "ItemShopOffset", "ItemShop", "ScreenShot", "ScreenShotAuto", "ScreenShotOnFail", },
		
		osFunctionsNames = { "print", "clock", "time", "difftime", "date", 
							 "exit", "execute", "getenv", "remove", "rename", "setlocale", "tmpname" },

		print = function(msg)
				if (msg == nil) then
					msg = "Error. Tried to print nil message";
				end;
				
				DEFAULT_CHAT_FRAME:AddMessage(msg);
			end,
			
		SafeLoadFile = function(fileName)
				local func, err = loadfile(fileName);
				if (err) then
					d303Fix.print("Can't load file: '"..fileName.."'.");
					return false;
				end;
				
				dofile(fileName);
				return true;
			end,
		
		IsLeapYear = function(year)
				return ((year % 4 == 0) and (year  % 100 ~= 0) or (year % 400 == 0 and year % 1000 ~= 0))
			end,

		IsAnyNil = function(param)
				if not param then
					return true, nil
				end
				
				if type(param) == "table" then
					for k,v in ipairs(param) do
						if not v then
							return true, k
						end
					end
				end
				
				return false, nil
			end,
			
		-- Specific function allowing to make case steaatements
		SwitchFunc = function(codetable, case, ...)
				-- Get function or default function from table
				local f = codetable[case] or codetable.default
				if f and type(f) == "function" then
					-- If exist and it is function, execute it
					return f(case, ...)
				else
					-- Display error
					d303Fix.AddChatMessage("case "..tostring(case).." not a function.");
				end
			end,

		OnLoad = function(this)
				-- Loop events to register
				for e,f in pairs(d303Fix.Events_FuncTable) do
					this:RegisterEvent(e);
				end
				
				-- Loop variables to save
				for _,v in ipairs(d303Fix.variablesToSave) do
					SaveVariables("d303Fix_"..v);
				end
				
				-- Language support
				local gamelang = GetLanguage():upper();

				-- Load languages other than EN
				if (gamelang ~= "ENUS" and gamelang ~= "ENEU") then
					d303Fix.SafeLoadFile(d303Fix.Path.."Locales/"..gamelang..".lua");
				end;
				
				-- Print load info
				d303Fix.print("[|cff00ff00d303Fix |r|cffffffff"..d303Fix.Version.."|r] "..string.format(d303Fix.Strings.Init, d303Fix.date()));
			end,

		OnEvent = function(this, event, arg1)
				d303Fix.SwitchFunc(d303Fix.Events_FuncTable, event, arg1)
			end,
			
		OnUpdate = function(this, elapsedTime)
				-- Take screen shot if enabled
				if not d303Fix.ItemShop or d303Fix.timeSetFromItemShop or d303Fix.itemShopRetries < 0 then
					return;
				end
				
				d303Fix.itemShopTimer = d303Fix.itemShopTimer + elapsedTime;
				
				if d303Fix.itemShopTimer > 2 then
					d303Fix.itemShopTimer = 0
					d303Fix.timeSetFromItemShop = d303Fix.SetClockFromItemShop()
					d303Fix.itemShopTimer = 0
					d303Fix.itemShopRetries = d303Fix.itemShopRetries - 1;
					
					-- Take a screen shot on last retry (if enabled)
					if d303Fix.itemShopRetries < 0 and d303Fix.ScreenShot and d303Fix.ScreenShotOnFail then
						TakeScreenshot()
					end
				end
			end,
			
		SetClockFromSystemEvent = function(msg)
				local b, e = string.find(string.lower(msg), ".bmp")
				d303Fix.print(d303Fix.Strings.Header..d303Fix.Strings.ScreenShot.Attempt);
				d303Fix.SetTime(string.sub(msg, b - 15, b - 1));
				d303Fix.print(d303Fix.Strings.Header..string.format(d303Fix.Strings.ScreenShot.Success, d303Fix.date()));
			end,
			
		SetClockFromItemShop = function()
				d303Fix.print(d303Fix.Strings.Header..d303Fix.Strings.ItemShop.Attempt);
				-- Select diamond shop promo offers (2nd button)
				CIMF_SelectType(2)

				-- Loop Filter infos
				local filter = 1
				local success = false
				local id, name, count, s1, s2, s3, e = CIMF_GetFilterInfo(filter);
				while id > 0 and not success do
					--d303Fix.print(id.." "..name.." "..count.." "..s1.." "..s2.." "..s3.." "..e);
					filter = filter + 1

					-- Select found filter
					CIMF_SelectFilterIndex(id, -1)
					
					-- Select first item info
					local itemid, name, _, _, _, _, _, _, _, _, _, _, timeInfo = CIMF_GetItemInfo(0, ItemMallList1:GetID());

					 -- Find first end of line
					local st,en,split = string.find(timeInfo,"\n(.+)");
					if split then
						 -- Take string to the end of this line
						local _,_,promoEnd = string.find(split,"(.+)\n");
						 -- Take string from the end of this line
						local _,_,promoLeft = string.find(split,"\n(.+)");
						
						if promoEnd ~= nil and promoLeft ~= nil then
							--d303Fix.print(promoEnd.." "..promoLeft)
							
							local tend = {}
							local tleft = { year = 1970, month = 1, }
							st, en, tend.year, tend.month, tend.day, tend.hour, tend.min, tend.sec = string.find(promoEnd, "(%d+)/(%d+)/(%d+)%s+(%d+):(%d+):(%d+)");
							
							-- Thanks to matif from Curse for providing screen shot of minus value in promotion left time
							st ,en ,tleft.day, tleft.hour, tleft.min, tleft.sec = string.find(promoLeft, "([-]*%d+):([-]*%d+):([-]*%d+):([-]*%d+)");
							
							if not d303Fix.IsAnyNil(tend) and  not d303Fix.IsAnyNil(tleft) then
								-- Attempt only if there are no nil values
								local leftTimeValue = 0;
								if tonumber(tleft.day) < 0 or tonumber(tleft.hour) < 0 or tonumber(tleft.min) < 0 or tonumber(tleft.sec) < 0 then
									-- If one value is less than zero than whole set is a negative
									tleft.day	= math.abs(tonumber(tleft.day)) + 1
									tleft.hour	= math.abs(tonumber(tleft.hour))
									tleft.min	= math.abs(tonumber(tleft.min))
									tleft.sec	= math.abs(tonumber(tleft.sec))
									leftTimeValue = -d303Fix.time(tleft)
								else
									tleft.day = tonumber(tleft.day) + 1
									leftTimeValue = d303Fix.time(tleft)
								end;
								
								d303Fix.SetTime((d303Fix.time(tend) - leftTimeValue) + d303Fix.ItemShopOffset * d303Fix.secondsRepresentation.hour);
								d303Fix.print(d303Fix.Strings.Header..string.format(d303Fix.Strings.ItemShop.Success, d303Fix.date(), d303Fix.ItemShopOffset, name));
								success = true;
							end
						end
					end
					
					-- Select next filter
					id, name, count, s1, s2, s3, e = CIMF_GetFilterInfo(filter);
				end
				
				if not success then
					d303Fix.print(d303Fix.Strings.Header..string.format(d303Fix.Strings.ItemShop.Fail, tostring(d303Fix.itemShopRetries)));
				end;
				
				return success;
			end,

		SetItemShopOffset = function(h)
				d303Fix.ItemShopOffset = h
				d303Fix.print(d303Fix.Strings.Header..string.format(d303Fix.Strings.ItemShop.Offset, tostring(d303Fix.ItemShopOffset)));
			end,
		
		SetTime = function(param)
				local fn = d303Fix.conversion[type(param)] or function(param) return false end
				return fn(param)
			end,
			
		Reset = function()
				d303Fix.baseTime = 0;
				d303Fix.timeSetFromItemShop = false;
				d303Fix.itemShopRetries = 10;
				d303Fix.itemShopTimer = 0;
			end,
			
		clock = function() return math.floor(GetTime()) - d303Fix.startTime end,

		time = function(param)
				local t = {};
				if (type(param) == "table") then
					t = param;
					t.isLeap = d303Fix.IsLeapYear(t.year or 0);
				else
					-- Avoid loop date -> time -> date :D
					return d303Fix.baseTime + GetTime();
					--t = d303Fix.date("*t");
				end;
				
				-- Calculate from days, hours, minutes and seconds
				tm = tonumber(t.sec or 0) + (tonumber(t.min or 0) * d303Fix.secondsRepresentation.min) + (tonumber(t.hour or 12) * d303Fix.secondsRepresentation.hour) + (((tonumber(t.day or 1) - 1) * d303Fix.secondsRepresentation.day));
				
				-- Add Month
				m = tonumber(t.month or 1)
				while m > 1 do
					tm = tm + d303Fix.secondsInMonth[t.isLeap and m + 11 or m - 1]
					m = m - 1;
				end;
				
				-- Add year
				y = tonumber(t.year or 1970);
				while y > 1970 do
					tm = tm + d303Fix.secondsRepresentation[d303Fix.IsLeapYear(y - 1) and "lyear" or "year"];
					y = y - 1;
				end
				
				return tm;
			end,

		difftime = function(x, y) 
					return ((type(x) == "table") and d303Fix.time(x) or x) - ((type(y) == "table") and d303Fix.time(y) or y)
				end,

		date = function(fmt, param)
				local t = {};
				local tm = d303Fix.baseTime + GetTime();
				
				if param then
					-- Set time from param
					tm = (type(param) == "table") and d303Fix.time(param) or param;
					
					-- If time is from parameter than get UTC time
					if fmt and fmt:find("!") == 1 then
						-- Count UTC time, assuming that item shop time offset is time zone
						tm = tm - (d303Fix.ItemShopOffset * d303Fix.secondsRepresentation.hour);
						fmt = string.sub(fmt, 2)
					end;
				else					
					-- Get Game time if requested
					if fmt and fmt:find("!") == 1 then
						-- Few people tried to fix that, this is not an error, in RoM '!' means Game Time not UTC time
						tm = ((86400 * GetCurrentGameTime()) / 240) + 16200;
						while (tm > 86400) do
							tm = tm - 86400;
						end;
						
						fmt = string.sub(fmt, 2)
					end;
				end

				-- Set UNIX Base date
				t = {
					year	= 1970,		month	= 1,	day		= 1,
					hour	= 0,		min		= 0,	sec		= 0,
					isLeap	= false,	isdst	= true,
				}
				
				-- Calculate week day
				t.wday = 1 + (( 4 + math.floor(tm / d303Fix.secondsRepresentation.day)) % 7);
				
				-- Calculate year
				y = d303Fix.secondsRepresentation[d303Fix.IsLeapYear(t.year) and "lyear" or "year"];
				while tm >= y do 
					tm = tm - y; 
					y = d303Fix.secondsRepresentation[d303Fix.IsLeapYear(t.year) and "lyear" or "year"];
					t.year = t.year + 1;
				end
				t.isLeap = y == d303Fix.secondsRepresentation.lyear;
				
				-- Calculate day of the year
				t.yday = math.floor(tm / 86400) + 1;
				
				-- Calculate month
				while tm >= d303Fix.secondsInMonth[t.isLeap and t.month + 12 or t.month] do
					tm = tm - d303Fix.secondsInMonth[t.isLeap and t.month + 12 or t.month];
					t.month = t.month + 1;
				end
				
				-- Calculate day, hour, minute and seconds
				t.day	= math.floor(tm / d303Fix.secondsRepresentation.day) + 1;	tm = tm % d303Fix.secondsRepresentation.day;
				t.hour	= math.floor(tm / d303Fix.secondsRepresentation.hour);		tm = tm % d303Fix.secondsRepresentation.hour;
				t.min	= math.floor(tm / d303Fix.secondsRepresentation.min);		tm = tm % d303Fix.secondsRepresentation.min;
				t.sec	= math.floor(tm);
				
				if fmt and fmt == "*t" or fmt == "!*t" then
					return t;
				elseif fmt == nil then
					fmt = "%c"
				end;

				-- Apply patterns
				for key,fn in pairs(d303Fix.patterns) do 
					if fmt and fmt:find("%"..key) then
						fmt = fn(fmt, key, t)
					end
				end

				-- Fix % char
				if fmt and fmt:find("%%") then
					fmt = string.gsub(fmt, "%%", "%")
				end;
				
				-- return formatted string (splall trick for nill value)
				return (fmt == nil) and "nil" or tostring(fmt)
			end,

		exit = function() d303Fix.print(d303Fix.Strings.Header..string.format(d303Fix.Strings.NoFn, "os.exit")) end,
		execute = function(command) d303Fix.print(d303Fix.Strings.Header..string.format(d303Fix.Strings.NoFn, "os.execute")) end,
		getenv = function(varname) d303Fix.print(d303Fix.Strings.Header..string.format(d303Fix.Strings.NoFn, "os.getenv")) end,
		remove = function(filename) d303Fix.print(d303Fix.Strings.Header..string.format(d303Fix.Strings.NoFn, "os.remove")) end,
		rename = function(oldname, newname) d303Fix.print(d303Fix.Strings.Header..string.format(d303Fix.Strings.NoFn, "os.rename")) end,
		setlocale = function(locale, category) d303Fix.print(d303Fix.Strings.Header..string.format(d303Fix.Strings.NoFn, "os.setlocale")) end,
		tmpname = function() d303Fix.print(d303Fix.Strings.Header..string.format(d303Fix.Strings.NoFn, "os.tmpname")) end,
		
		--[[ Test function - for developing only
		test = function()
				-- Save od.baseTime
				local base = d303Fix.baseTime;
				
				d303Fix.print(" d303Fix Tests");
				d303Fix.print("  Game functions:");
				d303Fix.print("    GetTime() -> "..tostring(GetTime()));
				d303Fix.print("    GetCurrentGameTime() -> "..tostring(GetCurrentGameTime()));
				d303Fix.print("  d303Fix functions:");
				d303Fix.print("   Set Functions:");
				d303Fix.print("    d303Fix.SetTime(12345) -> "..tostring(d303Fix.SetTime(12345)));
				d303Fix.print("    d303Fix.SetTime({[\"year\"] = 2010, [\"month\"] = 8, [\"day\"] = 11, [\"hour\"] = 12, [\"min\"] = 1, [\"sec\"] = 1}) -> "..tostring(d303Fix.SetTime({["year"] = 2010, ["month"] = 8, ["day"] = 11, ["hour"] = 12, ["min"] = 1, ["sec"] = 1})));
				d303Fix.print("    d303Fix.SetTime(\"2010-08-11 12:30:50\") -> "..tostring(d303Fix.SetTime("2010-08-11 12:30:50")));
				d303Fix.print("   System date and time functions:");
				d303Fix.print("    d303Fix.date(\"*t\").year -> "..tostring(d303Fix.date("*t").year));
				d303Fix.print("    d303Fix.date(\"*t\").yday -> "..tostring(d303Fix.date("*t").yday));
				d303Fix.print("    d303Fix.date(\"*t\").month -> "..tostring(d303Fix.date("*t").month));
				d303Fix.print("    d303Fix.date(\"*t\").day -> "..tostring(d303Fix.date("*t").day));
				d303Fix.print("    d303Fix.date(\"*t\").hour -> "..tostring(d303Fix.date("*t").hour));
				d303Fix.print("    d303Fix.date(\"*t\").min -> "..tostring(d303Fix.date("*t").min));
				d303Fix.print("    d303Fix.date(\"*t\").sec -> "..tostring(d303Fix.date("*t").sec));
				d303Fix.print("    d303Fix.date(\"*t\").wday -> "..tostring(d303Fix.date("*t").wday));
				d303Fix.print("    d303Fix.date(\"*t\").isdst -> "..tostring(d303Fix.date("*t").isdst));
				d303Fix.print("    d303Fix.date() -> "..tostring(d303Fix.date()));
				d303Fix.print("    d303Fix.time() -> "..tostring(d303Fix.time()));
				d303Fix.print("    d303Fix.time(1) -> "..tostring(d303Fix.time(1)));
				d303Fix.print("    d303Fix.time({[\"year\"] = 2010, [\"month\"] = 8, [\"day\"] = 11, [\"hour\"] = 12, [\"min\"] = 1, [\"sec\"] = 1}) -> "..tostring(d303Fix.time({["year"] = 2010, ["month"] = 8, ["day"] = 11, ["hour"] = 12, ["min"] = 1, ["sec"] = 1})));
				d303Fix.print("    d303Fix.time({[\"year\"] = nil, [\"month\"] = nil, [\"day\"] = nil, [\"hour\"] = nil, [\"min\"] = 1, [\"sec\"] = nil}) -> "..tostring(d303Fix.time({["year"] = nil, ["month"] = nil, ["day"] = nil, ["hour"] = nil, ["min"] = 1, ["sec"] = nil})));
				d303Fix.print("    d303Fix.clock() -> "..tostring(d303Fix.clock()));
				d303Fix.print("   Game date and time functions:");
				d303Fix.print("    d303Fix.date(\"!*t\").year -> "..tostring(d303Fix.date("!*t").year));
				d303Fix.print("    d303Fix.date(\"!*t\").yday -> "..tostring(d303Fix.date("!*t").yday));
				d303Fix.print("    d303Fix.date(\"!*t\").month -> "..tostring(d303Fix.date("!*t").month));
				d303Fix.print("    d303Fix.date(\"!*t\").day -> "..tostring(d303Fix.date("!*t").day));
				d303Fix.print("    d303Fix.date(\"!*t\").hour -> "..tostring(d303Fix.date("!*t").hour));
				d303Fix.print("    d303Fix.date(\"!*t\").min -> "..tostring(d303Fix.date("!*t").min));
				d303Fix.print("    d303Fix.date(\"!*t\").sec -> "..tostring(d303Fix.date("!*t").sec));
				d303Fix.print("    d303Fix.date(\"!*t\").wday -> "..tostring(d303Fix.date("!*t").wday));
				d303Fix.print("    d303Fix.date(\"!*t\").isdst -> "..tostring(d303Fix.date("!*t").isdst));
				--
				d303Fix.print("   System date and time d303Fix.date() formatting:");
				for key,value in pairs(d303Fix.patterns) do 
					d303Fix.print("    d303Fix.date(\""..key.."\") -> "..tostring(d303Fix.date(key)));
				end
				d303Fix.print("   Game date and time d303Fix.date() formatting:");
				for key,value in pairs(d303Fix.patterns) do 
					d303Fix.print("    d303Fix.date(\"!"..key.."\") -> "..tostring(d303Fix.date("!"..key)));
				end
				
				d303Fix.print("   Not implemented functions:");
				d303Fix.exit()
				d303Fix.execute()
				d303Fix.getenv()
				d303Fix.remove(filename)
				d303Fix.rename(oldname, newname)
				d303Fix.setlocale(locale, category)
				d303Fix.tmpname()
				
				d303Fix.print(d303Fix.date())
				d303Fix.SetTime(d303Fix.time(d303Fix.date("*t")))
				d303Fix.print(d303Fix.date())
				d303Fix.SetTime(d303Fix.time(d303Fix.date("*t")))
				d303Fix.print(d303Fix.date())
				d303Fix.SetTime(d303Fix.time(d303Fix.date("*t")))
				d303Fix.print(d303Fix.date())
				
				d303Fix.print("    d303Fix.date(\"!%c\") -> "..tostring(d303Fix.date("!%c")));
				d303Fix.print("    d303Fix.date(\"!%c\", os.time()) -> "..tostring(d303Fix.date("!%c", os.time())));
				d303Fix.print("    d303Fix.date(\"%c\", os.time()) -> "..tostring(d303Fix.date("%c", os.time())));
				
				-- Restore d303Fix.baseTime
				d303Fix.baseTime = base;
			end,
		]]
	}
end

-- Display override info
if os and os.print and d303Fix then
	d303Fix.print(d303Fix.Strings.Header..d303Fix.Strings.OsRedeclared);
end

-- Override os object
if not os or (os and os.print and d303Fix) then
	os = {}
	for _,v in ipairs(d303Fix.osFunctionsNames) do
		os[v] = d303Fix[v]
	end
end
