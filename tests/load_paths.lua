return function(test, loadProject)
	local function fixture(files, resumeIndex)
		local lookups, loads = {}, {}
		local function newRoute()
			return {
				CurrentWaypoint = 1,
				load = function(self, path)
					loads[#loads + 1] = path
					self.Waypoints = { {}, {}, {} }
					self.CurrentWaypoint = 2
				end,
				setMode = function(self, mode) self.Mode = mode end,
				setRadius = function(self, radius) self.Radius = radius end,
				setForcedWaypointType = function(self, kind) self.ForcedType = kind end,
			}
		end
		local env = loadProject({
			settings = { options = {}, profile = { options = {
				RETURNPATH_SUFFIX = "_return", WANDER_RADIUS = 75,
			} } },
			player = { Name = "Example", Returning = true },
			cli = { yellow = 1, green = 2, lightgray = 3 },
			language = {
				[0] = "Loaded %s", [1] = "Loaded return %s", [15] = "Nearest waypoint %d",
				[142] = "Missing route %s", [143] = "Missing return %s",
				[162] = "Found default %s", [163] = "No default %s",
				[164] = "Using return route %s", [165] = "Using primary route %s",
				[168] = "Wander radius %d",
			},
			sprintf = string.format,
			cprintf = function(_, format, ...) string.format(format, ...) end,
			fileExists = function(path) return files[path] == true end,
			getExecutionPath = function() return "test-root" end,
			dofile = function(path)
				assert(path == "test-root/logs/resumes/Example.txt")
				return "saved.xml", resumeIndex, 4
			end,
			CWaypointList = newRoute,
			CWaypointListWander = newRoute,
			__WPL = newRoute(),
			__RPL = newRoute(),
		}, "functions.lua")
		-- functions.lua defines findFile, so replace it after loading the module.
		env.findFile = function(path)
			lookups[#lookups + 1] = path
			return path
		end
		return env, lookups, loads
	end

	test("loadPaths loads a normal route and clears a missing default return", function()
		local env, lookups, loads = fixture({ ["waypoints/main.xml"] = true })
		local oldPrimary = env.__WPL
		env.loadPaths("main")
		assert(env.__WPL ~= oldPrimary and env.__WPL.CurrentWaypoint == 2)
		assert(env.__RPL == nil and env.player.Returning == false)
		assert(table.concat(lookups, "|") == "waypoints/main.xml|waypoints/main_return.xml")
		assert(table.concat(loads, "|") == "waypoints/main.xml")
	end)

	test("loadPaths configures wander without loading a primary file", function()
		local env, _, loads = fixture({})
		env.loadPaths("wander")
		assert(env.__WPL.Mode == "wander" and env.__WPL.Radius == 75)
		assert(#loads == 0 and env.__RPL == nil and env.player.Returning == false)
	end)

	test("loadPaths loads the saved route and applies valid resume settings", function()
		for _, index in ipairs({ 3, 99 }) do
			local env, _, loads = fixture({ ["test-root/logs/resumes/Example.txt"] = true }, index)
			env.loadPaths("resume")
			assert(table.concat(loads, "|") == "waypoints/saved.xml")
			assert(env.__WPL.CurrentWaypoint == (index == 3 and 3 or 2))
			assert(env.__WPL.ForcedType == 4)
		end
	end)

	test("loadPaths loads the default return route after the primary", function()
		local env, _, loads = fixture({ ["waypoints/main.xml"] = true, ["waypoints/main_return.xml"] = true })
		local oldReturn = env.__RPL
		env.loadPaths("main.xml")
		assert(env.__RPL == oldReturn and env.player.Returning == true)
		assert(table.concat(loads, "|") == "waypoints/main.xml|waypoints/main_return.xml")
	end)

	test("loadPaths prefers an explicit return route over the default", function()
		local env, lookups, loads = fixture({
			["waypoints/main.xml"] = true, ["waypoints/main_return.xml"] = true,
			["waypoints/back.xml"] = true,
		})
		env.__RPL = nil
		env.player.Returning = false
		env.loadPaths("main", "back")
		assert(env.__RPL and env.player.Returning == false)
		assert(table.concat(lookups, "|") == "waypoints/main.xml|waypoints/back.xml")
		assert(table.concat(loads, "|") == "waypoints/main.xml|waypoints/back.xml")
	end)

	test("loadPaths preserves the primary route when loading only a return route", function()
		for _, returning in ipairs({ false, true }) do
			local env, lookups, loads = fixture({ ["waypoints/back.xml"] = true })
			local primary, returnRoute = env.__WPL, env.__RPL
			primary.CurrentWaypoint, primary.ForcedType = 7, 4
			env.player.Returning = returning
			env.loadPaths(nil, "back")
			assert(env.__WPL == primary and primary.CurrentWaypoint == 7 and primary.ForcedType == 4)
			assert(env.__RPL == returnRoute and env.player.Returning == returning)
			assert(table.concat(lookups, "|") == "waypoints/back.xml")
			assert(table.concat(loads, "|") == "waypoints/back.xml")
		end
	end)
end
