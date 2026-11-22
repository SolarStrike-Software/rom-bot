return function(test, loadProject)
	local function fixture()
		local function noOp() end
		local player = {
			Level = 20, Class1 = 1, HP = 100, MaxHP = 100,
			Mana = 50, MaxMana = 100, Rage = 0, Energy = 0, Focus = 0, Psi = 0, Nature = 0,
			LastSkill = { Id = -1 }, targetDistance = 10,
			updateMP = noOp, updatePsi = noOp, updateBattling = noOp, updateNature = noOp,
			distanceToTarget = function(self) return self.targetDistance end,
		}
		local target = {
			Address = 100, Type = 2, HP = 100, MaxHP = 100,
			updateHP = noOp, updateType = noOp, isAlive = function() return true end,
		}
		local env = loadProject({
			class = function(constructor)
				local methods = {}
				return setmetatable(methods, { __call = function(_, copy)
					local object = setmetatable({}, { __index = methods })
					constructor(object, copy)
					return object
				end })
			end,
			player = player,
			settings = { profile = { options = {} } },
			CLASS_PRIEST = 5, PT_PLAYER = 1, PT_MONSTER = 2,
			getZoneId = function() return 1 end,
			getSkillUsePrior = function() return 0 end,
			GetIdName = tostring,
		}, "classes/skill.lua")
		local skill = env.CSkill()
		skill.Available, skill.hotkey = true, 1
		return skill, env, target
	end

	test("CSkill checks availability, hotkey, level, and friendly-only mode", function()
		local skill, _, target = fixture()
		assert(skill:canUse(false, target))
		skill.Available = false
		assert(skill:canUse(false, target) == false)
		skill.Available, skill.hotkey = true, 0
		assert(skill:canUse(false, target) == false)
		skill.hotkey, skill.aslevel = 1, 21
		assert(skill:canUse(false, target) == false)
		skill.aslevel = 20
		assert(skill:canUse(true, target) == false)
		assert(skill:canUse(false, target))
	end)

	test("CSkill enforces mana costs and minimum and maximum range", function()
		local skill, env, target = fixture()
		skill.Mana = 51
		assert(skill:canUse(false, target) == false)
		skill.Mana, skill.MinRange = 50, 5
		for _, distance in ipairs({ 5, 20 }) do
			env.player.targetDistance = distance
			assert(skill:canUse(false, target))
		end
		for _, distance in ipairs({ 4, 21 }) do
			env.player.targetDistance = distance
			assert(skill:canUse(false, target) == false)
		end
	end)

	test("CSkill requires the correct ammunition type and enough arrows", function()
		local skill, env, target = fixture()
		local ammo = { ObjSubType = 6, ItemCount = 3, update = function() end }
		env.equipment = { BagSlot = { [9] = ammo } }
		skill.Consumable, skill.ConsumableNumber = "arrow", 3
		assert(skill:canUse(false, target) == false)
		ammo.ObjSubType, ammo.ItemCount = 5, 2
		assert(skill:canUse(false, target) == false)
		ammo.ItemCount = 3
		assert(skill:canUse(false, target))
	end)

	test("CSkill prefers its configured cooldown before reading the client", function()
		local skill, env = fixture()
		skill.Cooldown, skill.BaseItemAddress = 5, 100
		env.getTime = function() return 3500 end
		env.deltaTime = function(now, lastCast)
			assert(now == 3500 and lastCast == skill.LastCastTime)
			return 3500
		end
		env.memoryReadRepeat = function() error("Unexpected client cooldown read") end
		assert(skill:getRemainingCooldown() == 1.5)
	end)

	test("CSkill reads client cooldown slots and handles missing values", function()
		local skill, env = fixture()
		local index, remaining = 3, 25
		skill.BaseItemAddress = 100
		env.getTime = function() return 0 end
		env.deltaTime = function() return 0 end
		env.getProc = function() return 4 end
		env.addresses = { skill = { remaining_cooldown = 8 }, cooldowns = { base = 200, array_start = 4 } }
		env.getBaseAddress = function(offset)
			assert(offset == 204)
			return 1000 + offset
		end
		env.memoryReadRepeat = function(kind, proc, address)
			assert(kind == "int" and proc == 4 and address == 108)
			return index
		end
		env.memoryReadInt = function(proc, address)
			assert(index == 3 and proc == 4 and address == 1216)
			return remaining
		end
		assert(skill:getRemainingCooldown() == 2.5)
		remaining = nil
		assert(skill:getRemainingCooldown() == 0)
		index = nil
		assert(skill:getRemainingCooldown() == 0)
	end)
end
