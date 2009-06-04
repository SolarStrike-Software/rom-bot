WPT_FORWARD = 1;
WPT_BACKWARD = 2;

CWaypointList = class(
	function(self)
		self.Waypoints = {};
		self.CurrentWaypoint = 1;
		self.Direction = WPT_FORWARD;
		self.OrigX = player.X;
		self.OrigZ = player.Z;
		self.Radius = 500;
	end
);

function CWaypointList:load(filename)
	local root = xml.open(filename);
	if( not root ) then
		error("Failed to load waypoints from \'%s\'", filename);
	end
	local elements = root:getElements();

	self.Waypoints = {}; -- Delete current waypoints.

	for i,v in pairs(elements) do
		local x,z = v:getAttribute("x"), v:getAttribute("z");
		local type = v:getAttribute("type");
		local action = v:getValue();

		local tmp = CWaypoint(x, z);
		if( action ) then tmp.Action = action; end;
		if( type ) then
			if( type == "TRAVEL" ) then
				tmp.Type = WPT_TRAVEL;
			elseif( type == "NORMAL" ) then
				tmp.Type = WPT_NORMAL;
			else
				-- Undefined type, assume WPT_NORMAL
				tmp.Type = WPT_NORMAL;
			end
		else
			-- No type set, assume WPT_NORMAL
			tmp.Type = WPT_NORMAL;
		end

		table.insert(self.Waypoints, tmp);
	end

	self.CurrentWaypoint = 1;
end

function CWaypointList:advance()

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

function CWaypointList:getNextWaypoint()
	local tmp = CWaypoint(self.Waypoints[self.CurrentWaypoint]);
	if( settings.profile.options.WAYPOINT_DEVIATION < 2 ) then
		return tmp;
	end

	local halfdev = settings.profile.options.WAYPOINT_DEVIATION/2;

	tmp.X = tmp.X + math.random(halfdev) - halfdev;
	tmp.Z = tmp.Z + math.random(halfdev) - halfdev;

	return tmp; --self.Waypoints[self.CurrentWaypoint];
end

-- Sets the "direction" (forward/backward) to travel
function CWaypointList:setDirection(wpt)
	-- Ignore invalid types
	if( wpt ~= WPT_FORWARD and wpt ~= WPT_BACKWARD ) then
		return;
	end;

	self.Direction = wpt;
end

-- Reverse your current direction
function CWaypointList:reverse()
	if( self.Direction == WPT_FORWARD ) then
		self.Direction = WPT_BACKWARD;
	else
		self.Direction = WPT_FORWARD;
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

	self.CurrentWaypoint = index;
end

-- Returns an index to the waypoint closest to the given point.
function CWaypointList:getNearestWaypoint(_x, _z)
	local closest = 1;

	for i,v in pairs(self.Waypoints) do
		local oldClosestWp = self.Waypoints[closest];
		if( distance(_x, _z, v.X, v.Z) < distance(_x, _z, oldClosestWp.X, oldClosestWp.Z) ) then
			closest = i;
		end
	end

	return closest;
end