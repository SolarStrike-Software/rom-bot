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
p_harvest_command = "player:harvest();";
p_merchant_command = "player:merchant(\"%s\");";
p_targetNPC_command = "player:target_NPC(\"%s\");";
p_targetObj_command = "player:target_Object(\"%s\");";
p_choiceOption_command = "sendMacro(\"ChoiceOption(%d);\");";
p_mouseClickL_command = "player:mouseclickL(%d, %d, %d, %d);";
-- ********************************************************************
-- End of Change parameter changes                                    *
-- ********************************************************************


setStartKey(settings.hotkeys.START_BOT.key);
setStopKey(settings.hotkeys.STOP_BOT.key);

wpKey = key.VK_NUMPAD1;			-- insert a movement point
harvKey = key.VK_NUMPAD2;		-- insert a harvest point
saveKey = key.VK_NUMPAD3;		-- save the waypoints
merchantKey = key.VK_NUMPAD4;	-- target merchant, repair and buy stuff
targetNPCKey = key.VK_NUMPAD5;	-- target NPC and open dialog waypoint
choiceOptionKey = key.VK_NUMPAD6; 	-- insert choiceOption
mouseClickKey = key.VK_NUMPAD7; -- Save MouseClick
restartKey = key.VK_NUMPAD9;	-- restart waypoints script
resetKey = key.VK_NUMPAD8;	-- restart waypoints script and discard changes
codeKey = key.VK_NUMPAD0;		-- add comment to last WP.
targetObjKey = key.VK_DECIMAL;	-- target an object and action it.


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

local playerPtr = memoryReadIntPtr(getProc(), addresses.staticbase_char, addresses.charPtr_offset);
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


function saveWaypoints(list)
	keyboardBufferClear();
	io.stdin:flush();
	cprintf(cli.green, language[500]);	-- What do you want to name your path
	filename = getExecutionPath() .. "/waypoints/" .. io.stdin:read() .. ".xml";

	file, err = io.open(filename, "w");
	if( not file ) then
		error(err, 0);
	end

	local openformat = "\t<!-- #%3d --><waypoint x=\"%d\" z=\"%d\" y=\"%d\"%s>%s";
	local closeformat = "</waypoint>\n";

	file:write("<?xml version=\"1.0\" encoding=\"utf-8\"?>");
	local str = sprintf("<waypoints%s>\n", p_wp_gtype);	-- create first tag
	file:write(str);					-- write first tag

	local hf_line, tag_open = "", false;
	for i,v in pairs(list) do
		if( v.wp_type == "HP" ) then -- Harvest point
			if( tag_open ) then hf_line = hf_line .. "\t" .. closeformat; end;
			hf_line = hf_line .. sprintf(openformat, i, v.X, v.Z, v.Y, p_hp_type, p_harvest_command) .. closeformat;
			tag_open = false;
		elseif( v.wp_type == "WP" ) then -- Waypoint
			if( tag_open ) then hf_line = hf_line .. "\t" .. closeformat; end;
			hf_line = hf_line .. sprintf(openformat, i, v.X, v.Z, v.Y, p_wp_type, "");
			tag_open = true;
		elseif( v.wp_type == "MER" ) then -- Merchant
			if( tag_open ) then
				hf_line = hf_line .. "\t\t" .. sprintf(p_merchant_command, string.gsub(v.npc_name, "\"", "\\\"")) .. "\n";
			else
				hf_line = hf_line .. sprintf(openformat, i, v.X, v.Z, v.Y, p_wp_type,
				"\n\t\t" .. sprintf(p_merchant_command, v.npc_name) ) .. "\n";
				tag_open = true;
			end
		elseif( v.wp_type == "NPC" ) then -- Open NPC Dialog
			if( tag_open ) then
				hf_line = hf_line .. "\t\t" .. sprintf(p_targetNPC_command, string.gsub(v.npc_name, "\"", "\\\"")) .. "\n";
			else
				hf_line = hf_line .. sprintf(openformat, i, v.X, v.Z, v.Y, p_wp_type,
				"\n\t\t" .. sprintf(p_targetNPC_command, v.npc_name) ) .. "\n";
				tag_open = true;
			end
		elseif( v.wp_type == "CO" ) then -- Choice Option
			if( tag_open ) then
				hf_line = hf_line .. "\t\t" .. sprintf(p_choiceOption_command, v.co_num) .. "\n";
			else
				hf_line = hf_line .. sprintf(openformat, i, v.X, v.Z, v.Y, p_wp_type,
				"\n\t\t" .. sprintf(p_choiceOption_command, v.co_num) ) .. "\n";
				tag_open = true;
			end
		elseif( v.wp_type == "MC" ) then -- Mouse click (left)
			if( tag_open ) then
				hf_line = hf_line .. "\t\t" .. sprintf(p_mouseClickL_command, v.mx, v.my, v.wide, v.high) .. "\n";
			else
				hf_line = hf_line .. sprintf(openformat, i, v.X, v.Z, v.Y, p_wp_type,
				"\n\t\t" .. sprintf(p_mouseClickL_command, v.mx, v.my, v.wide, v.high) ) .. "\n";
				tag_open = true;
			end
		elseif( v.wp_type == "COD" ) then -- Code
			if( tag_open ) then
				hf_line = hf_line .. "\t\t" .. v.com .. "\n";
			else
				hf_line = hf_line .. sprintf(openformat, i, v.X, v.Z, v.Y, p_wp_type,
				"\n\t\t" .. v.com ) .. "\n";
				tag_open = true;
			end
		elseif( v.wp_type == "OBJ" ) then -- Target Object
			if( tag_open ) then
				hf_line = hf_line .. "\t\t" .. sprintf(p_targetObj_command, v.obj_name) .. "\n";
			else
				hf_line = hf_line .. sprintf(openformat, i, v.X, v.Z, v.Y, p_wp_type,
				"\n\t\t" .. sprintf(p_targetObj_command, v.obj_name) ) .. "\n";
				tag_open = true;
			end
		end
	end

	-- If we left a tag open, close it.
	if( tag_open ) then
		hf_line = hf_line .. "\t" .. closeformat;
	end

	file:write(hf_line);
	file:write("</waypoints>");

