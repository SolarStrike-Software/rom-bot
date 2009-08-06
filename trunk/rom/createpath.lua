include("addresses.lua");
include("classes/player.lua");
include("classes/waypoint.lua");
include("settings.lua");
include("functions.lua");

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
-- ********************************************************************
-- End of Change parameter changes                                    *
-- ********************************************************************


setStartKey(key.VK_DELETE);
setStopKey(key.VK_END);

wpKey = key.VK_NUMPAD1;		-- insert a movement point
harvKey = key.VK_NUMPAD2;	-- insert a harvest point	
saveKey = key.VK_NUMPAD3;	-- save the waypoints
restartKey = key.VK_NUMPAD9;	-- restart waypoints script


function saveWaypoints(list)
	keyboardBufferClear();
	io.stdin:flush();
	cprintf(cli.green, "What do you want to name your path?\nName> ");
	filename = getExecutionPath() .. "/waypoints/" .. io.stdin:read() .. ".xml";

	file, err = io.open(filename, "w");
	if( not file ) then
		error(err, 0);
	end

	local str = sprintf("<waypoints%s>\n", p_wp_gtype);	-- create first tag
	file:write(str);					-- write first tag

	for i,v in pairs(list) do

		if( v.harvPoint == true ) then 		-- it's a harvest point?
			hf_temp1 = p_hp_type;	-- insert type=TRAVEL for harvest points if you want
			hf_temp2 = p_harvest_command;	-- then insert harvest command
		else 
			hf_temp1 = p_wp_type;		-- normal waypoint type
			hf_temp2 = ""; 			-- no special command
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

		local playerPtr = memoryReadIntPtr(getProc(), staticcharbase_address, charPtr_offset);
		player = CPlayer(playerPtr);
		player:update();

		local hf_x, hf_y, hf_wide, hf_high = windowRect( getWin());
		cprintf(cli.turquoise, "RoM windows size is %sx%s\n", hf_wide, hf_high );	-- RoM windows size

		cprintf(cli.green, "RoM waypoint creator\n");
		printf("Hotkeys:\n  (%s)\tInsert new waypoint (at player position)\n"
			.. "  (%s)\tInsert new harvest waypoint (at player position)\n"	
			.. "  (%s)\tSave waypoints and quit\n"
			.. "  (%s)\tSave waypoints and restart\n",
			getKeyName(wpKey), getKeyName(harvKey), getKeyName(saveKey), getKeyName(restartKey) );

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
					hf_key == "HP"  ) then	-- harvet waypoint

					player:update();

					local tmp = {};		
					tmp.X = player.X;		
					tmp.Z = player.Z;		

					if( hf_key == "HP" ) then 	-- is's a havest point?
						tmp.harvPoint = true;	-- it is a harvest point
						hf_temp = "HP";
					else 
						tmp.harvPoint = false; 
						hf_temp = "WP";
					end; 

					printf("Recorded [#%2d] %s, Continue to next. Press %s to save and quit\n",
					#wpList + 1, hf_temp,getKeyName(saveKey));

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

--while (true) do
	startMacro(main, true);
--end;