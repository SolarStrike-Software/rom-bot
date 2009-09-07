-- A little class

CItem = class(
	function(self)
		self.Id = 0;
		self.BagId = 0;
    	self.Name = "Empty";
    	self.ItemCount = 0;
    	self.Color = "ffffff";
	end
)

function CItem:use()
	RoMScript("UseBagItem("..self.BagId..");");
	
	-- Set the default values since our item does not exist anymore.
	if self.ItemCount <= 0 then
		self = CItem();
	end
end

function CItem:delete()
    RoMScript("PickupBagItem("..self.BagId..");");
	RoMScript("DeleteCursorItem();");
	
	-- Set the default values since our item is deleted.
	self = CItem();
end 

function CItem:__tonumber()
	return self.Id;
end