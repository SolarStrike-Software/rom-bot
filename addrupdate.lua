local exeName = "Client.exe";
local exeStartAddress = 0x400000;

print("\201================================ [ NOTICE ] =================================\187");
print("\186     This script is still in development.                                    \186");
print("\186     Use at your own risk                                                    \186");
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

	for match in bytes:gmatch("([%x?][%x?])%s*") do
		if( match == "??" ) then
			-- Match anything
			str = str .. ".";
		else
			-- Match exact
			local chr = string.char(tonumber("0x"..match));

			if( string.find(chr, "[^a-zA-Z0-9]") ) then
				-- escape it
				chr = "%" .. chr;
			end

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
	partners		Table of extra addresses to update based on the found result of this pattern
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
			]]),
		partners = {
			crafting_base = {
				add_value = 0x1578; -- Assumed; not referenced in code
			},
		},
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

	freeze_mousepos_codemod = {
		value_offset = 0x1F,
		value_size = 4,
		value_raw = false,
		value_type = "address",
		pattern = byteArrayToPattern([[
		51
		52
		8B CE
		E8 ?? ?? ?? ??
		5F
		5E
		5D
		33 C0
		5B
		C2 10 00
		8B C5
		8B C8
		81 E1 FF FF 00 00
		C1 F8 10
		89 8E ?? ?? ?? ??
		89 86 ?? ?? ?? ??
		5F
		5E
		5D
		33 C0
		5B
		C2 10 00
		83 FB 79
		0F 84 ?? ?? ?? ??
		F7 C5 00 00 00 20
		]])
	},

	freeze_mousepos2_codemod = {
		value_offset = 0x5F,
		value_size = 4,
		value_raw = false,
		value_type = "address",
		pattern = byteArrayToPattern([[
		83 C4 0C
		80 7E ?? 00
		74 5C
		8D 4C 24 08
		51
		FF 15 ?? ?? ?? ??
		8B 46 ??
		8D 54 24 ??
		52
		50
		FF 15 ?? ?? ?? ??
		8B 4C 24 ??
		85 C9
		7D 0C
		C7 86 ?? ?? ?? ?? ?? ?? ?? ??
		EB 0D
		8B 46 ??
		3B C8
		7E 06
		89 86 ?? ?? ?? ??
		8B 4C ?? ??
		85 C9
		7D 0C
		C7 86 ?? ?? ?? ?? ?? ?? ?? ??
		EB 0D
		8B 46 ??
		3B C8
		7E 06
		89 86 ?? ?? ?? ??
		DB 86 ?? ?? ?? ??
		8B 4E ??
		85 C9
		]])
	},

	swimhack_codemod = {
		value_offset = 0x36,
		value_size = 4,
		value_raw = false,
		value_type = "address",
		pattern = byteArrayToPattern([[
		50
		8D 54 24 ??
		D9 5C 24 ??
		D9 83 ?? ?? ?? ??
		D8 87 ?? ?? ?? ??
		D9 5C 24 ??
		D9 83 ?? ?? ?? ??
		D8 87 ?? ?? ?? ??
		D9 5C 24 ??
		E8 ?? ?? ?? ??
		85 C0
		0F 85 ?? ?? ?? ??
		C7 83 ?? ?? ?? ?? ?? ?? ?? ??
		C7 83 ?? ?? ?? ?? ?? ?? ?? ??
		89 83 ?? ?? ?? ??
		E9 ?? ?? ?? ??
		8D 8B ?? ?? ?? ??
		C7 44 24 ?? 01 00 00 00
		]])
	},

	exp_table = {
		value_offset = 0x20,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			8B 44 24 ??
			83 F8 FF
			75 05
			33 C0
			C2 04 00
			8B 89 ?? ?? ?? ??
			69 C0 ?? ?? ?? ??
			8B 44 01 ??
			8B 0D ?? ?? ?? ??
			85 C9
			56
			8B 35 ?? ?? ?? ??
			75 04
		]])
	},

	psi = {
		value_offset = 0x23,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			56
			FF D2
			8B F0
			85 F6
			C7 44 24 ?? FF FF FF FF
			C7 44 24 ?? 00 00 00 00
			74 66
			83 BE ?? ?? ?? ?? 09
			75 5D
			A1 ?? ?? ?? ??
			57
			8B CE
			89 44 24 ??
			33 FF
			E8 ?? ?? ?? ??
			85 C0
			7E 45
			8D 9B 00 00 00 00
			57
			8B CE
		]]),
	},

	actionbar_base = {
		value_offset = 0x0F,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			56
			8B 74 24 08
			6A 01
			56
			E8 ?? ?? ?? ??
			8B 0D ?? ?? ?? ??
			83 C4 08
			83 E8 01
			50
			E8 ?? ?? ?? ??
			8B D0
			85 D2
			B0 01
			74 78
			8B 0A
			83 C1 FD
			83 F9 ??
			77 6E
		]]),
	},

	gold_base = {
		value_offset = 0x30,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			6A FF
			C6 85 ?? ?? ?? ?? 01
			8B 0D ?? ?? ?? ??
			68 ?? ?? ?? ??
			E8 ?? ?? ?? ??
			8B 0D ?? ?? ?? ??
			50
			68 ?? ?? ?? ??
			68 ?? ?? ?? ??
			E8 ?? ?? ?? ??
			A1 ?? ?? ?? ??
			D9 80 ?? ?? ?? ??
			51
		]]),
	},

	gold_offset = {
		value_offset = 0x0D,
		value_size = 4,
		value_raw = true,
		pattern = byteArrayToPattern([[
			53
			8B 1D ?? ?? ?? ??
			56
			57
			8B F1
			2B B0 ?? ?? ?? ??
			8B FA
			2B B8 ?? ?? ?? ??
			85 F6
		]]),
	},

	object_list_base = {
		value_offset = 0x4C,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			7E 14
			8B 15 ?? ?? ?? ??
			8B FF
			3B 34 82
			74 16
			83 C0 01
			3B C1
			7C F4
			8D 44 24 ??
			50
			B9 ?? ?? ?? ??
			E8 ?? ?? ?? ??
			8D 4C 24 ??
			E8 ?? ?? ?? ??
			8B 5C 24 ??
			8B 74 24 ??
			E9 ?? ?? ?? ??
			33 DB
			39 1D ?? ?? ?? ??
			0F 8E ?? ?? ?? ??
			90
			8B 0D ?? ?? ?? ??
		]]),
		partners = {
			object_list_size = {
				add_value = -4; -- 4 bytes previous to object_list_base
			},
		},
	},

	game_time = {
		value_offset = 0x24,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			68 ?? ?? ?? ??
			FF D0
			8B 0D ?? ?? ?? ??
			8B 49 ??
			8B 11
			8B 42 ??
			68 ?? ?? ?? ??
			FF D0
			FF D6
			B9 ?? ?? ?? ??
			A3 ?? ?? ?? ??
			E8 ?? ?? ?? ??
			B9 ?? ?? ?? ??
			E8 ?? ?? ?? ??
			E8 ?? ?? ?? ??
			E8 ?? ?? ?? ??
			DD 05 ?? ?? ?? ??
			DD 05 ?? ?? ?? ??
			DC C1
			D9 C9
		]]),
		partners = {
			global_cooldown_base = {
				add_value = 0x10;-- + 0x1a28,
			},
		},
	},

	global_cooldown_offset = {
		value_offset = 0x08,
		value_size = 4,
		value_raw = true,
		pattern = byteArrayToPattern([[
			D8 C9
			D9 5C 24 ??
			DA 8F ?? ?? ?? ??
			D9 5C 24 ??
			D9 44 24 ??
			D9 44 24 ??
			DF F1
			DD D8
			76 1F
			F3 0F 2A 81 ?? ?? ?? ??
			5E
		]]),
	},

	loading_base = {
		value_offset = 0x32,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			83 C4 ??
			FF D7
			E8 ?? ?? ?? ??
			8B C8
			E8 ?? ?? ?? ??
			FF D7
			8B CE
			E8 ?? ?? ?? ??
			FF D7
			FF D7
			80 BE ?? ?? ?? ?? 00
			74 26
			80 3D ?? ?? ?? ?? 00
			74 1D
			8B 0D ?? ?? ?? ??
			8B 11
			8B 42 ??
			FF D0
			84 C0
		]]),
	},

	in_game = {
		value_offset = 0x27,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			3B CB
			C7 44 24 ?? ?? ?? ?? ??
			89 9F ?? ?? ?? ??
			74 0D
			8B 01
			8B 50 ??
			FF D2
			89 9F ?? ?? ?? ??
			8B CF
			E8 ?? ?? ?? ??
			A1 ?? ?? ?? ??
			83 E8 01
			3B C3
			A3 ?? ?? ?? ??
			7F 34
		]]),
	},

	macro_base = {
		value_offset = 0x1A,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			56
			8B 74 24 ??
			6A 01
			56
			E8 ?? ?? ?? ??
			83 E8 01
			83 C4 ??
			83 F8 ??
			77 2E
			8B 0D ?? ?? ?? ??
			69 C0 ?? ?? ?? ??
			8D 44 08 ??
			85 C0
			74 1A
			33 D2
			83 78 ?? FF
			0F 95 C2
		]]),
		partners = {
			macro_size = {
				value_offset = 6; -- 6 bytes after macro_base
				value_size = 4,
			},
		},
	},

	hotkey_base = {
		value_offset = 0x2B,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			66 85 C0
			7D 06
			81 CE ?? ?? ?? ??
			8B 7C 24 ??
			8D 44 24 ??
			50
			8D 4C 24 ??
			51
			8D 4B ??
			89 7C 24 ??
			89 74 24 ??
			E8 ?? ?? ?? ??
			8B 0D ?? ?? ?? ??
			8B 11
			8B 82 ?? ?? ?? ??
			6A 00
			0B F7
			56
			FF D0
		]]),
	},

	cooldowns_base = {
		value_offset = 0x11,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			50
			51
			E8 ?? ?? ?? ??
			8B 74 24 ??
			B9 ?? ?? ?? ??
			BF ?? ?? ?? ??
			F3 A5
			33 ED
			83 C4 18
			B9 ?? ?? ?? ??
			89 2D ?? ?? ?? ??
			E8 ?? ?? ?? ??
			8B 15 ?? ?? ?? ??
			8B 0D ?? ?? ?? ??
		]]),
	},

	cooldowns_array_start = {
		value_offset = 0x32,
		value_size = 4,
		value_raw = true,
		pattern = byteArrayToPattern([[
			0F 57 C0
			F3 0F 11 44 24 ??
			EB 31
			8B 81 ?? ?? ?? ??
			DB 84 87 ?? ?? ?? ??
			EB 1C
			8B 91 ?? ?? ?? ??
			DB 84 97 ?? ?? ?? ??
			EB 0D
			8B 81 ?? ?? ?? ??
			DB 84 87 ?? ?? ?? ??
			D8 C9
			D9 5C 24 ??
			DA 8F ?? ?? ?? ??
			D9 5C 24 ??
			D9 44 24 ??
			D9 44 24 ??
			DF F1
			DD D8
		]]),
	},

	skillbook_base = {
		value_offset = 0x11,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			55
			33 ED
			C1 E0 ??
			80 BF ?? ?? ?? ?? 00
			75 1C
			5D
			05 ?? ?? ?? ??
			5F
			8B 8C 24 ?? ?? ?? ??
			64 89 0D 00 00 00 00
			81 C4 ?? ?? ?? ??
			C3
			53
			56
			8D B0 ?? ?? ?? ??
			33 DB
		]]),
	},

	party_leader_base = {
		value_offset = 0x8,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			83 3D ?? ?? ?? ?? 10
			A1 ?? ?? ?? ??
			73 05
			B8 ?? ?? ?? ??
		]]),
	},

	party_member_list_base = {
		value_offset = 0x18,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			FF D0
			99
			B9 ?? ?? ?? ??
			F7 F9
			81 C2 ?? ?? ?? ??
			52
			E8 ?? ?? ?? ??
			8B 0D ?? ?? ?? ??
			83 C4 ??
			33 FF
			89 44 24 ??
			33 DB
			8B 41 ??
			85 C0
		]]),
		partners = {
			party_member_list_offset = {
				value_offset = 17; -- 17 bytes after macro_base
				value_size = 1,
			},
		},
	},

	party_icon_list_base = {
		value_offset = 0x24,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			C1 F8 02
			3B F8
			72 0A
			FF 15 ?? ?? ?? ??
			8B 4C 24 ??
			8B 34 B9
			8B 46 ??
			85 C0
			7C 20
			83 F8 ??
			7D 1B
			8B 16
			8B 0D ?? ?? ?? ??
			52
			E8 ?? ?? ?? ??
			50
			56
		]])
	},

	newbie_eggpet_base = {
		value_offset = 0x0b,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			FF 15 ?? ?? ?? ??
			83 C4 ??
			83 2D ?? ?? ?? ?? 04
			8B 35 ?? ?? ?? ??
			3B 35 ?? ?? ?? ??
			76 02
			FF D7
			B8 ?? ?? ?? ??
			8B D8
			EB 0B
			8D A4 24 00 00 00 00
		]])
	},

	newbie_eggpet_offset = {
		value_offset = 0x1e,
		value_size = 1,
		value_raw = true,
		pattern = byteArrayToPattern([[
			89 7E ??
			E8 ?? ?? ?? ??
			89 46 ??
			33 C9
			B8 01 00 00 00
			BA 04 00 00 00
			F7 E2
			0F 90 C1
			89 7E ??
			C7 86 80 00 00 00 01 00 00 00
		]])
	},

	movement_speed_base = {
		value_offset = 0x15,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			83 F8 01
			74 ??
			83 F8 ??
			0F 85 ?? ?? ?? ??
			D9 05 ?? ?? ?? ??
			B9 ?? ?? ?? ??
			DD 5C 24 ??
			E8 ?? ?? ?? ??
			DD 05 ?? ?? ?? ??
			D9 C0
			DE E2
		]])
	},

	movement_speed_offset = {
		value_offset = 0x29,
		value_size = 4,
		value_raw = true,
		pattern = byteArrayToPattern([[
			8B CE
			D9 9E ?? ?? ?? ??
			E8 ?? ?? ?? ??
			D9 9E ?? ?? ?? ??
			8B CE
			E8 ?? ?? ?? ??
			D9 9E ?? ?? ?? ??
			8B CE
			E8 ?? ?? ?? ??
			D9 9E ?? ?? ?? ??
			8B CE
		]])
	},

	inventory_rent_base = {
		value_offset = 0x7,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			56
			E8 ?? ?? ?? ??
			A1 ?? ?? ?? ??
			DB 80 ?? ?? ?? ??
			DD 1C 24
			56
			E8 ?? ?? ?? ??
			83 C4 ??
			B8 02 00 00 00
			5E
			C3
			6A 01
		]]),
		partners = {
			inventory_rent_offset = {
				value_offset = 6; -- 6 bytes after inventory_rent_base
				value_size = 4,
			},
		},
	},

	input_box_base = {
		value_offset = 0x15,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			52
			E8 ?? ?? ?? ??
			F3 0F 10 00
			83 C4 ??
			F3 0F 11 44 24 ??
			8B 0D ?? ?? ?? ??
			D9 81 ?? ?? ?? ??
			D9 5c 24 ??
			D9 44 24 ??
			D9 44 24 ??
			D9 C0
		]])
	},

	mouse_base = {
		value_offset = 0x2,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			8B 0D ?? ?? ?? ??
			8B 01
			8B 40 ??
			FF E0
		]])
	},

	cursor_base = {
		value_offset = 0xF,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			55
			8B EC
			83 E4 F8
			83 EC 0C
			53
			56
			8B F1
			8B 0D ?? ?? ?? ??
			85 C9
			57
			0F 84
		]])
	},

	text_base = {
		value_offset = 0x25,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			D9 E8
			DC C1
			D9 C9
			DD 15 ?? ?? ?? ??
			DC 6C 24 04
			DF F1
			DD D8
			77 D3
			D9 44 24 ??
			51
			D9 1C 24
			E8 ?? ?? ?? ??
			8B 0D ?? ?? ?? ??
			83 C4 04
			E9 ?? ?? ?? ??
		]])
	},

	channel_base = {
		value_offset = 0x2,
		value_size = 4,
		value_raw = false,
		pattern = byteArrayToPattern([[
			51
			A1 ?? ?? ?? ??
			8B 88 ?? ?? ?? ??
			8B 54 24 08
			83 C1 01
			89 0C 24
			DB 04 24
			83 EC 08
			DD 1C 24
			52
			E8 ?? ?? ?? ??
			B8 01 00 00 00
			83 C4 ??
			C3
		]])
	},
};

