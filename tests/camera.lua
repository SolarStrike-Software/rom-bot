return function(test, loadProject)
	local function fixture()
		local coordinates = { [101] = 1, [102] = 2, [103] = 3, [104] = 4, [105] = 6, [106] = 15 }
		local writes, distanceWrites = {}, {}
		local env = loadProject({
			settings = { options = {} },
			class = function() return {} end,
			addresses = { game_root = {
				base = 20, camdistance = 8,
				camera = { x = 1, y = 2, z = 3, focus_x = 4, focus_y = 5, focus_z = 6 },
			} },
			memoryReadFloat = function(proc, address)
				assert(proc == 5)
				return assert(coordinates[address])
			end,
			memoryWriteFloat = function(proc, address, value)
				assert(proc == 5 and address >= 101 and address <= 103)
				writes[address] = value
			end,
			memoryWriteFloatPtr = function(proc, base, offset, value)
				assert(proc == 5 and base == 220 and offset == 8)
				distanceWrites[#distanceWrites + 1] = value
			end,
		}, "functions.lua", "classes/camera.lua")
		env.getProc = function() return 5 end
		env.getBaseAddress = function(offset) return offset + 200 end
		return setmetatable({ Address = 100 }, { __index = env.CCamera }), writes, distanceWrites
	end

	test("CCamera reads position and focus and calculates distance", function()
		local camera = fixture()
		camera:update()
		assert(camera.X == 1 and camera.Y == 2 and camera.Z == 3)
		assert(camera.XFocus == 4 and camera.YFocus == 6 and camera.ZFocus == 15)
		assert(camera.Distance == 13)
	end)

	test("CCamera setPosition uses cached coordinates for omitted axes", function()
		local camera, writes = fixture()
		camera:update()
		camera:setPosition(9, nil, 0)
		assert(writes[101] == 9 and writes[102] == 2 and writes[103] == 0)
	end)

	test("CCamera clamps distance and preserves height when repositioning", function()
		local camera, writes, distances = fixture()
		camera.X, camera.Y, camera.Z = 0, 7, 10
		camera.XFocus, camera.ZFocus = 10, 10
		camera:setDistance("invalid")
		assert(#distances == 0 and next(writes) == nil)
		camera:setDistance(0)
		assert(distances[1] == 1 and math.abs(writes[101] - 9) < 1e-10)
		camera:setDistance(200)
		assert(distances[2] == 150 and math.abs(writes[101] + 140) < 1e-10)
		assert(writes[102] == 7 and math.abs(writes[103] - 10) < 1e-10)
	end)
end
