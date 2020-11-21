WPT_FORWARD = 1;
WPT_BACKWARD = 2;

CWaypointList = class(
	function(self)
		self.Waypoints = {};
		self.CurrentWaypoint = 1;
		self.LastWaypoint = 1;
		self.Direction = WPT_FORWARD;
		self.OrigX = player.X;
		self.OrigZ = player.Z;
		self.Radius = 500;
		self.FileName = nil;
		self.Mode = "waypoints";
		self.KillZone = {};
		self.ExcludeZones = {}
		self.ResumePoint = nil

		self.Type = 0; -- UNSET
		self.ForcedType = 0; 	-- Wp type to overwrite current type, can be used by users in WP coding
	end
);

function CWaypointList:load(filename)
	local root = xml.open(filename);
	if( not root ) then
		error(sprintf("Failed to load waypoints from \'%s\'", filename), 0);
	end
	local elements = root:getElements();
	local type = root:getAttribute("type");

	if( type ) then
		if( type == "TRAVEL" ) then
			self.Type = WPT_TRAVEL;
		elseif( type == "NORMAL" ) then
			self.Type = WPT_NORMAL;
		elseif( type == "RUN" ) then
			self.Type = WPT_RUN;
		else
			self.Type = WPT_NORMAL;
		end
	else
		self.Type = WPT_NORMAL;
	end

	self.FileName = string.match(filename,"waypoints/(.*)");
	self.Waypoints = {}; -- Delete current waypoints.
	self.ForcedType = 0;	-- delete forced waypoint type

	local onLoadEvent = nil;

	for i,v in pairs(elements) do
		local x,z,y = v:getAttribute("x"), v:getAttribute("z"), v:getAttribute("y");
		local type = v:getAttribute("type");
		local action = v:getValue();
		local name = v:getName() or "";
		local tag = v:getAttribute("tag") or "";

		if( string.lower(name) == "waypoint" ) and x and z then
			local tmp = CWaypoint(x, z, y);
			if( action ) then tmp.Action = action; end;
			if( type ) then
				if( type == "TRAVEL" ) then
					tmp.Type = WPT_TRAVEL;
				elseif( type == "RUN" ) then
					tmp.Type = WPT_RUN;
				elseif( type == "NORMAL" ) then
					tmp.Type = WPT_NORMAL;
				else
					-- Undefined type, assume WPT_NORMAL
					tmp.Type = WPT_NORMAL;
				end
			else
				-- No type set, assume Type from header tag
				tmp.Type = self.Type;
			end

			if( tag ) then tmp.Tag = string.lower(tag); end;

			table.insert(self.Waypoints, tmp);
		elseif( string.lower(name) == "onload" ) then
			if( string.len(action) > 0 and string.find(action, "%w") ) then
				self.onLoadEvent,errmsg = loadstring(action);
				if( not self.onLoadEvent ) then
					cprintf(cli.yellow, language[152] .. "\n")
					handleLoadstringFailure(action, errmsg, filename)
				end

				if( _G.type(self.onLoadEvent) ~= "function" ) then
					self.onLoadEvent = nil;
				end;
			end
		end
	end

	self.Mode = "waypoints"
	if #self.Waypoints > 0 then
		self:setWaypointIndex(self:getNearestWaypoint(player.X, player.Z, player.Y));
		self.LastWaypoint = self.CurrentWaypoint -1
		if self.LastWaypoint < 1 then self.LastWaypoint = #self.Waypoints end
	end

	if( self.onLoadEvent ) then
		self.DoOnload = true
	end
end


function CWaypointList:getFileName()
	if( self.FileName == nil ) then
		return "<NONE>";
	else
		return self.FileName;
	end
end

function CWaypointList:setMode(mode)
	self.Mode = mode;
end

function CWaypointList:setForcedWaypointType(_type)

	if( _type == nil  or  _type == ""  or  _type == 0 ) then
		self.ForcedType = 0;
		cprintf(cli.green, "Forced waypoint type cleared.\n" );
		return;
	end;

	if( _type == "NORMAL"  or  _type == WPT_NORMAL ) then
		self.ForcedType = WPT_NORMAL;
	elseif( _type == "TRAVEL"  or  _type == WPT_TRAVEL) then
		self.ForcedType = WPT_TRAVEL;
	elseif( _type == "RUN"  or  _type == WPT_RUN) then
		self.ForcedType = WPT_RUN;
	else
		cprintf(cli.yellow, "You try to force an unknown waypoint type \'%s\'. Please check.\n", _type);
		error("Bot finished due to error above.", 0);
	end
	player.Current_waypoint_type = self.ForcedType

	cprintf(cli.green, "Forced waypoint type \'%s\' set by user.\n", _type );
end

function CWaypointList:getMode()
	return self.Mode;
end

function CWaypointList:getRadius()
	return self.Radius;
end

