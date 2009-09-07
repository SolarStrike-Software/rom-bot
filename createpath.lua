include("database.lua");
include("addresses.lua");
include("classes/player.lua");
include("classes/inventory.lua");
include("classes/camera.lua");
include("classes/waypoint.lua");
include("classes/waypointlist.lua");
include("classes/waypointlist_wander.lua");
include("classes/node.lua");
include("settings.lua");
include("functions.lua");
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
p_harvest_command = "player:harvest();";	-- harvest command
p_targetNPC_command = "\n\t\tplayer:merchant(\"%s\");\n\t";	-- target NPC command
-- ********************************************************************
-- End of Change parameter changes                                    *
-- ********************************************************************


setStartKey(key.VK_DELETE);
setStopKey(key.VK_END);

wpKey = key.VK_NUMPAD1;		-- insert a movement point
harvKey = key.VK_NUMPAD2;	-- insert a harvest point	
targetNPCKey = key.VK_NUMPAD4;	-- insert a target a NPC and open dialog waypoint
saveKey = key.VK_NUMPAD3;	-- save the waypoints
restartKey = key.VK_NUMPAD9;	-- restart waypoints script



function saveWaypoints(list)
	keyboardBufferClear();
	io.stdin:flush();
	cprintf(cli.green, language[500]);	-- What do you want to name your path
	filename = getExecutionPath() .. "/waypoints/" .. io.stdin:read() .. ".xml";

	file, err = io.open(filename, "w");
	if( not file ) then
		error(err, 0);
	end

	local str = sprintf("<waypoints%s>\n", p_wp_gtype);	-- create first tag
	file:write(str);					-- write first tag

	local hf_temp1, hf_temp2;
	for i,v in pairs(list) do

		if( v.wp_type == "HP" ) then 		-- it's a harvest point?
			hf_temp1 = p_hp_type;	-- insert type=TRAVEL for harvest points if you want
			hf_temp2 = p_harvest_command;	-- then insert harvest command
		elseif( v.wp_type == "WP" ) then
			hf_temp1 = p_wp_type;		-- normal waypoint type
			hf_temp2 = ""; 			-- no special command
		elseif( v.wp_type == "NPC" ) then
			hf_temp1 = p_wp_type;		-- normal waypoint type
			hf_temp2 = sprintf(p_targetNPC_command, v.npc_name); -- player:targetNPC(%s);
		end;							

		local str = sprintf("\t<!-- #%2d --><waypoint x=\"%d\" z=\"%d\"%s>%s</waypoint>\n", i, v.X, v.Z, hf_temp1, hf_temp2);
		file:write(str);
	end
	file:write("</waypoints>\n");

	file:close();
end

function main()

	local running = true;
	while(running) do
		local wpList = {};

		settings.load();
		local playerPtr = memoryReadIntPtr(getProc(), staticcharbase_address, charPtr_offset);
		player = CPlayer(playerPtr);
		player:update();
		 
		settings.loadProfile(player.Name);

		local hf_x, hf_y, hf_wide, hf_high = windowRect( getWin());
		cprintf(cli.turquoise, language[42], hf_wide, hf_high, hf_x, hf_y );	-- RoM windows size

		cprintf(cli.green, language[501]);	-- RoM waypoint creator\n
		printf(language[502]			-- Insert new waypoint 
			.. language[503]		-- Insert new harvest waypoint
			.. language[505]		-- Save waypoints and quit
			.. language[504]		-- Insert target/dialog NPC waypoint
			.. language[506],		-- Save waypoints and restart
			getKeyName(wpKey), getKeyName(harvKey), getKeyName(saveKey), 
			getKeyName(targetNPCKey), getKeyName(restartKey) );
		
		attach(getWin())	
		addMessage(language[501]);

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

			if( keyPressed(targetNPCKey) ) then	-- target NPC key pressed
				hf_key_pressed = true;
				hf_key = "NPC";
			end;

			if( keyPressed(restartKey) ) then	-- restart key pressed
				hf_key_pressed = true;
				hf_key = "RESTART";
			end;

			if( hf_key_pressed == false ) then	-- key released, do the work

				-- SAVE Key: save waypoint file and exit
				if( hf_key == "SAVE" ) then
					saveWaypoints(wpList);
					hf_key = " ";	-- clear last pressed key
					running = false;
					break;
					--error("   ", 0); -- Not really an error, but it will drop us back to shell.
				end;

				-- waypoint or harvest point key: create a waypoint/harvest waypoint
				if( hf_key == "WP"  or		-- normal waypoint
					hf_key == "HP"  or	-- harvest waypoint
					hf_key == "NPC"  ) then	-- NPC waypoint

					player:update();

					local tmp = {};		
					tmp.X = player.X;		
					tmp.Z = player.Z;		

					local hf_type;
					if( hf_key == "HP" ) then 	-- is's a havest point?
						tmp.wp_type = "HP";	-- it is a harvest point
						hf_type = "HP"; 
						addMessage(language[512]); -- harvestpoint added
					elseif( hf_key == "WP" ) then
						tmp.wp_type = "WP"; 
						hf_type = "WP";
						addMessage(string.gsub(language[511],"¤",(#wpList + 1))); -- waypoint added
					elseif( hf_key == "NPC" ) then
						tmp.wp_type = "NPC";
						
						-- ask for NPC name
						--keyboardBufferClear();
						--io.stdin:flush();
						--cprintf(cli.green, language[507]);	-- What's the name of the NPC 
						--tmp.npc_name = io.stdin:read();
						
						-- get target name
						local target = player:getTarget();
						tmp.npc_name = target.Name;

						hf_type = sprintf("NPC (%s)", tmp.npc_name); 
						addMessage(string.gsub(language[513],"¤",tmp.npc_name));
					end; 
                    
					printf(language[508],	-- Continue to next. Press %s to save and quit
					#wpList + 1, hf_type, getKeyName(saveKey));

					table.insert(wpList, tmp);

				end;

				if( hf_key == "RESTART" ) then
					saveWaypoints(wpList);
					hf_key = " ";	-- clear last pressed key
					running = true; -- restart
					break;
				end;

				hf_key = " ";	-- clear last pressed key
			end;

			yrest(10);
		end -- End of: while(true)
	end -- End of: while(running)
end

startMacro(main, true);