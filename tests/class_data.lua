return function(test, loadProject)
	test("GetIdName caches singular and plural names separately", function()
		local addresses, reads = {}, 0
		local env = loadProject({
			commandMacro = 0,
			MemDatabase = { getAddress = function(_, id) addresses[#addresses + 1] = id; return 100 end },
			addresses = { item = { name = 8 } },
			getProc = function() return 4 end,
			memoryReadInt = function(proc, address)
				assert(proc == 4)
				return address + 100
			end,
			memoryReadString = function(_, address)
				reads = reads + 1
				return ({ [208] = "Potion", [212] = "Potions" })[address]
			end,
			validName = function(name) return name ~= nil end,
		}, "classes/memorytable.lua")
		assert(env.GetIdName(101) == "Potion" and env.GetIdName(101, true) == "Potions")
		assert(env.GetIdName(101, true) == "Potions" and env.GetIdName(101) == "Potion")
		assert(env.GetIdName(0) == nil and reads == 2 and #addresses == 2)
	end)

	test("CMemDatabase serves cached addresses and expires branch timestamps", function()
		local env = loadProject({
			class = function(constructor)
				local methods = {}
				return setmetatable(methods, { __call = function()
					local object = setmetatable({}, { __index = methods })
					constructor(object)
					return object
				end })
			end,
			os = { clock = function() return 0 end, time = function() return 100 end },
			fileExists = function() return false end,
		}, "classes/memdatabase.lua")
		local database = env.MemDatabase
		database.database[42] = { address = 1234 }
		database.loadedBranches[1], database.loadedBranches[2] = 40, 39
		assert(database:getAddress(42) == 1234)
		assert(not database:isBranchDirty(1) and database:isBranchDirty(2) and database:isBranchDirty(3))
		database.loadedIds[42] = true
		database:flush()
		assert(next(database.database) == nil and next(database.loadedIds) == nil and database:isBranchDirty(1))
	end)

	test("LoadItemTypes reuses a matching cache and rebuilds it after a language change", function()
		local reads, rebuilds, saves = 0, 0, 0
		local env = loadProject({
			pcall = pcall, printf = function() end,
			getExecutionPath = function() return "test-root" end,
			fileExists = function(path)
				assert(path == "test-root/../cache/itemtypestable.lua")
				return true
			end,
			RoMScript = function(command)
				assert(command == "GetLanguage()")
				return "ENUS"
			end,
		}, "classes/itemtypes.lua")
		local language = "EN"
		env.dofile = function(path)
			assert(path == "test-root/../cache/itemtypestable.lua")
			reads = reads + 1
			env.itemtypes, env.itemtypes_language, env.itemtypes_version = { cached = true }, language, 1
		end
		env.LoadItemTypes_memory = function() rebuilds = rebuilds + 1 end
		env.CacheItemTypes = function() saves = saves + 1 end
		env.LoadItemTypes()
		assert(env.itemtypes.cached and reads == 1 and rebuilds == 0 and saves == 0)
		language = "DE"
		env.LoadItemTypes()
		assert(reads == 2 and rebuilds == 1 and saves == 1)
	end)

	test("CObject snapshots valid objects and rejects invalid IDs", function()
		local id, warnings = 42, {}
		local env = loadProject({
			class = function() return {} end,
			getProc = function() return 4 end,
			addresses = { game_root = { pawn = { id = 1, type = 2, name_ptr = 3, x = 4, y = 5, z = 6 } } },
			memoryReadUInt = function(_, address) assert(address == 101); return id end,
			memoryReadInt = function(_, address) assert(address == 102); return 2 end,
			memoryReadRepeat = function(kind, _, address)
				assert(kind == "uint" and address == 103)
				return 200
			end,
			memoryReadString = function(_, address) assert(address == 200); return "Wolf" end,
			memoryReadFloat = function(_, address) return ({ [104] = 3, [106] = 5 })[address] end,
			showWarnings = function(value) warnings[#warnings + 1] = value end,
			bot = { ClientLanguage = "EN" },
			utf8ToAscii_umlauts = function(name) return name end,
		}, "classes/object.lua")
		local object = setmetatable({ Address = 100 }, { __index = env.CObject })
		object:update()
		assert(object.Name == "Wolf" and object.Attackable and object.X == 3 and object.Y == 0 and object.Z == 5)
		assert(#warnings == 2 and warnings[1] == false and warnings[2] == true)
		id = 1000000
		object:update()
		assert(object.Id == 0 and object.Type == -1 and object.Name == "" and #warnings == 2)
	end)

	test("CCodeMod recognizes matching and different byte snapshots", function()
		local bytes = { -1, 65 }
		local env = loadProject({
			class = function() return {} end,
			getProc = function() return 4 end,
			getBaseAddress = function(offset) return 1000 + offset end,
			memoryReadBatch = function(proc, address, format)
				assert(proc == 4 and address == 1008 and format == "BB")
				return bytes
			end,
		}, "classes/codemod.lua")
		local snapshot = setmetatable({
			base = 8, origCode = string.char(255, 65), replacement = string.char(255, 66),
		}, { __index = env.CCodeMod })
		assert(not snapshot:checkModified() and not snapshot:checkInstalled())
		bytes = { -1, 66 }
		assert(snapshot:checkModified() and snapshot:checkInstalled())
	end)
end
