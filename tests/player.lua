return function(test, loadProject)
	local function fixture(stubs)
		stubs.class = function() return {} end
		-- These tests supply their own skill data and exercise player methods directly.
		stubs.include = function(name) assert(name == "pawn.lua" or name == "skill.lua") end
		local env = loadProject(stubs, "classes/player.lua")
		return setmetatable({ SkillQueue = {} }, { __index = env.CPlayer })
	end

	test("CPlayer queues skills by name or object in FIFO order", function()
		local profileSkill = { Name = "FIREBALL" }
		local player = fixture({
			settings = { profile = { skills = { profileSkill } } },
			CSkill = function(skill) return { Name = skill.Name } end,
		})
		local object = { Name = "STRIKE" }
		assert(player:getNextQueuedSkill() == nil)
		player:queueSkill("FIREBALL", true)
		player:queueSkill(object)
		local first = player:getNextQueuedSkill()
		assert(first.Name == "FIREBALL" and first.Blocking == true)
		assert(first ~= profileSkill and profileSkill.Blocking == nil)
		player:popSkillQueue()
		assert(player:getNextQueuedSkill() == object and object.Blocking == false)
		player:flushSkillQueue()
		assert(player:getNextQueuedSkill() == nil)
	end)

	test("CPlayer rejects unknown skill names and invalid queue entries", function()
		local messages = {}
		local player = fixture({
			settings = { profile = { skills = {} } },
			cli = { yellow = 1, red = 2 },
			cprintf = function(_, format, ...)
				messages[#messages + 1] = string.format(format, ...)
			end,
		})
		player:queueSkill("MISSING")
		player:queueSkill(42)
		assert(player:getNextQueuedSkill() == nil)
		assert(#messages == 2)
		assert(messages[1]:find("Unknown profile skill MISSING", 1, true))
		assert(messages[2]:find("'skill' is not a table", 1, true))
	end)

	test("CPlayer resets damage toggles and preserves Soul Bond cooldown", function()
		local damage = { Type = 1, Toggled = true, used = 4, LastCastTime = { low = 123, high = 456 } }
		local dot = { Type = 2, Toggled = true }
		local soulBond = { Name = "PRIEST_SOUL_BOND", Type = 3, Toggled = true, LastCastTime = { low = 77, high = 88 } }
		local player = fixture({
			settings = { profile = { skills = { damage, dot, soulBond } } },
			STYPE_DAMAGE = 1, STYPE_DOT = 2,
		})
		player:resetSkills()
		player:resetSkillLastCastTime()
		assert(damage.Toggled == false and dot.Toggled == false and soulBond.Toggled == true)
		assert(damage.used == 0 and dot.used == nil)
		assert(damage.LastCastTime.low == 0 and damage.LastCastTime.high == 0)
		assert(soulBond.LastCastTime.low == 77 and soulBond.LastCastTime.high == 88)
	end)

	test("CPlayer reads the global cooldown and scales the result", function()
		local player = fixture({
			addresses = { global_cooldown = { base = 100, offset = 12 } },
			getProc = function() return 4 end,
			getBaseAddress = function(offset)
				assert(offset == 112)
				return 1000 + offset
			end,
			memoryReadRepeat = function(kind, proc, address)
				assert(kind == "int" and proc == 4 and address == 1112)
				return 15
			end,
		})
		player:updateGlobalCooldown()
		assert(player.GlobalCooldown == 1.5)
	end)
end
