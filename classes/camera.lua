CCamera = class(
	function(self)
		--self.Address = memoryReadUIntPtr(getProc(), addresses.staticbase_char, addresses.camPtr_offset) or 0
		
		local gameroot = addresses.client_exe_module_start + addresses.game_root.base;
		self.Address = memoryReadUIntPtr(getProc(), gameroot, addresses.game_root.camera.base) or 0;

		self.XUVec = 0.0;
		self.YUVec = 0.0;
		self.ZUVec = 0.0;

		self.X = 0;
		self.Y = 0;
		self.Z = 0;

		self.XFocus = 0;
		self.YFocus = 0;
		self.ZFocus = 0;

		self.Distance = 0
		if( self.Address ~= 0) then
			self:update();
		end
	end
);

function CCamera:update()
	local proc = getProc();
	local memerrmsg = "Error reading memory in CCamera:update()";

--[[
	self.XUVec = debugAssert(memoryReadFloat(proc, self.Address + addresses.camXUVec_offset), memerrmsg);
	self.YUVec = debugAssert(memoryReadFloat(proc, self.Address + addresses.camYUVec_offset), memerrmsg);
	self.ZUVec = debugAssert(memoryReadFloat(proc, self.Address + addresses.camZUVec_offset), memerrmsg);
--]]

	-- camera coordinates
	self.X = memoryReadFloat(proc, self.Address + addresses.game_root.camera.x);
	self.Y = memoryReadFloat(proc, self.Address + addresses.game_root.camera.y);
	self.Z = memoryReadFloat(proc, self.Address + addresses.game_root.camera.z);

	-- camera focus coordinates
	self.XFocus = debugAssert(memoryReadFloat( proc, self.Address + addresses.game_root.camera.focus_x), memerrmsg);
	self.ZFocus = debugAssert(memoryReadFloat( proc, self.Address + addresses.game_root.camera.focus_z), memerrmsg);
	self.YFocus = debugAssert(memoryReadFloat( proc, self.Address + addresses.game_root.camera.focus_y), memerrmsg);

	-- camera distance
	--self.Distance = memoryReadFloat(proc, self.Address + addresses.game_root.camera.distance);
	self.Distance = distance(self.X, self.Y, self.Z, self.XFocus, self.YFocus, self.ZFocus);

	--[[if( self.XUVec == nil or self.YUVec == nil or self.ZUVec == nil or
	self.X == nil or self.Y == nil or self.Z == nil or
	self.XFocus == nil or self.YFocus == nil or self.ZFocus == nil or self.Distance == nil) then
		error("Error reading memory in CCamera:update()");
	end
	--]]
end

function CCamera:setPosition(x, y, z)
	local proc = getProc();

	x = x or self.X;
	y = y or self.Y;
	z = z or self.Z;

	memoryWriteFloat(proc, self.Address + addresses.game_root.camera.x, x);
	memoryWriteFloat(proc, self.Address + addresses.game_root.camera.y, y);
	memoryWriteFloat(proc, self.Address + addresses.game_root.camera.z, z);
end

function CCamera:setRotation(angle)
	self:update();
	
	local originalDistance = self.Distance;
	
	-- Position camera behind player along this new angle.
	local nx = player.X + math.cos(angle + math.pi)*originalDistance;
	local nz = player.Z + math.sin(angle + math.pi)*originalDistance;
	
	self:setPosition(nx, nil, nz);
end

function CCamera:setDistance(distance)
	if type(distance) == "number" then
		if distance < 1 then
			distance = 1
		elseif distance > 150 then
			distance = 150
		end
	else
		-- invalid value.
		return
	end
	
	local base = getBaseAddress(addresses.game_root.base);
	memoryWriteFloatPtr(getProc(), base, addresses.game_root.camdistance, distance);
	
	local angle = math.atan2(self.ZFocus - self.Z, self.XFocus - self.X);
	angle = math.fmod(angle + math.pi, math.pi*2);
	local nx = self.XFocus + math.cos(angle)*distance;
	local nz = self.ZFocus + math.sin(angle)*distance;
	self:setPosition(nx, nil, nz);
end
