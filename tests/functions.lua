return function(test, loadProject)
	local function loadFunctions(stubs)
		stubs = stubs or {}
		stubs.settings = { options = {} }
		return loadProject(stubs, "functions.lua")
	end

	test("angleDifference uses the shorter arc across zero", function()
		local difference = loadFunctions().angleDifference
		assert(difference(0, 0) == 0)
		assert(difference(0, math.pi) == math.pi)
		assert(math.abs(difference(0.1, 2 * math.pi - 0.1) - 0.2) < 1e-10)
	end)

	test("trim strips outer whitespace and returns one value", function()
		local trim = loadFunctions().trim
		assert(trim("\t two words \r\n") == "two words")
		assert(trim(" \t ") == "")
		assert(select("#", trim("word")) == 1)
	end)

	test("nearest segment point projects and clamps to the endpoints", function()
		local nearest = loadFunctions({
			CWaypoint = function(x, z) return { X = x, Z = z } end,
		}).getNearestSegmentPoint
		local point = nearest(4, 3, 0, 0, 10, 0)
		assert(point.X == 4 and point.Z == 0)
		point = nearest(-1, 3, 0, 0, 10, 0)
		assert(point.X == 0 and point.Z == 0)
		point = nearest(11, 3, 0, 0, 10, 0)
		assert(point.X == 10 and point.Z == 0)
		point = nearest(4, 3, 2, 1, 2, 1)
		assert(point.X == 2 and point.Z == 1)
	end)

	test("distance supports scalar and table points", function()
		local distance = loadFunctions().distance
		assert(distance(10, 20, 13, 24) == 5)
		assert(distance(10, 20, 0, 13, 24, 12) == 13)
		assert(distance({ X = 10, Z = 20, Y = 100 }, { 13, 24 }) == 5)
		assert(distance({ 10, 20, 0 }, { X = 13, Z = 24, Y = 12 }) == 13)
	end)

	test("distance rejects missing horizontal coordinates", function()
		local ok, message = pcall(loadFunctions().distance, { X = 10 }, { 13, 24 })
		assert(not ok and message:find("Error: nil value passed to distance()", 1, true))
	end)

	test("parseItemLink preserves return counts and fallback values", function()
		local parse = loadFunctions().parseItemLink
		assert(select("#", parse(nil)) == 0)
		assert(select("#", parse("")) == 0)
		assert(select("#", parse("unmatched")) == 3)
		local id, color, name = parse("unmatched")
		assert(id == 0 and color == 0 and name == "<invalid>")
		id, color, name = parse("|Hitem:1a|h|c00ff00[Example Item]|r|h")
		assert(id == 26 and color == 65280 and name == "Example Item")
	end)
end
