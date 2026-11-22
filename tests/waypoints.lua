return function(test, loadProject)
	local function makeRoute(stubs)
		stubs.class = function() return {} end
		stubs.settings = { options = {} }
		local env = loadProject(stubs, "functions.lua", "classes/waypointlist.lua")
		local route = setmetatable({
			Waypoints = {},
			CurrentWaypoint = 1,
			Direction = env.WPT_FORWARD,
		}, { __index = env.CWaypointList })
		return route, env
	end

	test("nearest waypoint supports routes with missing Y", function()
		local route = makeRoute({})
		route.Waypoints = { { X = 13, Z = 24, Y = 12 }, { X = 20, Z = 20 } }
		assert(route:getNearestWaypoint(10, 20) == 1)
		assert(route:getNearestWaypoint(10, 20, 0) == 2)
	end)

	test("reversing short routes retains a valid waypoint index", function()
		local route, env = makeRoute({})
		for count = 1, 2 do
			route.Waypoints[count] = {}
			for index = 1, count do
				route.CurrentWaypoint = index
				route:reverse()
				assert(route.Direction == env.WPT_BACKWARD and route.CurrentWaypoint == index)
				route:reverse()
				assert(route.Direction == env.WPT_FORWARD and route.CurrentWaypoint == index)
			end
		end
	end)

	test("loading a route clears the previous onLoad callback", function()
		local point = {
			getName = function() return "waypoint" end,
			getValue = function() return "" end,
			getAttribute = function(_, name) return ({ x = 1, z = 2 })[name] end,
		}
		local hook = {
			getName = function() return "onLoad" end,
			getValue = function() return "testHook()" end,
			getAttribute = function() end,
		}
		local runs = 0
		local route = makeRoute({
			player = { X = 0, Z = 0 },
			CWaypoint = function(x, z) return { X = x, Z = z } end,
			loadstring = function(code)
				assert(code == "testHook()")
				return function() runs = runs + 1 end
			end,
			xml = { open = function(filename)
				return {
					getElements = function()
						if filename == "waypoints/with-hook.xml" then return { point, hook } end
						return { point }
					end,
					getAttribute = function() end,
				}
			end },
		})
		route:load("waypoints/with-hook.xml")
		assert(route.DoOnload)
		route.DoOnload = false
		route.onLoadEvent()
		assert(runs == 1)
		route:load("waypoints/without-hook.xml")
		assert(not route.DoOnload and route.onLoadEvent == nil)
	end)
end
