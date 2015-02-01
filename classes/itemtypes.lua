local CACHE_PATH = getExecutionPath() .. "/../cache";
local ITEMTYPESTABLE_VERSION = 1.0 -- Change if the saved format changes to force an update of the file.

function LoadItemTypes()
	itemtypes = nil

	local fname = CACHE_PATH .. "/itemtypestable.lua";
	if( fileExists(fname) ) then
		LoadItemTypes_cached(fname)
		if itemtypes_language ~= string.sub(RoMScript("GetLanguage()"),1,2) then
			printf("Client Language changed.\n")
		elseif itemtypes_version ~= ITEMTYPESTABLE_VERSION	then
			printf("itemtypestable is incorrect version.\n")
		else
			-- Data good
			return
		end
	end

	LoadItemTypes_memory()
	CacheItemTypes();
end

function LoadItemTypes_cached(filename)
	local status, err = pcall(dofile, filename);

	if( not status ) then
		-- Failed to load the cache file.
		cprintf(cli.red, "[DEBUG] Failed to load item types cache file; Dropping bad file.\n");

		LoadItemTypes_memory();
		CacheItemTypes();
	end
end

function LoadItemTypes_memory()
--	local starttime = getTime()

	cprintf(cli.yellow,"Getting item type names.\n")

	local data={}

	local addressPtrsBase = memoryReadInt(getProc(), addresses.getTEXT)
	local address = memoryReadInt(getProc(), addressPtrsBase + 0x268)
	-- Search for first type
	address = findPatternInProcess(getProc(),"AC_ITEMTYPENAME","xxxxxxxxxxxxxxx",address,address+0x10000)
	repeat
		local key = memoryReadString(getProc(), address)
		address = address + #key + 1
		local text = memoryReadString(getProc(), address)
		address = address + #text +1

		local A, B, C = string.match(key,"AC_ITEMTYPENAME_(%d*)_?(%d*)_?(%d*)")
		A, B, C = tonumber(A), tonumber(B), tonumber(C)
		if C then
			data[A][B][C] ={Name = text}
			if (A == 0 and B >= 0 and B <= 4) or -- non unique t3 weapon name
				(A == 1 and B >= 0 and B <= 3) then -- non unique t3 armor name
				-- Add the t2 name to make a unique name
				data[A][B][C].UniqueName = data[A][B][C].Name .. " " .. data[A][B].Name
			end
		elseif B then
			data[A][B] = {Name = text}
		elseif A then
			data[A] = {Name = text}
		end
	until A == nil

	-- Get exceptions
	-- Exceptions:
	data[3][5] = {Name = getTEXT("SYS_ITEMTYPE_14")} -- Prepared Materials

	printf("\n")

	itemtypes =  data

	itemtypes_language = string.sub(RoMScript("GetLanguage()"),1,2)
--	print("time",deltaTime(getTime(), starttime))
end

function CacheItemTypes()
 	local outFile = io.open(CACHE_PATH .. "/itemtypestable.lua", "w");

	if( not outFile ) then
		return;
	end

	outFile:write("itemtypes = {\n");
	for i,v in pairs(itemtypes) do
		outFile:write("\t["..i.."] = { Name = \""..v.Name.."\"")

		local havesub = false
		for i,v in pairs(v) do
			if i ~= "Name" then
				if havesub == false then
					havesub = true
					outFile:write(",\n")
				end

				outFile:write("\t\t["..i.."] = { Name = \""..v.Name.."\"")

				local havesubsub = false
				for i,v in pairs(v) do
					if i ~= "Name" then
						if havesubsub == false then
							havesubsub = true
							outFile:write(",\n")
						end
						outFile:write("\t\t\t["..i.."] = { Name = \""..v.Name.."\"")
						if v.UniqueName then
							outFile:write(", UniqueName = \""..v.UniqueName.."\"")
						end
						outFile:write(" },\n")
					end
				end

				if havesubsub then
					outFile:write("\t\t},\n")
				else
					outFile:write(" },\n")
				end
			end
		end

		if havesub then
			outFile:write("\t},\n")
		else
			outFile:write(" },\n")
		end
	end

	outFile:write("}\n");

	outFile:write("itemtypes_language = \"" .. itemtypes_language .. "\"\n")
	outFile:write("itemtypes_version = " .. ITEMTYPESTABLE_VERSION .. "\n")
	outFile:close()
end

function PrintItemTypes()
	for k,v in pairs(itemtypes) do
		if k~="Name" then
			print(k,v.Name)
			for k,v in pairs(v) do
				if k~="Name" then
					print("",k,v.Name)
					for k,v in pairs(v) do
						if k~="Name" then
							print("","",k,v.Name)
						end
					end
				end
			end
		end
	end
end
