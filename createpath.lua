include("database.lua");
include("addresses.lua");
include("classes/player.lua");
include("classes/camera.lua");
include("classes/waypoint.lua");
include("classes/waypointlist.lua");
include("classes/waypointlist_wander.lua");
include("classes/node.lua");
include("settings.lua");
include("functions.lua");
include("macros.lua");
include("classes/object.lua");
include("classes/memorytable.lua");

settings.load();
database.load();

-- ********************************************************************
-- Change the parameters below to your need                           *
-- ********************************************************************
-- if you want to create waypoint files with special waypoint types
-- like type=TRAVEL, than you can change the global variables
-- below to your need, see the following example
-- p_wp_gtype = " type=\"TRAVEL\"";	-- global type for whole file
-- p_wp_type = " type=\"TRAVEL\"";	-- type for normal waypoints
-- p_hp_type = " type=\"TRAVEL\"";	-- type for harvest waypoints
p_wp_gtype = "";	-- global type for whole file: e.g. TRAVEL
p_wp_type = "";		-- type for normal waypoints
p_hp_type = "";		-- type for harvest waypoints
p_harvest_command = "\n\t\t\tplayer:harvest()\n";
p_merchant_command = "player:merchant%s";
p_targetNPC_command = "player:target_NPC%s";
p_targetObj_command = "player:target_Object%s";
--p_choiceOption_command = "sendMacro(\"ChoiceOption(%d)\")";
p_mouseClickL_command = "player:mouseclickL(%d, %d, %d, %d)";
p_wpType_command = "__WPL:setForcedWaypointType(\"%s\")";
p_acceptbyname_command = "AcceptQuestByName%s";
p_completebyname_command = "CompleteQuestByName%s";
p_choicebyname_command = "ChoiceOptionByName%s";
-- ********************************************************************
-- End of Change parameter changes                                    *
-- ********************************************************************


setStartKey(settings.hotkeys.START_BOT.key);
setStopKey(settings.hotkeys.STOP_BOT.key);

wpKey = key.VK_NUMPAD1;				-- insert a movement point
harvKey = key.VK_NUMPAD2;			-- insert a harvest point
saveKey = key.VK_NUMPAD3;			-- save the waypoints
merchantKey = key.VK_NUMPAD4;		-- target merchant, repair and buy stuff
targetNPCKey = key.VK_NUMPAD5;		-- target NPC and open dialog waypoint
--choiceOptionKey = key.VK_NUMPAD6; 	-- insert choiceOption
byName = key.VK_NUMPAD6;			-- Insert Accept/Complete/ChoiceOption 'ByName' selection.
mouseClickKey = key.VK_NUMPAD7;	 	-- Save MouseClick
restartKey = key.VK_NUMPAD9;		-- restart waypoints script
resetKey = key.VK_NUMPAD8;			-- restart waypoints script and discard changes
codeKey = key.VK_NUMPAD0;			-- add comment to last WP.
targetObjKey = key.VK_DECIMAL;		-- target an object and action it.
wpTypeKey = key.VK_DIVIDE;			-- change waypoint type
flyToggle = key.VK_ADD				-- Toggles fly and optionally inserts fly command

-- read arguments / forced profile perhaps
local forcedProfile = nil;
for i = 2,#args do

	local foundpos = string.find(args[i], ":", 1, true);
	if( foundpos ) then
		local var = string.sub(args[i], 1, foundpos-1);
		local val = string.sub(args[i], foundpos+1);

		if( var == "profile" ) then
			forcedProfile = val;
		else
			-- invalid option
			local msg = sprintf(language[61], args[i]);
			error(msg, 0 );
		end
	end

	-- check the options
	if(not foundpos  and  args[i] ~= "update" ) then
		local msg = sprintf(language[61], args[i]);
		error(msg, 0 );
	end;

end

local wpList = {};

local playerPtr = memoryReadUIntPtr(getProc(), addresses.staticbase_char, addresses.charPtr_offset);
player = CPlayer(playerPtr);
player:update();

-- convert player name to profile name and check if profile exist
local load_profile_name;	-- name of profile to load
if( forcedProfile ) then
	load_profile_name = convertProfileName(forcedProfile);
else
	load_profile_name = convertProfileName(player.Name);
end

attach(getWin());
settings.loadProfile(load_profile_name);

