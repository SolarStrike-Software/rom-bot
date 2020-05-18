include("object.lua");

CObjectList = class(
	function (self)
		self.Objects = {};
	end
);

function CObjectList:update()
	self.Objects = {}; -- Flush all objects.
	local size = memoryReadInt(getProc(), getBaseAddress(addresses.object_list.size));
	local start = memoryReadUInt(getProc(), getBaseAddress(addresses.object_list.base));

	for i = 0,size do
		local addr = memoryReadUInt(getProc(), start + i*4);
		if( addr and addr > 0) then
			local newObj = CObject(addr);
			--printf("object found at 0x%X - %s\n", addr, newObj.Name);
			self.Objects[i] = newObj;
		end
	end
end

function CObjectList:getObject(index)
	if( index < 0 or index > #self.Objects ) then
		error("Call to CObjectList:getObject failed: index out of bounds", 2);
	end

	return self.Objects[index];
end

function CObjectList:size()
	return #self.Objects;
end
