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

	self.FileName = getFileName(filename);
	self.Waypoints = {}; -- Delete current waypoints.
	self.ForcedType = 0;	-- delete forced waypoint type

	local onLoadEvent = nil;

	for i,v in pairs(elements) do
		local x,z,y = v:getAttribute("x"), v:getAttribute("z"), v:getAttribute("y");
		local type = v:getAttribute("type");
		local action = v:getValue();
		local name = v:getName() or "";
		local tag = v:getAttribute("tag") or "";

		if( string.lower(name) == "waypoint" ) then
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
				onLoadEvent = loadstring(action);
				assert(onLoadEvent, sprintf(language[152]));

				if( _G.type(onLoadEvent) ~= "function" ) then
					onLoadEvent = nil;
				end;
			end
		end
	end

	if #self.Waypoints == 0 then -- Can't be mode 'waypoints' with no waypoints
		self.Mode = "wander"
	else
		self.Mode = "waypoints"
		self:setWaypointIndex(self:getNearestWaypoint(player.X, player.Z, player.Y));
		self.LastWaypoint = self.CurrentWaypoint -1
		if self.LastWaypoint < 1 then self.LastWaypoint = #self.Waypoints end
	end

	if( onLoadEvent ) then
		onLoadEvent();
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
function CWaypointList:getNearestWaypoint(_x, _z, _y)
	local closest = 1;

	for i,v in pairs(self.Waypoints) do
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
