local LOWEST_BRANCH = 0x6c; -- The lowest useful branch (real start is at 0)
local HIGHEST_BRANCH = 0x348; -- The highest branch
local BRANCH_OLD_SECONDS = 60; -- How long ago a branch was loaded before it is considered out-of-date
local INITIALIZE_ITEM_DELAY = 1/60.0; -- How much to wait when spamming the in-game command

local foundPredictedBranches		= {}; -- Branch predictions found at runtime
local foundPredictedBranchBlockSize = 1000;

local function idToBlock(id)
	return math.floor(id / foundPredictedBranchBlockSize)*foundPredictedBranchBlockSize;
end

local cacheFile = getExecutionPath() .. "/../cache/branch_predictions.lua";
local timerName = 'save_predicted_branch_cache';
local function saveCache()
	unregisterTimer(timerName); -- We only need this to trigger once after a prediction was added
	
	local file = io.open(cacheFile, 'w');
	file:write("return {\n");
	for i,v in pairs(foundPredictedBranches) do
		local tabUnpacked = "";
		for j,k in pairs(v) do
			if( #tabUnpacked > 0 ) then
				tabUnpacked = tabUnpacked .. ", ";
			end
			tabUnpacked = tabUnpacked .. sprintf("0x%x", tonumber(k));
		end
		file:write(sprintf("\t[%d] = {%s},\n", i, tabUnpacked));
	end
	file:write("}\n");
	file:close();
end

local function loadCache()
	if( fileExists(cacheFile) ) then
		foundPredictedBranches = include(cacheFile, true);
	else
		foundPredictedBranches = {};
	end
end

local function addFoundPrediction(id, branch)
	local idBlock = idToBlock(id);
	cprintf(cli.purple, "Add prediction for block %d, branch 0x%X\n", idBlock, branch);
	if( foundPredictedBranches[idBlock] == nil ) then
		foundPredictedBranches[idBlock] = {};
	end
	
	table.insert(foundPredictedBranches[idBlock], branch);
	
	registerTimer(timerName, 10000, saveCache);
end


CMemDatabase = class(function(self)
	self.database = {};
	self.loadedBranches = {};
	self.lastLoad = os.clock();
	self.loadedIds = {};
	
	loadCache();
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
	local branchListAddress = memoryReadRepeat("uintptr", getProc(), base, addresses.memdatabase.offset);
	
	if( branchListAddress == nil ) then
		return;
	end
	
	local branchAddress = memoryReadRepeat("uint", getProc(), branchListAddress + branch);
	if( branchAddress ~= nil and branchAddress ~= 0 and branchAddress ~= 0xFFFFFFFF ) then
		for j = 0,addresses.memdatabase.branch.size do
			local branchItemOffset = j * addresses.memdatabase.branch.info_size
			local itemsetId = memoryReadUInt(getProc(), branchAddress + branchItemOffset + addresses.memdatabase.branch.itemset_id);
			
			-- If the itemsetId we read from the branch matches 'j' (the offset from start of branch)
			-- then it is probably correct. If not, then we ignore it entirely!
			if( itemsetId == j ) then
				local itemAddress = memoryReadUInt(getProc(), branchAddress + branchItemOffset + addresses.memdatabase.branch.itemset_address);
			
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
	end
	
	-- Record when this branch was loaded
	self.loadedBranches[branch] = os.time();
end

-- Drop cached data
function CMemDatabase:flush()
	self.database = {};
	self.loadedBranches = {};
	self.loadedIds = {};
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

function CMemDatabase:forceLoad(id)
	if( commandMacro == 0 ) then
		local res = SlashCommand("/script GetCraftRequestItem(".. id ..",-1);GetItemLink(" .. id .. ")");
		yrest(50); -- Small delay to make sure the game has had time to process the command
	else
		RoMScript("GetCraftRequestItem(".. id ..",-1);GetItemQuality(" .. id .. ")");
	end
	self.loadedIds[id] = res;
end

function CMemDatabase:forceLoadSkills()
	SlashCommand("/script for t=2,4 do for i=1,35 do if(GetSkillDetail(t,i)==nil) then break end end end");
	
	for name,skill in pairs(database.skills) do
		self.loadedIds[skill.Id] = true;
	end
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
	if( (id >= 200000 and id < 240000)
		or (id >= 490000 and id < 640000) )
	then
		if( self.loadedIds[id] == nil ) then
			self:forceLoad(id);
		end
	end
	
	-- Still no good? Try running through predicted branches
	local predictedBranches = {};
	
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


MemDatabase = CMemDatabase();