-- In game message to get users attention
local function message(text,level)
	if level == "warning" then -- Red text, beep. When nothing was done.
		printf("\a")
		addMessage("|cffff4500"..text)
	elseif level == "question" then -- Orange text. Awating user input.
		addMessage("|cffff9900"..text)
	else							-- Default message.
		addMessage(text)
	end
end

-- Activate MM console to get users input
local function activateConsole()
	local startWidth, startHeight = getConsoleAttributes() -- Remember size becaue of size change bug
	showWindow(getHwnd(), sw.minimize) yrest(500) -- minimize first or else restore wonn't work bug.
	showWindow(getHwnd(), sw.restore) yrest(1000) -- Restore and activate console

	-- Restore size if changed
	local curX, curY = getConsoleAttributes()
	if curY ~= startHeight then -- size changed, restore
		setConsoleAttributes(startWidth, startHeight)
	end
end

-- Gets the text, type and index of the dialog choice the user selected.
local function getChoice(num)
	local text, typ, index = RoMCode("n="..num.." c=0 for k,v in pairs(g_SpeakFrameData.option) do if v.objtype~=1 then c=c+1 if c==n then a={v.title,v.type,v.id} break end end end")
	-- Fix title
	if text ~= nil then
		text = string.gsub(text,"|c%x*","") -- Remove color info
		text = string.gsub(text,"%[.*%]","") -- Remove added info in square brackets
		text = string.gsub(text,"%(.*%)","") -- Remove added info in normal brackets
		local acceptQuest = getTEXT("SYS_ACCEPT_QUEST")
		if string.find(string.lower(text),string.lower(acceptQuest)) then
			text = string.sub(text,#acceptQuest+2) -- Remove "Accept quest: "
		end
		text = trim(text) -- Trim leading and trailing spaces
	end

	return text, typ, index
end

-- Returns table of quest ids in the questlog.
local function scanQuestIds()
	return {RoMCode("for i=1,GetNumQuestBookButton_QuestBook() do table.insert(a,GetQuestId(i)) end")}
end

-- Compares 2 tables of ids and returns the changed id.
local function findId(tablewithid, tablewithoutid)
	for ka, va in pairs(tablewithid) do
		local foundflag = false;
		for kb, vb in pairs(tablewithoutid) do
			if vb == va then
				foundflag = true;
				break
			end
		end
		if foundflag == false then
			return va
		end
	end
end

-- Saves the completed waypoint file
local function saveWaypoints(list)
	local file
    while (not file) do
		activateConsole()
		-- Get input
		keyboardBufferClear();
		io.stdin:flush();
		cprintf(cli.green, language[500]);	-- What do you want to name your path
		tempname = io.stdin:read()

		if tempname ~= "" and tempname ~= nil then
			filename = getExecutionPath() .. "/waypoints/" .. tempname  .. ".xml";
		else
			filename = getExecutionPath() .. "/waypoints/__unnamed.xml";
		end
		filechk, err = io.open(filename, "r");
		if (filechk) then
			cprintf(cli.yellow, language[525]); -- Filename already exists! Overwrite? [Y/N]
			overwrite = io.stdin:read()
			filechk:close();
		end
		if (not filechk) or string.lower(overwrite) == "y" then
			file, err = io.open(filename, "w");
			if( not file ) then
				cprintf(cli.green, language[524]); -- File save failed. Please verify the name and try again.
			end
		end
	end

	local openformat = "\t<!-- #%3d --><waypoint x=\"%d\" z=\"%d\" y=\"%d\"%s>%s";
	local closeformat = "\t</waypoint>\n";

	file:write("<?xml version=\"1.0\" encoding=\"utf-8\"?>");
	local str = sprintf("<waypoints%s>\n", p_wp_gtype);	-- create first tag
	file:write(str);					-- write first tag

	local hf_line, tag_open, line_num, hf_data = "", false, 1, false;
	for i,v in pairs(list) do
		if( v.wp_type == "WP" ) then -- Waypoint
			if( tag_open ) then
				if ( hf_data ) then
					hf_line = hf_line .. "\n" .. closeformat
				else
					hf_line = hf_line .. closeformat
				end
			end
			hf_line = hf_line .. sprintf(openformat, line_num, v.X, v.Z, v.Y, p_wp_type, "")
			line_num = line_num + 1
			tag_open = true;
			hf_data = false;
		elseif( v.wp_type == "HP" ) then -- Harvest point
			if( tag_open ) then
				if ( hf_data ) then
					hf_line = hf_line .. "\n" .. closeformat
				else
					hf_line = hf_line .. closeformat
				end
			end
			hf_line = hf_line .. sprintf(openformat, line_num, v.X, v.Z, v.Y, p_hp_type, p_harvest_command) .. closeformat;
			line_num = line_num + 1
			tag_open = false;
			hf_data = false;
		elseif( v.wp_type == "MER" ) then -- Merchant
			hf_data = true;
			if( tag_open ) then
				hf_line = hf_line .. "\n\t\t\t" .. sprintf(p_merchant_command, v.npc_name)
			else
				hf_line = hf_line .. sprintf(openformat, line_num, v.X, v.Z, v.Y, p_wp_type, "") .. "\n";
				hf_line = hf_line .. "\t\t\t" .. sprintf(p_merchant_command, v.npc_name)
				line_num = line_num + 1
				tag_open = true;
			end
		elseif( v.wp_type == "NPC" ) then -- Open NPC Dialog
			hf_data = true;
			if( tag_open ) then
				hf_line = hf_line .. "\n\t\t\t" .. sprintf(p_targetNPC_command, v.npc_name)
			else
				hf_line = hf_line .. sprintf(openformat, line_num, v.X, v.Z, v.Y, p_wp_type, "") .. "\n";
				hf_line = hf_line .. "\t\t\t" .. sprintf(p_targetNPC_command, v.npc_name)
				line_num = line_num + 1
				tag_open = true;
			end
		elseif( v.wp_type == "MC" ) then -- Mouse click (left)
			hf_data = true;
			if( tag_open ) then
				hf_line = hf_line .. "\n\t\t\t" .. sprintf(p_mouseClickL_command, v.mx, v.my, v.wide, v.high)
			else
				hf_line = hf_line .. sprintf(openformat, line_num, v.X, v.Z, v.Y, p_wp_type, "") .. "\n";
				hf_line = hf_line .. "\t\t\t" .. sprintf(p_mouseClickL_command, v.mx, v.my, v.wide, v.high)
				line_num = line_num + 1
				tag_open = true;
			end
		elseif( v.wp_type == "COD" ) then -- Code
			hf_data = true;
			if( tag_open ) then
				hf_line = hf_line .. "\n\t\t\t" .. v.com
			else
				hf_line = hf_line .. sprintf(openformat, line_num, v.X, v.Z, v.Y, p_wp_type, "") .. "\n";
				hf_line = hf_line .. "\t\t\t" .. v.com
				line_num = line_num + 1
				tag_open = true;
			end
		elseif( v.wp_type == "OBJ" ) then -- Target Object
			hf_data = true;
			if( tag_open ) then
				hf_line = hf_line .. "\n\t\t\t" .. sprintf(p_targetObj_command, v.obj_name)
			else
				hf_line = hf_line .. sprintf(openformat, line_num, v.X, v.Z, v.Y, p_wp_type, "") .. "\n";
				hf_line = hf_line .. "\t\t\t" .. sprintf(p_targetObj_command, v.obj_name)
				line_num = line_num + 1
				tag_open = true;
			end
		elseif( v.wp_type == "WPT" ) then -- Change Waypoint movement mode
			hf_data = true;
			if( tag_open ) then
				hf_line = hf_line .. "\n\t\t\t" .. sprintf(p_wpType_command, v.wp_move)
			else
				hf_line = hf_line .. sprintf(openformat, line_num, v.X, v.Z, v.Y, p_wp_type, "") .. "\n";
				hf_line = hf_line .. "\t\t\t" .. sprintf(p_wpType_command, v.wp_move)
				line_num = line_num + 1
				tag_open = true;
			end
		elseif( v.wp_type == "ACCEPT" ) then -- Accept quest
			hf_data = true;
			local tmptext
			if v.id then
				tmptext = sprintf("(%d) -- %s", v.id, v.name)
			else
				tmptext = sprintf("(\"%s\")", v.name)
			end
			if( tag_open ) then
				hf_line = hf_line .. "\n\t\t\t" .. sprintf(p_acceptbyname_command, tmptext)
			else
				hf_line = hf_line .. sprintf(openformat, line_num, v.X, v.Z, v.Y, p_wp_type, "") .. "\n";
				hf_line = hf_line .. "\t\t\t" .. sprintf(p_acceptbyname_command, tmptext)
				line_num = line_num + 1
				tag_open = true;
			end
		elseif( v.wp_type == "COMPLETE" ) then -- Complete quest
			hf_data = true;
			local tmprewtext = ""
			if v.rewnum then
				tmprewtext = sprintf(", %d", v.rewnum)
			end
			local tmptext
			if v.id then
				tmptext = sprintf("(%d%s) -- %s", v.id, tmprewtext, v.name)
			else
				tmptext = sprintf("(\"%s\"%s)", v.name, tmprewtext)
			end
			if v.rewards then
				tmptext = tmptext .. "\n\t\t\t-- Rewards: "
				for k,v in ipairs (v.rewards) do
					local rewardId = getKeyStrings(v,true)
					if rewardId then rewardId = (rewardId:match("%d%d%d%d%d%d") or 0) end
					tmptext = tmptext .. sprintf("[%d] %s (%s), ", k, v, rewardId)
				end
			end
			if( tag_open ) then
				hf_line = hf_line .. "\n\t\t\t" .. sprintf(p_completebyname_command, tmptext)
			else
				hf_line = hf_line .. sprintf(openformat, line_num, v.X, v.Z, v.Y, p_wp_type, "") .. "\n";
				hf_line = hf_line .. "\t\t\t" .. sprintf(p_completebyname_command, tmptext)
				line_num = line_num + 1
				tag_open = true;
			end
		elseif( v.wp_type == "COBYNAME" ) then -- Choose option by name
			hf_data = true;
			local tmptext
			if v.keystring == nil or v.text == v.keystring then
				tmptext = sprintf("(\"%s\")", v.text)
			else
				tmptext = sprintf("(getTEXT(\"%s\")) -- \'%s\'", v.keystring, v.text)
			end
			if( tag_open ) then
				hf_line = hf_line .. "\n\t\t\t" .. sprintf(p_choicebyname_command, tmptext)
			else
				hf_line = hf_line .. sprintf(openformat, line_num, v.X, v.Z, v.Y, p_wp_type, "") .. "\n";
				hf_line = hf_line .. "\t\t\t" .. sprintf(p_choicebyname_command, tmptext)
				line_num = line_num + 1
				tag_open = true;
			end
		elseif( v.wp_type == "FLY" ) then -- Toggle flying and optionally insert command
			hf_data = true;
			local tmptext = sprintf("(\"%s\")", v.text)
			if( tag_open ) then
				hf_line = hf_line .. "\n\t\t\t" .. sprintf(p_choicebyname_command, tmptext)
			else
				hf_line = hf_line .. sprintf(openformat, line_num, v.X, v.Z, v.Y, p_wp_type, "") .. "\n";
				hf_line = hf_line .. "\t\t\t" .. sprintf(p_choicebyname_command, tmptext)
				line_num = line_num + 1
				tag_open = true;
			end
		end
	end

   -- If we left a tag open, close it.
	if( tag_open ) then
		if ( hf_data ) then
			hf_line = hf_line .. "\n" .. closeformat
		else
			hf_line = hf_line .. closeformat
		end
	end

	if( bot.ClientLanguage == "RU" ) then
		hf_line = oem2utf8_russian(hf_line);		-- language conversations for Russian Client
	end

	file:write(hf_line);
	file:write("</waypoints>");

	file:close();

	wpList = {};	-- clear intenal table

end

-- Get input from the user, either a single character or a string.
local function getInput(single, prompt)
	if single then -- Get single character
		cprintf(cli.green, prompt);
		message(prompt, "question");
		-- Wait till previous key is no longer pressed
		repeat
			local ks = keyboardState()
			local stillpressed
			for k,v in pairs(ks) do
				if v and k~=255 then stillpressed = true end
			end
			yrest(50)
		until not stillpressed

		-- Wait till new key is pressed
		local pressed
		local lastState = keyboardState()
		repeat
			local ks = keyboardState()
			if foregroundWindow() == getWin() or foregroundWindow() == getHwnd() then
				for k,v in pairs(ks) do
					if v and not (lastState[k]) then
						-- Check if alpha numeric
						if (k >= key.VK_A and k <= key.VK_Z) or
						   (k >= key.VK_0 and k <= key.VK_9) then
						   pressed = k
						elseif (k >= key.VK_NUMPAD0 and k <= key.VK_NUMPAD9) then
							pressed = k - 48
						end
					end
				end
			end
			lastState = ks
			yrest(50)
		until pressed

		-- Wait until that key stops being pressed
		repeat
			yrest(50)
		until not keyPressed(pressed)

		printf("\n")

		-- Return pressed character
		return string.char(pressed)
	else
		-- Restore console for input
		activateConsole()

		-- Print prompt
		cprintf(cli.green, prompt);

		-- Get input
		keyboardBufferClear();
		io.stdin:flush();
		local input = io.stdin:read();
		yrest(500)

		-- Restore game
		showWindow(getWin(), sw.restore) yrest(500)

		-- Return input
		return input
	end
end

-- The main function
function main()

	local playerAddress
	local playerId
	local playerHP
	local playerX = 0
	local playerZ = 0
	local playerY = 0
	local running = true;

	local lastTime = getTime();
	while(running) do

		local hf_x, hf_y, hf_wide, hf_high = windowRect( getWin());
		cprintf(cli.turquoise, language[42], hf_wide, hf_high, hf_x, hf_y );	-- RoM windows size
		cprintf(cli.green, language[501]);	-- RoM waypoint creator\n
		printf(language[502]			-- Insert new waypoint
			.. language[503]		-- Insert new harvest waypoint
			.. language[505]		-- Save waypoints and quit
			.. language[509]		-- Insert merchant command
			.. language[504]		-- Insert target/dialog NPC command
--			.. language[517]		-- Insert choiceOption command
			.. language[530]		-- Intert dialog 'ByName' selection.
			.. language[510]		-- Insert Mouseclick Left command
			.. language[518]		-- Reset script
			.. language[506]		-- Save waypoints and restart
			.. language[519]		-- Insert comment command
			.. language[522]		-- Insert target object command
			.. language[526]		-- Change Waypoint Type
			.. language[537],		-- Toggle flying
			getKeyName(wpKey), getKeyName(harvKey), getKeyName(saveKey),
			getKeyName(merchantKey), getKeyName(targetNPCKey),
			getKeyName(byName), getKeyName(mouseClickKey),
			getKeyName(resetKey), getKeyName(restartKey),
			getKeyName(codeKey), getKeyName(targetObjKey),
			getKeyName(wpTypeKey), getKeyName(flyToggle));

		attach(getWin())
		message(language[501]);	-- RoM waypoint creator\n

		local hf_key_pressed, hf_key;
		while(true) do

			hf_key_pressed = false;

			if( keyPressedLocal(wpKey) ) then	-- normal waypoint key pressed
				hf_key_pressed = true;
				hf_key = "WP";
			end;
			if( keyPressedLocal(harvKey) ) then	-- harvest waypoint key pressed
				hf_key_pressed = true;
				hf_key = "HP";
			end;
			if( keyPressedLocal(saveKey) ) then	-- save key pressed
				hf_key_pressed = true;
				hf_key = "SAVE";
			end;
			if( keyPressedLocal(merchantKey ) ) then	-- merchant NPC key pressed
				hf_key_pressed = true;
				hf_key = "MER";
			end;
			if( keyPressedLocal(targetNPCKey) ) then	-- target NPC key pressed
				hf_key_pressed = true;
				hf_key = "NPC";
			end;
			if( keyPressedLocal(byName) ) then		-- byname key pressed
				hf_key_pressed = true;
				hf_key = "BYNAME";
			end;
			if( keyPressedLocal(codeKey) ) then	-- choice option key pressed
				hf_key_pressed = true;
				hf_key = "COD";
			end;
			if( keyPressedLocal(mouseClickKey) ) then	-- target MouseClick key pressed
				hf_key_pressed = true;
				hf_key = "MC";
			end;
			if( keyPressedLocal(restartKey) ) then	-- restart key pressed
				hf_key_pressed = true;
				hf_key = "RESTART";
			end;
			if( keyPressedLocal(resetKey) ) then	-- reset key pressed
				hf_key_pressed = true;
				hf_key = "RESET";
			end;
			if( keyPressedLocal(targetObjKey) ) then	-- target object key pressed
				hf_key_pressed = true;
				hf_key = "OBJ";
			end;
			if( keyPressedLocal(wpTypeKey) ) then		-- waypoint type key pressed
				hf_key_pressed = true;
				hf_key = "WPT";
			end;
			if( keyPressedLocal(flyToggle) ) then		-- byname key pressed
				hf_key_pressed = true;
				hf_key = "FLY";
			end;

			if( hf_key_pressed == false and 	-- key released, do the work
				hf_key ) then					-- and key not empty

				-- SAVE Key: save waypoint file and exit
				if( hf_key == "SAVE" ) then
					saveWaypoints(wpList);
					hf_key = " ";	-- clear last pressed key
					running = false;
					break;
				end;

				if( hf_key == "RESET" ) then
					clearScreen();
					wpList = {}; -- DON'T save clear table
					hf_key = " ";	-- clear last pressed key
					running = true; -- restart
					break;
				end;

				player.Address = memoryReadRepeat("uintptr", getProc(), addresses.staticbase_char, addresses.charPtr_offset) or 0;
				player:updateXYZ();

				local tmp = {}, hf_type;
				tmp.X = player.X;
				tmp.Z = player.Z;
				tmp.Y = player.Y;
				hf_type = "";


				local prefix = sprintf(language[511], #wpList+1) -- %d Waypoint Added.
				-- waypoint or harvest point key: create a waypoint/harvest waypoint
				if( hf_key == "HP" ) then			-- harvest waypoint
					tmp.wp_type = "HP";
					hf_type = "HP";
					message(sprintf(language[512], #wpList+1) ); -- harvestpoint added
				elseif(	hf_key == "WP") then			-- normal waypoint
					tmp.wp_type = "WP";
					hf_type = "WP";
					message(prefix ); -- waypoint added
				elseif( hf_key == "MER" ) then -- merchant command
					tmp.wp_type = "MER";
					local target = player:getTarget();	-- get target name
					tmp.npc_name = "("..target.Id..") -- "..target.Name;
					hf_type = "target/merchant NPC "..target.Name;
					message(prefix..sprintf(language[513], target.Name));
				elseif( hf_key == "NPC" ) then -- target npc
					tmp.wp_type = "NPC";
					local target = player:getTarget();	-- get target name
					tmp.npc_name = "("..target.Id..") -- "..target.Name;
					hf_type = "target/dialog NPC "..target.Name;
					message(prefix..sprintf(language[514], target.Name));
				elseif( hf_key == "COD") then			-- enter code
					tmp.wp_type = "COD";
					tmp.com = getInput(nil, language[520]);	-- add code
					hf_type = tmp.com;
					message(prefix..sprintf(language[521], tmp.com or "nil" ) ); -- code
				elseif( hf_key == "MC" ) then 	-- is's a mouseclick?
					tmp.wp_type = "MC";			-- it is a mouseclick
					local x, y = mouseGetPos();
					local wx, wy, hf_wide, hf_high = windowRect(getWin());
					tmp.wide = hf_wide;
					tmp.high = hf_high;
			        tmp.mx = x - wx;
					tmp.my = y - wy;
					hf_type = sprintf("mouseclick at %d,%d (%dx%d)", tmp.mx, tmp.my, tmp.wide, tmp.high );
					message(prefix..sprintf(language[515],
					tmp.mx, tmp.my, tmp.wide, tmp.high )); -- Mouseclick
				elseif( hf_key == "OBJ" ) then 	-- target object
					tmp.wp_type = "OBJ";
					local mouseObj = CObject(memoryReadUIntPtr(getProc(), addresses.staticbase_char, addresses.mousePtr_offset));
					tmp.obj_name = "("..mouseObj.Id..") -- "..mouseObj.Name
					hf_type = sprintf("target object \'%s\'", mouseObj.Name );
					message(prefix..sprintf(language[523],mouseObj.Name)); -- target object
				elseif( hf_key == "WPT") then			-- change waypoint type
					tmp.wp_type = "WPT";
					tmp.com = getInput(true, language[527]);	-- Change to (T)ravel, (R)un, or (N)ormal
					if tmp.com == "1" or tmp.com == "2" or tmp.com == "3" then
						tmp.wp_type = nil -- Doesn't need to save waypoint
						local tmp_type
						if tmp.com == "1" then
							tmp_type = "TRAVEL"
						elseif tmp.com == "2" then
							tmp_type = "RUN"
						elseif tmp.com == "3" then
							tmp_type = "NORMAL"
						end
						if tmp_type ~= "NORMAL" then
							p_wp_gtype = " type=\""..tmp_type.."\""
						else
							p_wp_gtype = ""
						end
						hf_type = sprintf("File waypoint type set to \'%s\'", tmp_type);
						message(sprintf(language[529], tmp_type ) ); -- Whole file Waypoint Type changed to
					else
						if tmp.com == "4" then
							tmp.wp_move = "TRAVEL"
						elseif tmp.com == "5" then
							tmp.wp_move = "RUN"
						elseif tmp.com == "6" then
							tmp.wp_move = "NORMAL"
						else
							tmp.wp_move = "NORMAL"
						end
						hf_type = sprintf("Single waypoint type set to \'%s\'", tmp.wp_move );
						message(prefix..sprintf(language[528], tmp.wp_move ) );
					end
				elseif( hf_key == "BYNAME") then
					local dialogOpen = RoMScript("SpeakFrame:IsVisible()")
					if not dialogOpen then
						hf_type = language[531] -- Please open the npc dialog before using this option.
						message(language[531], "warning" );
						tmp.wp_type = nil -- Doesn't need to save waypoint
					else
						tmp.com = getInput(true, language[507]);	-- Choose option
						local name, typ, index = getChoice(tmp.com)
						if( bot.ClientLanguage == "RU" ) then
							name=utf82oem_russian(name) -- language conversations for Russian Client
						end
						if name == nil then
							tmp.wp_type = nil
							hf_type = "<Invalid Option>"
							message("<Invalid Option>", "warning");
						elseif typ == 1 then
							tmp.wp_type = "ACCEPT"
							local questIdsBefore = scanQuestIds()
							if index ~= nil then
								RoMCode("OnClick_QuestListButton(1,"..index..")") -- Clicks the quest
							end
							RoMCode("AcceptQuest()") yrest(1000) -- Accepts the quest
							RoMCode("SpeakFrame:Hide()") -- Close dialog.
							local questIdsAfter = scanQuestIds()
							tmp.id = findId(questIdsAfter, questIdsBefore)
							if tmp.id then
								tmp.name = GetIdName(tmp.id)
							else
								tmp.name = name
							end
							hf_type = sprintf("Accept Quest '%s'", tmp.name)
							message(prefix..sprintf(language[534], tmp.name) ); -- AcceptQuestName
						elseif typ == 2 then
							hf_type = language[533]
							message(hf_type, "warning")
							tmp.wp_type = nil
						elseif typ == 3 then
							tmp.wp_type = "COMPLETE"
							local questIdsBefore = scanQuestIds()
							if index ~= nil then
								RoMCode("OnClick_QuestListButton(3,"..index..")") -- Clicks the quest
							end
							-- Check for rewards
							local rewardCount = RoMScript("GetQuestItemNumByType_QuestDetail(2)")
							if rewardCount > 0 then
								tmp.rewards = {}
								local tmptext = ""
								for i = 1, rewardCount do
									tmp.rewards[i] = RoMScript("GetQuestItemInfo_QuestDetail( 2,"..i..")")
									tmptext = tmptext .. sprintf(", (%d) %s",i , tmp.rewards[i])
								end
								tmp.rewnum = getInput(true, sprintf(language[538],tmptext));	-- Select reward
								if tonumber(tmp.rewnum) then
									RoMCode("SpeakFrame_ClickQuestReward(SpeakQuestReward1_Item"..tmp.rewnum..")")
								end
							end

							RoMCode("CompleteQuest()") yrest(1000) -- Completes the quest
							RoMCode("SpeakFrame:Hide()") -- Close dialog.
							local questIdsAfter = scanQuestIds()
							tmp.id = findId(questIdsBefore, questIdsAfter)
							if tmp.id then
								tmp.name = GetIdName(tmp.id)
							else
								tmp.name = name
							end
							hf_type = sprintf("Complete Quest '%s'", tmp.name)
							message(prefix..sprintf(language[535], tmp.name) ); -- CompleteQuestName
						else
							tmp.wp_type = "COBYNAME"
							name = string.match(name,"^[> ]*(.-)[< ]*$") -- Filter >> and << added by addons.
							tmp.text = name
							hf_type = sprintf("ChoiceOptionByName \'%s\'",name)
							message(prefix..sprintf(language[516], "\'"..name.."\'" ) ); -- ChoiceOptionByName
							tmp.keystring = getKeyStrings(name, true)--, "SC_", "SP")
							ChoiceOptionByName(name)
						end
					end
				elseif( hf_key == "FLY") then
					-- Toggle flying
					local offsets = {addresses.charPtr_offset, addresses.pawnSwim_offset1, addresses.pawnSwim_offset2}
					local active = 4
					local flying = (memoryReadIntPtr(getProc(), addresses.staticbase_char, offsets) == active)
					if flying then
						tmp.com = "flyoff()"
						memoryWriteString(getProc(), addresses.swimAddress, string.char(unpack(addresses.swimAddressBytes)));
					else
						tmp.com = "fly()"
						memoryWriteString(getProc(), addresses.swimAddress, string.rep(string.char(0x90),#addresses.swimAddressBytes));
						memoryWriteIntPtr(getProc(), addresses.staticbase_char, offsets, active);
					end

					-- Ask user if they want to insert command
					local answer = getInput(true, sprintf(language[536],tmp.com));	-- add fly
					if answer == "1" then
						tmp.wp_type = "COD";
						hf_type = tmp.com
						message(prefix..sprintf(language[521], hf_type) ); -- code
					else
						tmp.wp_type = nil -- Doesn't need to save waypoint
						if flying then
							hf_type = "No longer flying."
						else
							hf_type = "Now flying."
						end
					end
				end


				local coords = ""
				if hf_type == "WP" or hf_type == "HP" then
					coords = sprintf(", (%d, %d, %d)", tmp.X, tmp.Z, tmp.Y)
				end
				printf(language[508],	-- (X, Z, Y), Press %s to save and quit
					#wpList+1, (hf_type..coords), getKeyName(saveKey));

				if tmp.wp_type ~= nil then -- In case of invalid command
					table.insert(wpList, tmp);
				end

				if( hf_key == "RESTART" ) then
					saveWaypoints(wpList);
					hf_key = " ";	-- clear last pressed key
					running = true; -- restart
					break;
				end;


				hf_key = nil;	-- clear last pressed key
			end;

			-- To reduce cpu usage, do memory reads every 500ms.
			if deltaTime(getTime(), lastTime) > 500 then
				playerAddress = memoryReadUIntPtr(getProc(), addresses.staticbase_char, addresses.charPtr_offset);
				playerId = memoryReadInt(getProc(), playerAddress + addresses.pawnId_offset) or 0
				playerHP = memoryReadInt(getProc(), playerAddress + addresses.pawnHP_offset) or 0
				if not isInGame() or playerId < PLAYERID_MIN or playerId > PLAYERID_MAX or playerHP < 1 then
					repeat
						yrest(1000)
						playerAddress = memoryReadUIntPtr(getProc(), addresses.staticbase_char, addresses.charPtr_offset);
						playerId = memoryReadInt(getProc(), playerAddress + addresses.pawnId_offset) or 0
						playerHP = memoryReadInt(getProc(), playerAddress + addresses.pawnHP_offset) or 0
					until isInGame() and playerId >= PLAYERID_MIN and playerId <= PLAYERID_MAX and playerHP > 1
				end
				playerX = memoryReadFloat(getProc(), playerAddress + addresses.pawnX_offset) or playerX
				playerY = memoryReadFloat(getProc(), playerAddress + addresses.pawnY_offset) or playerY
				playerZ = memoryReadFloat(getProc(), playerAddress + addresses.pawnZ_offset) or playerZ
				mousePawnAddress = memoryReadUIntPtr(getProc(), addresses.staticbase_char, addresses.mousePtr_offset) or 0
				if( mousePawnAddress ~= 0) then
					mousePawnId = memoryReadUInt(getProc(), mousePawnAddress + addresses.pawnId_offset) or 0
					mousePawnName = GetIdName(mousePawnId) or "<UNKNOWN>"
					mousePawnX = memoryReadFloat(getProc(), mousePawnAddress + addresses.pawnX_offset) or mousePawnX
					mousePawnY = memoryReadFloat(getProc(), mousePawnAddress + addresses.pawnY_offset) or mousePawnY
					mousePawnZ = memoryReadFloat(getProc(), mousePawnAddress + addresses.pawnZ_offset) or mousePawnZ
					setWindowName(getHwnd(), sprintf("\rObject found Id %d \"%s\", Distance %d\t\t\t", mousePawnId, mousePawnName, distance(playerX, playerZ, playerY, mousePawnX, mousePawnZ, mousePawnY)));
				else
					setWindowName(getHwnd(), sprintf("\rPlayer Position X: %d, Z: %d, Y: %d\t\t\t",playerX, playerZ, playerY));
				end
				lastTime = getTime()
			end
			yrest(10);
		end -- End of: while(true)
	end -- End of: while(running)
end

startMacro(main, true);
