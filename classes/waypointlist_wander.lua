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

	return CWaypoint(X, Z); -- TODO: Make sure this works
end


function CWaypointListWander:setRadius(rad)
	self.Radius = rad;
end