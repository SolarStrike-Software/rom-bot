CCamera = class(
	function(self, ptr)
		self.Address = ptr;
		self.XUVec = 0.0;
		self.YUVec = 0.0;
		self.ZUVec = 0.0;

		self.X = 0;
		self.Y = 0;
		self.Z = 0;

		printf("self.Address: 0x%X\n", ptr);

		if( self.Address ) then
			self:update();
		end
	end
);

function CCamera:update()
	local proc = getProc();
	local memerrmsg = "Failed to read memory";

	self.XUVec = debugAssert(memoryReadFloat(proc, self.Address + camXUVec_offset), memerrmsg);
	self.YUVec = debugAssert(memoryReadFloat(proc, self.Address + camYUVec_offset), memerrmsg);
	self.ZUVec = debugAssert(memoryReadFloat(proc, self.Address + camZUVec_offset), memerrmsg);

	self.X = debugAssert(memoryReadFloat(proc, self.Address + camX_offset), memerrmsg);
	self.Y = debugAssert(memoryReadFloat(proc, self.Address + camY_offset), memerrmsg);
	self.Z = debugAssert(memoryReadFloat(proc, self.Address + camZ_offset), memerrmsg);

	printf("X: %0.2f, Y: %0.2f, Z: %0.2f\n", self.X, self.Y, self.Z);
	printf("XU: %0.2f, YU: %0.2f, ZU: %0.2f\n", self.XUVec, self.YUVec, self.ZUVec);

	if( self.XUVec == nil or self.YUVec == nil or self.ZUVec == nil or
	self.X == nil or self.Y == nil or self.Z == nil ) then
		error("Error reading memory in CCamera:update()");
	end
end

function CCamera:setPosition(x, y, z)
	local proc = getProc();
	
	self.XUVec = x;
	self.YUVec = y;
	--self.ZUVec = z;

	memoryWriteFloat(proc, self.Address + camXUVec_offset, x);
	memoryWriteFloat(proc, self.Address + camYUVec_offset, y);
	--memoryWriteFloat(proc, self.Address + camZUVec_offset, z);
end

function CCamera:setRotation(angle)
	local proc = getProc();
	local maxViewDistance = 125; -- Hard value set by the game
	local px = player.X;
	local pz = player.Z;
	local nx = px + math.cos(angle + math.pi) * maxViewDistance;
	local nz = pz + math.sin(angle + math.pi) * maxViewDistance;

	memoryWriteFloat(proc, self.Address + camX_offset, nx);
	memoryWriteFloat(proc, self.Address + camZ_offset, nz);
end
