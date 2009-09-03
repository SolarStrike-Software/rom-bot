-- A little class

CItem = class(
	function(self)
		self.Id = 0;
		self.BagId = 0;
    	self.Name = "";
    	self.ItemCount = 0;
    	self.Color = "ffffff";
	end
)

function CItem:use()
	RoMScript("UseBagItem("..self.BagId..");");
	self.ItemCount = self.ItemCount - 1;
end

function CItem:delete()
    RoMScript("PickupBagItem("..self.BagId..");");
	RoMScript("DeleteCursorItem();");
	
	-- Set the default values since our item is deleted.
	self.Id = 0;
	self.BagId = 0;
    self.Name = "";
    self.ItemCount = 0;
    self.Color = "ffffff";
end

function CItem:__tostring()
	if self.Id then
	    return self.Id;
	else
	    return false;
	end
end