local exeName = "Client.exe";
local exeStartAddress = 0x400000;

print("\201================================ [ NOTICE ] =================================\187");
print("\186     This script is still in development.                                    \186");
print("\186     You probably don't actually want to use this for now.                   \186");
print("\200" .. string.rep("=", 77) .. "\188\n\n");

-- Attempt to read install location from registry
function getAutoClientPath()
	local regQuery = 'reg query "HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\{dd7f99fe-264a-4259-8ef0-da6d482e2b76}" /v InstallLocation';
	local response = io.popen(regQuery):read('*a');
	local pattern = "InstallLocation%s+REG_SZ%s+([^\n]+)";
	local parsed = string.match(response, pattern);
	
	if( parsed == nil ) then
		return nil;
	end
	
	return appendSlashesIfNeeded(parsed);
end

-- Ask the user to select the file manually
function getSelectClientPath()
	local exePath = getOpenFileName("", "Runes of Magic .exe\0" .. exeName .. "\0\0");
	return exePath;
end

-- If the path does not end on a slash, add one.
function appendSlashesIfNeeded(str)
	if( not str:find(".*([\\/])$") ) then
		str = str .. "\\";
	end
	return str;
end


function getClientHandle()
	local exePath = getAutoClientPath();
	local fullPath = "";
	
	if( not exePath or not fileExists(exePath .. exeName) ) then
		printf("\aPlease select the Runes of Magic %s\n", exeName);
		rest(1000);
		fullPath = fixSlashes(getSelectClientPath(), false);
		exePath = appendSlashesIfNeeded(getFilePath(fullPath));
	else
		fullPath = exePath .. exeName;
	end
	
	if( not fileExists(fullPath) ) then
		error("Could not locate Runes of Magic client");
	end
	
	local handle = io.open(fullPath, 'rb');
	return handle;
end


handle = getClientHandle();
if( not handle ) then
	error("Could not open Runes of Magic client for reading");
end
print("Opened ROM client successfully...");


fileContents = handle:read("*a");
handle:close();

printf("File size: %d bytes\n", #fileContents);

-- Convert an "array" of bytes into a raw string for
-- pattern matching
-- Example: byteArrayToPattern("41 42 43 ?? ");
function byteArrayToPattern(bytes)
	local str = "";
	
	-- Note: The value is just here for info purposes;
	-- It just needs to be non-false, so I'm setting it
	-- to the string representation so you can easily tell
	-- what each hexcode represents.
	local escapeNeeded = {
		["25"] = "%",
		["5B"] = "[",
		["2A"] = "*", 
		["2B"] = "+",
		["2D"] = "-",
		["2E"] = ".",
		["40"] = "(",
		["41"] = ")",
	};
	
	for match in bytes:gmatch("([%x?][%x?])%s*") do
		if( match == "??" ) then
			-- Match anything
			str = str .. ".";
		elseif( escapeNeeded[match] ) then
			-- Escape character %; we need to double escape it
			str = str .. "%" .. string.char(tonumber("0x"..match));
		else
			-- Match exact
			local chr = string.char(tonumber("0x"..match));
			str = str .. chr;
		end
	end
	return str;
end

function findPattern(pattern)
	local found = fileContents:find(pattern);
	if( found ) then
		found = found - 1;
	end
	
	return found;
end

function getInt(loc, bytes)
	bytes = bytes or 4;
	local result = 0;
	
	for i = 1,bytes do
		local byte = string.byte(fileContents:sub(loc + i, loc + i + 1));
		if( i > 1 ) then
			result = result + byte * 256^(i-1);
		else
			result = result + byte;
		end
	end
	
	return tonumber(result);
end


--[[
	value_offset	How many bytes offset from the found location that contains the value we want
	value_size		The size (in bytes) of the value we want to read
	value_raw		True = use read value as is, false = subtract Client.exe start address
	value_type		"address" (Use found location) or "default" (use value read from location)
	pattern			String pattern representing data to find
]]
local updatables = {
	game_root_base = {
		value_offset = 0x2,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			8B 0D ?? ?? ?? ??
			8B 01
			8B 90 ?? ?? ?? ??
			81 EC B0 00 00 00
			53
			55
			56
			57
			FF D2
			8B B4 24 ?? ?? ?? ??
			8B 0D ?? ?? ?? ??
			56
			8B D8
			E8 ?? ?? ?? ??
			8B F8
			85 FF
			75 24
			A1 ?? ?? ?? ??
			8B ??
			8B 51 ??
			56
			68 ?? ?? ?? ??
			57
			50
			FF D2
			83 C4 10
			5F
			5E
			5D
			5B
			81 C4 B0 00 00 00
			C2 18 00
			]])
	},
	
	player_base = {
		value_offset = 0x46,
		value_size = 4,
		value_raw = true,
		pattern = byteArrayToPattern([[
			53
			55
			56
			57
			8B 7C 24 14
			85 FF
			8B F1
			0F 84 ?? ?? ?? ??
			8B C7
			8D 50 01
			8A 08
			83 C0 01
			84 C9
			75 F7
			8B 1D ?? ?? ?? ??
			6A 06
			2B C2
			8B E8
			68 ?? ?? ?? ??
			57
			89 6C 24 20
			FF D3
			83 C4 0C
			85 C0
			75 30
			83 FD 06
			75 0D
			8B 86 ?? ?? ?? ??
			5F
			5E
			5D
			5B
			C2 08 00
			8B 8E ?? ?? ?? ??
			8B 06
		]])
	},
	
	zone_id = {
		value_offset = 0x42,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			8B 44 24 1C
			53
			56
			8B 74 24 10
			A3 ?? ?? ?? ??
			B8 ?? ?? ?? ??
			F7 EE
			C1 FA 06
			8B CA
			C1 E9 1F
			03 CA
			BA ?? ?? ?? ??
			2B D1
			8B 0D ?? ?? ?? ??
			69 D2 ?? ?? ?? ??
			57
			03 D6
			52
			E8 ?? ?? ?? ??
			8B F8
			85 FF
			89 35 ?? ?? ?? ??
			74 17
		]])
	},
	
	class_info_base = {
		value_offset = 0x40,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			A1 ?? ?? ?? ??
			56
			8B 74 24 08
			83 EC 08
			85 C0
			7D 0F
			D9 EE
			DD 1C 24
			56
			E8 ?? ?? ?? ??
			D9 EE
			EB 2E
			8B 0D ?? ?? ?? ??
			69 C0 ?? ?? ?? ??
			DB 44 08 20
			DD 1C 24
			56
			E8 ?? ?? ?? ??
			8B 15 ?? ?? ?? ??
			A1 ?? ?? ?? ??
			69 D2
		]])
	},
	
	freeze_target_codemod = {
		value_offset = 0x11,
		value_size = 4,
		value_raw = false,
		value_type = "address",
		pattern = byteArrayToPattern([[
		8B 44 24 04
		56
		8B F1
		8B 96 ?? ?? ?? ??
		3B D0
		74 35
		89 86 ?? ?? ?? ??
		8B 0D ?? ?? ?? ??
		85 C9
		74 0A
		52
		50
		6A 0D
		56
		FF D1
		83 C4 10
		83 BE ?? ?? ?? ?? 00
		75 12
		]])
	},
};

