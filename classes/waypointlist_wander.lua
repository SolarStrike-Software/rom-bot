CWaypointListWander = class(CWaypointList);


function CWaypointListWander:load(filename)
	-- Unused
end


function CWaypointListWander:advance()
	-- Unused
end

function CWaypointListWander:getNextWaypoint()
	local halfrad = self.Radius/2;
	local X = self.OrigX + math.random(-halfrad, halfrad);
	local Z = self.OrigZ + math.random(-halfrad, halfrad);

	-- no active moving if radius=0, so player can move the character manuel to every position
	-- that means also no moving back to fught start position for melees
	if( self.Radius == 0 ) then
		X = player.X;
		Z = player.Z;
	end

	return CWaypoint(X, Z); -- TODO: Make sure this works
end


function CWaypointListWander:setRadius(rad)
	self.Radius = rad;
end

function CWaypointListWander:findWaypointTag(tag)
	return 0;
end