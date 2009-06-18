NTYPE_WOOD = 1
NTYPE_ORE = 2
NTYPE_HERB = 3


CNode = class(
	function(self, copyfrom)
		self.Name = "<NODE>";
		self.Id = 0;
		self.Type = NTYPE_WOOD;

		if( type(copyfrom) == "table" ) then
			self.Name = copyfrom.Name;
			self.Id = copyfrom.Id;
			self.Type = copyfrom.Type;
		end
	end
);