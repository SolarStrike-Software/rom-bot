include("object.lua");
OBJ_LIST_SIZE = 200;

CObjectList = class(
	function (self)
		self.Address = addresses.staticTablePtr;
		self.Objects = {};
	end
);

function CObjectList:update()
	for i = 0,OBJ_LIST_SIZE - 1 do
		local addr = memoryReadIntPtr(getProc(), self.Address, i*4);
		self.Objects[i] = CObject(addr);
	end
end

function CObjectList:getObject(index)
	if( index < 0 or index >= OBJ_LIST_SIZE ) then
		error("Call to CObjectList:getObject failed: index out of bounds", 2);
	end

	return self.Objects[index];
end