function findGameRoot()
	if( found ) then
		local bytes = getInt(found +2, 4) - exeStartAddress;
		printf("Found game root: 0x%X\n", bytes);
	end
end

local foundUpdates = {};
local missingUpdates = 0;
for i,v in pairs(updatables) do
	local found = findPattern(v.pattern);
	if( found ) then
		local val = nil;
		if( v.value_type == "address" ) then
			val = found + (v.value_offset or 0);
		else
			val = getInt(found + (v.value_offset or 0), (v.value_size or 4));
			if( not v.value_raw ) then
				-- If this is supposed to be an offset from client.exe, subtract it.
				val = val - exeStartAddress;
				if( val < 0 ) then
					error(sprintf("\n{%s} has value_raw=true, but final result was negitive; are you sure that's right?", i));
				end
			end
		end
	
		cprintf_ex("|green|Found pattern for |pink|{%s}|green| at |yellow|0x%X|green|, new value: |yellow|0x%X\n",
		i, found + v.value_offset, val);
		foundUpdates[i] = val;
	else
		cprintf(cli.red, "Could not find pattern for {%s}\n", i);
		missingUpdates = missingUpdates + 1;
	end
end

function save(filename, backup)
	backup = backup or true;
	
	local handle = io.open(getExecutionPath() .. '/' .. filename, 'r');
	if( not handle ) then
		error("Could not open " .. filename .. " for reading.");
	end
	
	local addressFile = handle:read('*a');
	
	if( backup ) then
		local backupFilename = 'backup-' .. filename;
		printf("Backuping up to %s\n", backupFilename);
		
		local outhandle = io.open(getExecutionPath() .. '/' .. backupFilename, 'w');
		outhandle:write(addressFile);
		outhandle:close();
	end
	
	-- Do replacements as requested
	printf("Replacing addresses...\n");
	for key,value in pairs(foundUpdates) do
		local hexValue = sprintf("0x%x", value);
		local changed = string.gsub(addressFile,
			"(.*)=(%s*)([x%x]+)([%,%s]*)%-%-%[%[(.*){" .. key .. "}(%s*)%]%]([^\n]*)",
			"%1=%2" .. hexValue .. "%4--[[%5{" .. key .. "}%6]]%7");
		
		if( changed ~= addressFile ) then
			cprintf_ex("|green|[+]|white| Successfully patched |pink|{%s}\n", key);
			addressFile = changed;
		else
			if( addressFile:find("%-%-%[%[%s*{" .. key .. "}%s*%]%]") ) then
				cprintf_ex("|yellow|[!]|white| Failed to patch |pink|{%s}|white| or already valid.\n", key);
			else
				cprintf_ex("|lightred|[-]|white| Failed to patch |pink|{%s}|white| (token not found in file)\n", key);
			end
		end
	end
	
	printf("Writing new addresses to %s\n", filename);
	local newHandle = io.open(getExecutionPath() .. "/" .. filename, 'w');
	newHandle:write(addressFile);
end

local continue = true;
if( missingUpdates > 0 ) then
	cprintf_ex([[
\n\n
|yellow|Not all updatable addresses could be found.\n
Do you want to continue and update found information? |white|y/n:
]]);
	while(true) do
		local inp = string.lower(io.read('1'));
		if( inp ~= 'y' and inp ~= 'n' ) then
			printf("Not a valid option. Select (y)es or (n)o:");
		else
			if( inp == 'y' ) then
				continue = true;
			else
				continue = false;
			end
			
			break;
		end
	end
end


if( continue ) then
	save('addresses.lua', true);
end