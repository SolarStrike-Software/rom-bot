local CACHE_PATH = getExecutionPath() .. "/../cache";

function LoadItemTypes()
	itemtypes = nil

	local fname = CACHE_PATH .. "/itemtypestable.lua";
	if( fileExists(fname) ) then
		LoadItemTypes_cached(fname)
		if itemtypes_language == string.sub(RoMScript("GetLanguage()"),1,2) then
			-- data good
			return
		else
			printf("Client Language changed.\n")
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
	--local starttime = os.clock()

	cprintf(cli.yellow,"Getting item type names.\n")

	local data={}

	-- Get Base type level data
	local t1_data={RoMScript("} A=0 repeat n='AC_ITEMTYPENAME_'..A T=TEXT(n)" ..
		" if n==T then break end table.insert(a,A..','..T) A=A+1 until false z={")}
	for k,v in pairs(t1_data) do
		local t1, name = string.match(v,"(%d*),(.*)")
		t1 = tonumber(t1)
		data[t1] = {Name = name}
	end

	displayProgressBar((1/(#data+3)) * 100, 20);

	-- Get second level data
	local t2_data={RoMScript("} for A=0,".. #data .." do B=0 repeat " ..
		"n='AC_ITEMTYPENAME_'..A..'_'..B T=TEXT(n) if n==T then break end " ..
		"table.insert(a,A..','..B..','..T) B=B+1 until false end z={")}
	for k,v in pairs(t2_data) do
		local t1, t2, name = string.match(v,"(%d*),(%d*),(.*)")
		t1, t2 = tonumber(t1), tonumber(t2)
		data[t1][t2] = {Name = name}
	end

	-- Get third level data
	for t1= 0, #data do
		displayProgressBar(((t1+2)/(#data+3)) * 100, 20);
		local t3_data = {RoMScript("} for B=0," .. #data[t1] .. " do C=0 repeat " ..
			"n='AC_ITEMTYPENAME_"..t1.."_'..B..'_'..C T=TEXT(n) if n==T then break end " ..
			"table.insert(a,B..','..C..','..T) C=C+1 until false end z={")}
		for k,v in pairs(t3_data) do
			local t2, t3, name = string.match(v,"(%d*),(%d*),(.*)")
			t2, t3 = tonumber(t2), tonumber(t3)
			data[t1][t2][t3] = {Name = name}
			if (t1 == 0 and t2 >= 0 and t2 <= 4) or -- non unique t3 weapon name
				(t1 == 1 and t2 >= 0 and t2 <= 3) then -- non unique t3 armor name
				-- Add the t2 name to make a unique name
				data[t1][t2][t3].Name = data[t1][t2][t3].Name .. " " .. data[t1][t2].Name
			end
		end
	end

	-- Get exceptions
	-- Exceptions:
	data[3][5] = {Name = RoMScript("TEXT(\"SYS_ITEMTYPE_14\")")} -- Prepared Materials

	displayProgressBar(100, 20);

	printf("\n")

	itemtypes =  data

	itemtypes_language = string.sub(RoMScript("GetLanguage()"),1,2)
	--print("time",os.clock() - starttime)
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
						outFile:write("\t\t\t["..i.."] = { Name = \""..v.Name.."\" },\n")
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
