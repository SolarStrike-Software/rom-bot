local LOWEST_BRANCH = 0x6c; -- The lowest useful branch (real start is at 0)
local HIGHEST_BRANCH = 0x348; -- The highest branch
local BRANCH_OLD_SECONDS = 60; -- How long ago a branch was loaded before it is considered out-of-date
local INITIALIZE_ITEM_DELAY = 0.25; -- How much to wait when spamming the in-game command

local foundPredictedBranches		= {}; -- Branch predictions found at runtime
local foundPredictedBranchBlockSize = 1000;

local function idToBlock(id)
	return math.floor(id / foundPredictedBranchBlockSize)*foundPredictedBranchBlockSize;
end

local function addFoundPrediction(id, branch)
	local idBlock = idToBlock(id);
	cprintf(cli.purple, "Add prediction for block %d, branch 0x%X\n", idBlock, branch);
	if( foundPredictedBranches[idBlock] == nil ) then
		foundPredictedBranches[idBlock] = {};
	end
	
	table.insert(foundPredictedBranches[idBlock], branch);
end


CMemDatabase = class(function(self)
	self.database = {};
	self.loadedBranches = {};
	self.lastLoad = os.clock();
end);

-- Dump information about all available IDs into a CSV file
function CMemDatabase:dump(filename)
	-- We start at 0 to dump EVERYTHING instead of just
	-- starting at the "useful" range
	for i = 0,HIGHEST_BRANCH,4 do
		self:loadBranch(i);
	end

	local outFile = io.open(filename, 'w');
	
	if( outFile == nil ) then
		error("Unable to open file for writing. Is the file already open by another process and do you have write permission to this location?", 2);
	end
	
	outFile:write('"Branch ID","Address","Game ID","Max Stack","Req\'d Lvl","Name","Description",\n');
	for itemId,data in pairs(self.database) do
		local itemAddress = data.address;
		local itemName = data.name;
		local maxStack = memoryReadUInt(getProc(), itemAddress + 0x1C);
		local description = memoryReadStringPtr(getProc(), itemAddress + 0x24, 0);
		local reqdLvl = memoryReadUInt(getProc(), itemAddress + 0x58);	
		
		-- Just in case of nils
		itemName = itemName or "";
		description = description or "";
		
		-- Sanitize output
		itemName = itemName:gsub('"', '""');
		description = description:gsub('"', '""');
		
		outFile:write(sprintf("0x%04X,0x%X,%d,%d,%d,\"%s\",\"%s\"\n",
			data.branch, itemAddress, itemId, maxStack, reqdLvl, itemName, description));
	end
	outFile:close();
end

-- Loads information about a branch into our local DB
function CMemDatabase:loadBranch(branch)
	local base = getBaseAddress(addresses.memdatabase.base);
	local branchListAddress = memoryReadUIntPtr(getProc(), base, addresses.memdatabase.offset);
	local branchAddress = memoryReadUInt(getProc(), branchListAddress + branch);
	
	if( branchAddress ~= nil and branchAddress ~= 0 ) then
		for j = 0,addresses.memdatabase.branch.size,addresses.memdatabase.branch.info_size do
			local itemAddress = memoryReadUInt(getProc(), branchAddress + j + addresses.memdatabase.branch.itemset_address);
			
			if( itemAddress ~= nil and itemAddress ~= 0 ) then
				local itemId = memoryReadUInt(getProc(), itemAddress);
				if( itemId == nil or itemId <  50000 or itemId > 800000 ) then
				else
					local itemName = memoryReadStringPtr(getProc(), itemAddress + 0xC, 0);
					self.database[itemId] = {
						id		=	itemId,
						address	=	itemAddress,
						branch	=	branch,
						name	=	itemName,
					};
				end
			end
		end
	end
	
	-- Record when this branch was loaded
	self.loadedBranches[branch] = os.time();
end

-- Drop cached data
function CMemDatabase:flush()
	self.database = {};
	self.loadedBranches = {};
end

-- Checks if a branch is not loaded, or is "old"
function CMemDatabase:isBranchDirty(branch)
	-- Not loaded? Then it's dirty
	if( self.loadedBranches[branch] == nil ) then
		return true;
	end
	
	-- Too old? Then it's dirty.
	if( (os.time() - self.loadedBranches[branch]) > BRANCH_OLD_SECONDS ) then
		return true;
	end
	
	return false;
end

-- Attempts to locate the address for any given ID
function CMemDatabase:getAddress(id)
	-- Return immediately if we already know about this
	if( self.database[id] ~= nil ) then
		return self.database[id].address;
	end

	-- We slow down to avoid hitting the limit on the ingame api
	if (os.clock() - self.lastLoad < INITIALIZE_ITEM_DELAY) then
		while (os.clock() - self.lastLoad < INITIALIZE_ITEM_DELAY) do
			yrest(50);
		end
	end
	
	-- Update last loaded time
	self.lastLoad = os.clock();
	
	-- Try to force it to load
	SlashCommand("/script GetCraftRequestItem(".. id ..",-1)");
	
	-- Still no good? Try running through predicted branches
	-- based on our ID first.
	local predictedBranches = self:getPredictedBranches(id) or {};
	
	-- Merge predictions found at runtime
	local idBlock = idToBlock(id);
	for i,v in pairs((foundPredictedBranches[idBlock] or {})) do
		table.insert(predictedBranches, v);
	end
	
	for i,v in pairs(predictedBranches) do
		-- Load another branch, check to see if we found it
		self:loadBranch(v);
		if( self.database[id] ~= nil ) then
			return self.database[id].address;
		end
	end

	
	-- Still no good? We have no choice but to try running through them all.
	for i = LOWEST_BRANCH,HIGHEST_BRANCH,4 do
		-- Load another branch (if it is old), check to see if we found it
		if( self:isBranchDirty(i) ) then
			self:loadBranch(i);
			if( self.database[id] ~= nil ) then
				addFoundPrediction(id, i);
				return self.database[id].address;
			end
		end
	end