function CWaypointList:advance()
	self.LastWaypoint = self.CurrentWaypoint
	if( self.Direction == WPT_FORWARD ) then
		self.CurrentWaypoint = self.CurrentWaypoint + 1;
		if( self.CurrentWaypoint > #self.Waypoints ) then
			self.CurrentWaypoint = 1;
		end
	else
		self.CurrentWaypoint = self.CurrentWaypoint - 1;
		if( self.CurrentWaypoint < 1 ) then
			self.CurrentWaypoint = #self.Waypoints;
		end
	end
end

function CWaypointList:backward()
	self.LastWaypoint = self.CurrentWaypoint
	if( self.Direction == WPT_FORWARD ) then
		self.CurrentWaypoint = self.CurrentWaypoint - 1;
		if( self.CurrentWaypoint < 1 ) then
			self.CurrentWaypoint = #self.Waypoints;
		end
	else
		self.CurrentWaypoint = self.CurrentWaypoint + 1;
		if( self.CurrentWaypoint > #self.Waypoints ) then
			self.CurrentWaypoint = 1;
		end
	end
end

function CWaypointList:getNextWaypoint(_num)
	if( not _num ) then _num = 0; end;

	local hf_wpnum;
	if( self.Direction == WPT_FORWARD ) then
		hf_wpnum = self.CurrentWaypoint + _num;
	else
		hf_wpnum = self.CurrentWaypoint - _num;
	end

	if( hf_wpnum > #self.Waypoints ) then
		hf_wpnum = hf_wpnum - #self.Waypoints;
	elseif( hf_wpnum < 1 ) then
		hf_wpnum = hf_wpnum + #self.Waypoints;
	end

	local tmp = CWaypoint(self.Waypoints[hf_wpnum]);
	tmp.wpnum = hf_wpnum;

	-- check if forced type is set, that could be done by users
	-- within lua coding in the waypoint tags
	if(self.ForcedType ~= 0 ) then
		tmp.Type = self.ForcedType;
	end

	if( settings.profile.options.WAYPOINT_DEVIATION < 2 ) then
		return tmp;
	end

	local halfdev = settings.profile.options.WAYPOINT_DEVIATION/2;

	tmp.X = tmp.X + math.random(halfdev) - halfdev;
	tmp.Z = tmp.Z + math.random(halfdev) - halfdev;

	return tmp;
end

-- Sets the "direction" (forward/backward) to travel
function CWaypointList:setDirection(wpt)
	-- Ignore invalid types
	if( wpt ~= WPT_FORWARD and wpt ~= WPT_BACKWARD ) then
		return;
	end;

	if( wpt ~= self.Direction ) then
		self.Direction = wpt
		if( wpt == WPT_BACKWARD ) then
			self.CurrentWaypoint = self.CurrentWaypoint - 2;
			if( self.CurrentWaypoint < 1 ) then
				self.CurrentWaypoint = #self.Waypoints + self.CurrentWaypoint;
			end
		else
			self.CurrentWaypoint = self.CurrentWaypoint + 2;
			if( self.CurrentWaypoint > #self.Waypoints ) then
				self.CurrentWaypoint = self.CurrentWaypoint - #self.Waypoints;
			end
		end;
	end
end

-- Reverse your current direction
function CWaypointList:reverse()
	if( self.Direction == WPT_FORWARD ) then
		self:setDirection(WPT_BACKWARD);
	else
		self:setDirection(WPT_FORWARD);
	end;
end

-- Sets the next waypoint to move to to whatever
-- index you want.
function CWaypointList:setWaypointIndex(index)
	if( type(index) ~= "number" ) then
		error("setWaypointIndex() requires a number. Received " .. type(index), 2);
	end
	if( index < 1 ) then index = 1; end;
	if( index > #self.Waypoints ) then index = #self.Waypoints; end;
	self.LastWaypoint = self.CurrentWaypoint
	self.CurrentWaypoint = index;
end

-- Returns an index to the waypoint closest to the given point.
function CWaypointList:getNearestWaypoint(_x, _z, _y, _start, _end)
	if type(_start) == "string" then
		_start = self:findWaypointTag(_start)
	end
	if type(_end) == "string" then
		_end = self:findWaypointTag(_end)
	end
	if _start and _start < 1 then _start = 1 end
	if _end and _end > #self.Waypoints then _end = #self.Waypoints end

	local closest = _start or 1;

	for i = (_start or 1), (_end or #self.Waypoints) do
		local v= self.Waypoints[i]
		local oldClosestWp = self.Waypoints[closest];
		if( distance(_x, _z, _y, v.X, v.Z, v.Y) < distance(_x, _z, _y, oldClosestWp.X, oldClosestWp.Z, oldClosestWp.Y) ) then
			closest = i;
		end
	end

	return closest;
end

function CWaypointList:findWaypointTag(tag)
	tag = string.lower(tag);
	for i,v in pairs(self.Waypoints) do
		if( v.Tag == tag ) then
			return i;
		end
	end

	return 0;
end

function CWaypointList:setKillZone(_zone)
	-- Reset Kill Zone
	if _zone == nil or _zone == "" or (type(_zone) == "table" and #_zone == 0) then
		self:clearKillZone()
		return
	end

	-- Check argument
	if type(_zone) == "table" then
		-- check table values
		for k,v in pairs(_zone) do
			if (not v.X) or (not v.Z) then
				error("SetKillZone: Invalid table.",0)
			end
		end
	elseif type(_zone) == "string" then
		if not string.find(_zone,".xml", 1, true) then
			_zone = _zone .. ".xml"
		end
		local filename = getExecutionPath() .. "/waypoints/" .. _zone
		if not fileExists(filename) then
			filename = getExecutionPath() .. "/../romglobal/waypoints/" .. _zone
		end
		local file, err = io.open(filename, "r");
		if file then
			file:close();
			local tmpWPL = CWaypointList();
			tmpWPL:load(filename);
			_zone = table.copy(tmpWPL.Waypoints)
		else
			error("SetKillZone: invalid file name.",0)
		end
	else
		error("SetKillZone: Invalid argument.",0)
	end

	-- Set kill zone
	self:clearKillZone()
	for i = 1, #_zone do
		self.KillZone[i] = {X=_zone[i].X, Z=_zone[i].Z}
	end
end

function CWaypointList:clearKillZone()
	self.KillZone = {}
end

function CWaypointList:addExcludeZone(_zone,_zonename)
	-- Check argument
	if type(_zone) == "table" then
		-- check table values
		for k,v in pairs(_zone) do
			if (not v.X) or (not v.Z) then
				error("AddExcludeZone: Invalid table.",0)
			end
		end
	elseif type(_zone) == "string" then
		if not string.find(_zone,".xml", 1, true) then
			_zone = _zone .. ".xml"
		end
		local filename = getExecutionPath() .. "/waypoints/" .. _zone
		if not fileExists(filename) then
			filename = getExecutionPath() .. "/../romglobal/waypoints/" .. _zone
		end
		local file, err = io.open(filename, "r");
		if file then
			file:close();
			local tmpWPL = CWaypointList();
			tmpWPL:load(filename);
			_zone = table.copy(tmpWPL.Waypoints)
		else
			error("AddExcludeZone: invalid file name.",0)
		end
	else
		error("AddExcludeZone: Invalid argument.",0)
	end

	local tmp = {}
	for i = 1, #_zone do
		tmp[i] = {X=_zone[i].X, Z=_zone[i].Z}
	end

	-- Add Exclude Zone
	if _zonename then
		self.ExcludeZones[_zonename] = table.copy(tmp)
	else
		table.insert(self.ExcludeZones,tmp)
	end
end

function CWaypointList:deleteExcludeZone(_zonename)
	for name,zone in pairs(self.ExcludeZones) do
		if name == _zonename then
			self.ExcludeZones[name] = nil
			return
		end
	end
end

function CWaypointList:clearExcludeZones()
	self.ExcludeZones = {}
end

-- After a pullback, use this function to find the waypoint you were pulled before.
function CWaypointList:findPulledBeforeWaypoint()
	local WPCount = #self.Waypoints

	-- If 1 or 2 then it can't change.
	if WPCount < 3 then
		return self.CurentWaypoint
	end

	local DistLimit = 1000 -- Limits distance to look back from current waypoint.
	local wptotest = self.CurrentWaypoint
	local bestwaypointindex = self.CurrentWaypoint -- Best waypoint index so far
	local bestdist -- Best distance to path so far
	local disttotal = 0   -- Tally of distance so far

	repeat
		local towp = self.Waypoints[wptotest]
		local fromwp = self.Waypoints[wptotest-1]
		if fromwp == nil then fromwp = self.Waypoints[#self.Waypoints] end

		-- First find segment point
		local segpoint = getNearestSegmentPoint(player.X, player.Z, towp.X, towp.Z, fromwp.X, fromwp.Z)

		-- if segpoint = towp or fromwp then it isn't between the wps
		if not (segpoint.X == towp.X and segpoint.Z == towp.Z) and not (segpoint.X == fromwp.X and segpoint.Z == fromwp.Z) then
			-- Get player distance to segment
			local tmpdist = distance(player, segpoint)
			-- See if it's a better match
			if bestdist == nil or tmpdist < bestdist then -- Compare
				bestdist = tmpdist
				bestwaypointindex = wptotest
			end
		end

		-- Check how far we have come from curentwaypoint
		disttotal = disttotal + distance(towp, fromwp)
		if disttotal > DistLimit then -- Exceeded limit. Return best score
			return bestwaypointindex
		end

		wptotest = wptotest - 1
		if wptotest < 1 then wptotest = #self.Waypoints end
	until wptotest == self.CurrentWaypoint -- Gone through all points

	return bestwaypointindex
end

function CWaypointList:updateResume()
	if self.Mode ~= "wander" then
		local file=io.open(getExecutionPath() .. "/logs/resumes/"..player.Name..".txt","w")
		if file then
			file:write("return \""..self.FileName.."\", "..self.CurrentWaypoint..", "..(player.Current_waypoint_type or "nil"))
			file:close()
		end
	end
end