local startTime = getTime();
local foundUpdates = {};
local missingUpdates = 0;

-- Use MDBrute to find memdatabase
mdbrutePath = getExecutionPath() .. "/bin/";
if( false and fileExists(mdbrutePath .. "mdbrute.exe") ) then
	cprintf_ex("Using |lightblue|MDBrute|white| to find memdatabase base address... This may take some time.\n\n\n");
	local cmd = sprintf('cd "%s" && mdbrute.exe --first-only', mdbrutePath);
	local mdbruteResults = io.popen(cmd):read('*a');
	local addr = string.match(mdbruteResults, "Found address 0x([0-9a-fA-F]+)");

	if( addr ~= nil ) then
		addr = tonumber(addr, 16);
		foundUpdates['memdatabase_base'] = addr;
		cprintf_ex("|green|Found |pink|{memdatabase_base}|green| at |yellow|0x%X\n", addr);
	else
		cprintf_ex("|red|Could not locate {memdatabase_base}\n");
	end
else
	print("MDBrute not installed; could not scan for memdatabase");
	printf("If you would like to use this feature, ownload, extract, and place mdbrute.exe into:\n%s\n\n", mdbrutePath);
	print("Download at: https://github.com/SolarStrike-Software/mdbrute/releases\n\n\n");
end


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

		if( v.partners ~= nil ) then
			for j,k in pairs(v.partners) do
				local moddesc = "+0";
				local value_size = k.value_size or 4;

				if( k.add_value ~= nil ) then
					val = val + k.add_value;
					if( k.add_value >= 0 ) then
						moddesc = "+";
					else
						moddesc = "-";
					end
					moddesc = moddesc .. sprintf("0x%X", math.abs(k.add_value));
				elseif( k.value_offset ~= nil ) then
					if( k.value_offset >= 0 ) then
						moddesc = "+";
					else
						moddesc = "-";
					end
					moddesc = moddesc .. sprintf("0x%X", math.abs(k.value_offset));
					local newLoc = (v.value_offset or 0) + k.value_offset;
					val = getInt(found + newLoc, value_size);
				end
				cprintf_ex("|green|Found |pink|{%s}|green| at |pink|{%s}|yellow| %s|green|, new value: |yellow|0x%X\n",
					j, i, moddesc, val
				);
				foundUpdates[j] = val;
			end
		end
	else
		cprintf(cli.lightred, "Could not find pattern for {%s}\n", i);
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
		--local hexValue = sprintf("0x%x", value);
		local skip = false;
		local changed = string.gsub(addressFile,
			"=(%s-)([x%x]+)([%,%s]*)%-%-%[%[(%s*)%{" .. key .. "%}(%s*)%]%]([^\n]*)",
			function (ws1, curValue, ws2, ws3, ws4, ws5)
				if( tonumber(curValue) == value ) then
					skip = true;
				end
				return sprintf("=%s0x%x%s--[[%s{%s}%s]]%s", ws1, value, ws2, ws3, key, ws4, ws5);
			end);

		if( skip or changed ~= addressFile ) then
			cprintf_ex("|green|[+]|white| Successfully patched |pink|{%s}\n", key);
		else
			if( addressFile:find("%-%-%[%[%s*%{" .. key .. "%}%s*%]%]") ) then
				cprintf_ex("|yellow|[!]|white| Failed to patch |pink|{%s}|white| or already valid.\n", key);
			else
				cprintf_ex("|lightred|[-]|white| Failed to patch |pink|{%s}|white| (token not found in file)\n", key);
			end
		end
		addressFile = changed;
	end

	printf("Writing new addresses to %s\n", filename);
	local newHandle = io.open(getExecutionPath() .. "/" .. filename, 'w');
	newHandle:write(addressFile);
end


local continue = true;
if( missingUpdates > 0 ) then
	cprintf_ex("\n\n|yellow|Not all updatable addresses could be found.\n"
		.. "Do you want to continue and update found information? |white|y/n: ");
	while(true) do
		local inp = string.lower(string.sub(io.read("*l"), 1, 1));
		if( #inp == 0 ) then
			continue = false; -- Default = don't write
			break;
		end
		if( inp ~= 'y' and inp ~= 'n' ) then
			printf("Not a valid option. Select (y)es or (n)o: ");
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

local endTime = getTime();
if( continue ) then
	save('addresses.lua', true);
else
	print("Changed were not committed");
end



printf("Took %0.2f seconds\n", deltaTime(endTime, startTime) / 1000.0);