--[[
	if( tag_open ) then
		file:write("\n\t</waypoint>\n</waypoints>\n");
	else
		file:write("</waypoints>\n");
	end
]]

	file:close();

	wpList = {};	-- clear intenal table

end

function main()

	local running = true;
	while(running) do

		local hf_x, hf_y, hf_wide, hf_high = windowRect( getWin());
		cprintf(cli.turquoise, language[42], hf_wide, hf_high, hf_x, hf_y );	-- RoM windows size
		cprintf(cli.green, language[501]);	-- RoM waypoint creator\n
		printf(language[502]			-- Insert new waypoint
			.. language[503]		-- Insert new harvest waypoint
			.. language[505]		-- Save waypoints and quit
			.. language[509]		-- Insert merchant command
			.. language[504]		-- Insert target/dialog NPC command
			.. language[517]		-- Insert choiceOption command
			.. language[510]		-- Insert Mouseclick Left command
			.. language[518]		-- Reset script
			.. language[506]		-- Save waypoints and restart
			.. language[519]		-- Insert comment command
			.. language[522],		-- Insert comment command
			getKeyName(wpKey), getKeyName(harvKey), getKeyName(saveKey),
			getKeyName(merchantKey), getKeyName(targetNPCKey),
			getKeyName(choiceOptionKey), getKeyName(mouseClickKey),
			getKeyName(resetKey), getKeyName(restartKey),
			getKeyName(codeKey), getKeyName(targetObjKey));

		attach(getWin())
		addMessage(language[501]);	-- -- RoM waypoint creator\n

		local hf_key_pressed, hf_key;
		while(true) do

			hf_key_pressed = false;

			if( keyPressed(wpKey) ) then	-- normal waypoint key pressed
				hf_key_pressed = true;
				hf_key = "WP";
			end;
			if( keyPressed(harvKey) ) then	-- harvest waypoint key pressed
				hf_key_pressed = true;
				hf_key = "HP";
			end;
			if( keyPressed(saveKey) ) then	-- save key pressed
				hf_key_pressed = true;
				hf_key = "SAVE";
			end;
			if( keyPressed(merchantKey ) ) then	-- merchant NPC key pressed
				hf_key_pressed = true;
				hf_key = "MER";
			end;
			if( keyPressed(targetNPCKey) ) then	-- target NPC key pressed
				hf_key_pressed = true;
				hf_key = "NPC";
			end;
			if( keyPressed(choiceOptionKey) ) then	-- choice option key pressed
				hf_key_pressed = true;
				hf_key = "CO";
			end;
			if( keyPressed(codeKey) ) then	-- choice option key pressed
				hf_key_pressed = true;
				hf_key = "COD";
			end;
			if( keyPressed(mouseClickKey) ) then	-- target MouseClick key pressed
				hf_key_pressed = true;
				hf_key = "MC";
			end;
			if( keyPressed(restartKey) ) then	-- restart key pressed
				hf_key_pressed = true;
				hf_key = "RESTART";
			end;
			if( keyPressed(resetKey) ) then	-- reset key pressed
				hf_key_pressed = true;
				hf_key = "RESET";
			end;
			if( keyPressed(targetObjKey) ) then	-- reset key pressed
				hf_key_pressed = true;
				hf_key = "OBJ";
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


				player:update();

				local tmp = {}, hf_type;
				tmp.X = player.X;
				tmp.Z = player.Z;
				tmp.Y = player.Y;
				hf_type = "";


				-- waypoint or harvest point key: create a waypoint/harvest waypoint
				if( hf_key == "HP" ) then			-- harvest waypoint
					tmp.wp_type = "HP";
					hf_type = "HP";
					addMessage(sprintf(language[512], #wpList+1) ); -- harvestpoint added
				elseif(	hf_key == "WP") then			-- normal waypoint
					tmp.wp_type = "WP";
					hf_type = "WP";
					addMessage(sprintf(language[511], #wpList+1) ); -- waypoint added
				elseif( hf_key == "MER" ) then -- merchant command
					tmp.wp_type = "MER";
					local target = player:getTarget();	-- get target name
					tmp.npc_name = target.Name;
					hf_type = "target/merchant NPC "..tmp.npc_name;
					addMessage(sprintf(language[513], #wpList+1, tmp.npc_name));
				elseif( hf_key == "NPC" ) then -- target npc
					tmp.wp_type = "NPC";
					local target = player:getTarget();	-- get target name
					tmp.npc_name = target.Name;
					hf_type = "target/dialog NPC "..tmp.npc_name;
					addMessage(sprintf(language[514], #wpList+1, tmp.npc_name));
				elseif(	hf_key == "CO") then			-- choose npc option
					tmp.wp_type = "CO";

					-- ask for option number
					keyboardBufferClear();
					io.stdin:flush();
					cprintf(cli.green, language[507]);	-- enter number of option
					tmp.co_num = io.stdin:read();
					hf_type = "choiceOpion "..tmp.co_num;
					addMessage(sprintf(language[516], tmp.co_num ) ); -- choice option
				elseif(	hf_key == "COD") then			-- enter code
					tmp.wp_type = "COD";

					-- ask for option number
					keyboardBufferClear();
					io.stdin:flush();
					cprintf(cli.green, language[520]);	-- add code
					tmp.com = io.stdin:read();
					hf_type = tmp.com;
					addMessage(sprintf(language[521], tmp.com ) ); -- code
				elseif( hf_key == "MC" ) then 	-- is's a mouseclick?
					tmp.wp_type = "MC";			-- it is a mouseclick
					local x, y = mouseGetPos();
					local wx, wy, hf_wide, hf_high = windowRect(getWin());
					tmp.wide = hf_wide;
					tmp.high = hf_high;
			        tmp.mx = x - wx;
					tmp.my = y - wy;
					hf_type = sprintf("mouseclick %d,%d (%dx%d)", tmp.mx, tmp.my, tmp.wide, tmp.high );
					addMessage(sprintf(language[515],
					tmp.mx, tmp.my, tmp.wide, tmp.high )); -- Mouseclick
				elseif( hf_key == "OBJ" ) then 	-- target object
					tmp.wp_type = "OBJ";
					local mouseObj = CObject(memoryReadIntPtr(getProc(), addresses.staticbase_char, addresses.mousePtr_offset));
					tmp.obj_name = mouseObj.Name
					hf_type = sprintf("target object %s", tmp.obj_name );
					addMessage(sprintf(language[523],tmp.obj_name)); -- target object
				end


				printf(language[508],	-- Continue to next. Press %s to save and quit
					#wpList+1, hf_type, getKeyName(saveKey));

				table.insert(wpList, tmp);

				if( hf_key == "RESTART" ) then
					saveWaypoints(wpList);
					hf_key = " ";	-- clear last pressed key
					running = true; -- restart
					break;
				end;


				hf_key = nil;	-- clear last pressed key
			end;

			yrest(10);
		end -- End of: while(true)
	end -- End of: while(running)
end

startMacro(main, true);
