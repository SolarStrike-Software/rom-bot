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

	if( settings.profile.options.DEBUG_INV) then	
		cprintf(cli.lightblue, "DEBUG - UseBagItem: %s\n", self.BagId );				-- Open/eqipt item:
	end;

	self.ItemCount = self.ItemCount - 1;	-- reduce quantity in by 1
-- TODO: only a fix for using potions / have to be checked for items like mounts
-- which will not be 0 after using

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