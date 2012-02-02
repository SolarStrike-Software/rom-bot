CCamera = class(
	function(self, ptr)
		self.Address = ptr;
		self.XUVec = 0.0;
		self.YUVec = 0.0;
		self.ZUVec = 0.0;

		self.X = 0;
		self.Y = 0;
		self.Z = 0;

		self.XFocus = 0;
		self.YFocus = 0;
		self.ZFocus = 0;
		if( self.Address ) then
			self:update();
		end
	end
);

function CCamera:update()
	local proc = getProc();
	local memerrmsg = "Error reading memory in CCamera:update()";

	self.XUVec = debugAssert(memoryReadFloat(proc, self.Address + addresses.camXUVec_offset), memerrmsg);
	self.YUVec = debugAssert(memoryReadFloat(proc, self.Address + addresses.camYUVec_offset), memerrmsg);
	self.ZUVec = debugAssert(memoryReadFloat(proc, self.Address + addresses.camZUVec_offset), memerrmsg);

	-- camera coordinates
	self.X = debugAssert(memoryReadFloat(proc, self.Address + addresses.camX_offset), memerrmsg);
	self.Y = debugAssert(memoryReadFloat(proc, self.Address + addresses.camY_offset), memerrmsg);
	self.Z = debugAssert(memoryReadFloat(proc, self.Address + addresses.camZ_offset), memerrmsg);

	-- camera focus coordinates
	self.XFocus = debugAssert(memoryReadFloat( proc, self.Address + addresses.camXFocus_offset), memerrmsg);
	self.ZFocus = debugAssert(memoryReadFloat( proc, self.Address + addresses.camZFocus_offset), memerrmsg);
	self.YFocus = debugAssert(memoryReadFloat( proc, self.Address + addresses.camYFocus_offset), memerrmsg);

	if( self.XUVec == nil or self.YUVec == nil or self.ZUVec == nil or
	self.X == nil or self.Y == nil or self.Z == nil or
	self.XFocus == nil or self.YFocus == nil or self.ZFocus == nil ) then
		error("Error reading memory in CCamera:update()");
	end
end

function CCamera:setPosition(x, y, z)
	local proc = getProc();

	self.XUVec = x;
	self.YUVec = y;
	--self.ZUVec = z;

	memoryWriteFloat(proc, self.Address + addresses.camXUVec_offset, x);
	memoryWriteFloat(proc, self.Address + addresses.camYUVec_offset, y);
	--memoryWriteFloat(proc, self.Address + addresses.camZUVec_offset, z);
end

function CCamera:setRotation(angle)
	local proc = getProc();
	self:update()

	local yangle = 0.35 -- About 20 degrees. Angle in radians from the horizontal. Can be changed.

	-- current camera distance
	local currentDistance = distance(self.XFocus,self.ZFocus,self.YFocus,self.X,self.Z,self.Y)

	-- y vector
	local playerYAngle = player.DirectionY
	if playerYAngle > 0.35 then
		playerYAngle = 0.35
	elseif playerYAngle < -0.35 then
		playerYAngle = -0.35
	end
	local vec3 = math.sin(yangle-playerYAngle) * currentDistance

	-- x and z vectors
	local hypotenuse = (currentDistance^2 - vec3^2)^.5
	local vec1 = math.cos(angle + math.pi) * hypotenuse;
	local vec2 = math.sin(angle + math.pi) * hypotenuse;

	-- new camera coordinates
	local nx = self.XFocus + vec1;
	local nz = self.ZFocus + vec2;
	local ny = self.YFocus + vec3;

	memoryWriteFloat(proc, self.Address + addresses.camX_offset, nx);
	memoryWriteFloat(proc, self.Address + addresses.camZ_offset, nz);
	memoryWriteFloat(proc, self.Address + addresses.camY_offset, ny);
end
