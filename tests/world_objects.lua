return function(test, loadProject)
	local function class(constructor)
		local methods = {}
		return setmetatable(methods, {
			__call = function(_, ...)
				local object = setmetatable({}, { __index = methods })
				constructor(object, ...)
				return object
			end,
		})
	end

	test("CNode applies defaults and preserves missing fields in a copy", function()
		local env = loadProject({ class = class }, "classes/node.lua")
		local node = env.CNode()
		assert(node.Name == "<NODE>" and node.Id == 0 and node.Type == env.NTYPE_WOOD)
		local copy = env.CNode({ Id = 42, Type = env.NTYPE_ORE })
		assert(copy.Name == nil and copy.Id == 42 and copy.Type == env.NTYPE_ORE)
	end)

	test("CWaypoint copies route metadata and leaves Y optional", function()
		local env = loadProject({ class = class }, "classes/waypoint.lua")
		local point = env.CWaypoint(7, 8)
		assert(point.X == 7 and point.Z == 8 and point.Y == nil and point.Tag == "")
		local copy = env.CWaypoint({ X = 9, Y = 3, Type = env.WPT_RUN, Action = "action", Tag = "exit" })
		assert(copy.X == 9 and copy.Z == 0 and copy.Y == 3)
		assert(copy.Type == env.WPT_RUN and copy.Action == "action" and copy.Tag == "exit")
	end)

	test("Wander uses bounded offsets or the player position at zero radius", function()
		local draws = 0
		local env = loadProject({
			class = function() return {} end,
			player = { X = 15, Z = 25 },
			CWaypoint = function(x, z) return { X = x, Z = z } end,
			math = { random = function(low, high)
				draws = draws + 1
				if draws <= 2 then assert(low == -5 and high == 5)
				else assert(low == 0 and high == 0) end
				return draws % 2 == 1 and low or high
			end },
		}, "classes/waypointlist_wander.lua")
		local route = setmetatable({ OrigX = 100, OrigZ = 200 }, { __index = env.CWaypointListWander })
		route:setRadius(10)
		local point = route:getNextWaypoint()
		assert(point.X == 95 and point.Z == 205 and point.Y == nil)
		route:setRadius(0)
		point = route:getNextWaypoint()
		assert(point.X == 15 and point.Z == 25 and draws == 4)
	end)

	test("CObjectList rebuilds its snapshot and skips empty object slots", function()
		local pointers = { [500] = 600, [504] = 700, [508] = 0 }
		local env = loadProject({
			class = class,
			include = function(name) assert(name == "object.lua") end,
			addresses = { object_list = { base = 10, size = 11 } },
			getProc = function() return 4 end,
			getBaseAddress = function(offset) return 90 + offset end,
			memoryReadInt = function(proc, address)
				assert(proc == 4 and address == 101)
				return 2
			end,
			memoryReadUInt = function(proc, address)
				assert(proc == 4)
				if address == 100 then return 500 end
				return pointers[address]
			end,
			CObject = function(address) return { Address = address } end,
		}, "classes/objectlist.lua")
		local list = env.CObjectList()
		list:update()
		assert(list:getObject(0).Address == 600 and list:getObject(1).Address == 700)
		assert(list:size() == 1 and not pcall(list.getObject, list, 2))
		pointers[504] = nil
		list:update()
		assert(list:size() == 0 and list:getObject(0).Address == 600)
	end)
end
