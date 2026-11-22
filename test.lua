local source = debug.getinfo(1, "S").source
local root = source:match("^@(.*[/\\])") or "./"
local suites = {
	"functions", "select_game", "load_paths", "rom_script", "complete_quest",
	"skill_book", "waypoints", "store", "player", "pawn", "skill",
	"world_objects", "item_storage",
	"item", "cursor", "camera",
	"item_slots", "class_data", "companions",
}
local passed, failed = 0, 0
local standard = {
	assert = assert, error = error, ipairs = ipairs, math = math, next = next,
	pairs = pairs, print = print, select = select, string = string, table = table,
	tonumber = tonumber, tostring = tostring, type = type, unpack = unpack or table.unpack,
}

local function ignoreCallback()
end

local function loadProject(stubs, ...)
	local env = setmetatable({
		atPause = ignoreCallback,
		atExit = ignoreCallback,
		atError = ignoreCallback,
		atResume = ignoreCallback,
		getExecutionPath = function() return root end,
	}, { __index = standard })
	for name, value in pairs(stubs) do
		env[name] = value
	end
	env._G = env
	for _, path in ipairs({ ... }) do
		local filename = root .. path
		if setfenv then
			setfenv(assert(loadfile(filename)), env)()
		else
			assert(loadfile(filename, "t", env))()
		end
	end
	return env
end

local function test(name, run)
	local ok, message = xpcall(run, debug.traceback)
	if ok then
		passed = passed + 1
		print("PASS " .. name)
	else
		failed = failed + 1
		print("FAIL " .. name .. "\n" .. message)
	end
end

for _, suite in ipairs(suites) do
	local register = assert(loadfile(root .. "tests/" .. suite .. ".lua"))()
	register(test, loadProject)
end

print(string.format("%d passed, %d failed", passed, failed))
if failed > 0 then
	error("RoMBot unit tests failed", 0)
end