end

-- "Predicted branches" are branches that we expect
-- to find data about a given ID. They seem to be consistent
-- but may be subject to change.
-- For example, 200663 (Simple First Aid Potion) seems to 
-- always be in branch 0xF0
function CMemDatabase:getPredictedBranches(id)
	if( id >= 100000 and id < 110000 ) then
		return {0x1C4, 0x1C8, 0x2CC, 0x1D0, 0x1D4, 0x1D8,
			0x1DC, 0x1E0, 0x1E4, 0x1E8, 0x1EC};
	end
	
	if( id >= 110000 and id < 120000 ) then
		return {0x208, 0x20C, 0x210, 0x214, 0x218, 0x21C,
			0x220, 0x224, 0x228, 0x22C, 0x230};
	end

	if( id >= 120000 and id < 120900 ) then
		return {0x2C4, 0x2C8, 0x2CC, 0x2D0, 0x2D4, 0x2D8,
			0x2DC, 0x2E0, 0x2E4, 0x2E8, 0x2EC, 0x2F0, 0x2F4,
			0x2F8, 0x2FC, 0x300, 0x304, 0x308, 0x30C, 0x310,
			0x314, 0x318, 0x31C, 0x320, 0x324, 0x328, 0x32C,
			0x330, 0x334, 0x338, 0x33C, 0x340, 0x344, 0x348,
			0x230};
	end
	
	if( id >= 120900 and id < 130000 ) then
		return {0x234, 0x238, 0x23C, 0x240, 0x244, 0x2A8,
			0x2AC, 0x2B0, 0x2B4, 0x2B8, 0x2C0};
	end
	
	if( id >= 130000 and id < 140000 ) then
		return {0x1EC};
	end

	if( id >= 200000 and id < 210000 ) then
		return {0xF0, 0xF4, 0xF8, 0xFC,
			0x100, 0x104, 0x108, 0x10C, 0x110, 0x114,
			0x294};
	end
	
	if( id >= 210000 and id < 215000 ) then
		return {0x84, 0x28C, 0x290, 0x294, 0x298, 0x29C, 0x2A0, 0x2A4, 0x2A8, 0x2AC};
	end
	
	if( id >= 215000 and id < 220000 ) then
		return {0x2A4};
	end
	
	if( id >= 220000 and id < 230000 ) then
		return {0x7C, 0x80, 0x84, 0x88, 0x8C,
			0x90, 0x94, 0x98, 0x9C,
			0xA0, 0xA4, 0xA8, 0xAC};
	end
	
	if( id >= 230000 and id < 240000 ) then
		return {0xA8, 0xAC, 0xB4, 0xB8, 0xBC, 0xC0, 0xC4, 0xC8, 0xCC};
	end
	
	if( id >= 240000 and id < 245000) then
		return {0x110, 0x114, 0x118, 0x11C, 0x120, 0x124, 0x128, 0x12C};
	end
	
	-- Seems to be all quests
	if( id >= 420000 and id < 430000 ) then
		return {0x1EC, 0x1F0, 0x1F4, 0x1F8, 0x1FC, 0x200, 0x204, 0x208};
	end
	
	-- Skills
	if( id >= 490000 and id < 510000 ) then
		return {0x150, 0x154, 0x158, 0x15C,
			0x160, 0x164, 0x168, 0x16C,
			0x170, 0x174, 0x178, 0x17C,
			0x180, 0x184, 0x188, 0x18C,
			0x190, 0x194, 0x198, 0x19C,
			0x1A0, 0x1A4, 0x1A8, 0x1AC,
			0x1B0, 0x1B4, 0x1B8, 0x1BC};
	end
	
	-- Runes
	if( id >= 510000 and id < 520000 ) then
		return {0x60, 0x64, 0x68, 0x6C, 0x70, 0x74, 0x78, 0x7C, 0x80};
	end
	
	if( id >= 520000 and id < 540000 ) then
		return {0x254, 0x258, 0x25C, 0x260, 0x264};
	end
	
	-- Skills, ie. Attack, Recall, etc.
	if( id >= 540000 and id < 550000 ) then
		return {0x124, 0x128, 0x130, 0x134, 0x138, 0x13C, 0x144, 0x148};
	end
	
	-- Recipes
	if( id >= 550000 and id < 560000 ) then
		return {0x248, 0x24C};
	end
	
	-- Harvestables
	if( id >= 560000 and id < 570000 ) then
		return {0x1C0, 0x1C4};
	end
	
	if( id >= 570000 and id < 600000 ) then
		return {0x0, 0x4, 0x8, 0xC, 0x10, 0x14, 0x18, 0x20, 0x28};
	end
	
	-- Buffs & debuffs
	if( id >= 620000 and id < 630000 ) then
		return {0x178, 0x180, 0x184, 0x188, 0x18C};
	end
end


MemDatabase = CMemDatabase();