-- V 1.0
-- North = 1.5
-- South = -1.5
-- East = 0
-- West = +3 or -3


function telefollow(_dist,address)
	teleport_SetStepSize(30)
	teleport_SetStepPause(300)
	if _dist == nil then
		print("\nrequirements missing.\n")
		return
	end
	
	local function calccoords(dist,angle)
		if dist == nil or angle == nil then
			print("\nrequirements missing.\n")
			return
		end
		local degrees, theta, sn, cs, X, Z
		degrees = angle * 60
		theta=(degrees*math.pi)/180;
		sn=math.sin(theta);
		cs=math.cos(theta);
		X= (dist*cs)
		Z= (dist*sn)
		return X,Z
	end
	
	player:update() 
	if address == nil then
		target = player:getTarget()
	else
		target = CPawn(address)
	end
	if target then
		X,Z = calccoords(_dist,target.Direction)
		teleport((target.X - X), (target.Z-Z), target.Y)
		player:faceDirection(target.Direction)
	end
end