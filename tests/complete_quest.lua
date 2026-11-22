return function(test, loadProject)
	local function fixture(options)
		local commands, waits, messages, rewardReads = {}, {}, {}, {}
		local quests = { { "Supply Run", false, 0 }, { "Supply Run (Daily)", true, 2 },
			{ "Supply Run (Daily Bonus)", true, 2 } }
		local rewards = { "Gold", "Silver Sword", "Silver Shield" }
		local attempts, timeReads = 0, 0
		local env = loadProject({
			settings = { options = {} },
			player = { TargetPtr = 1, updateTargetPtr = function() end },
			os = {
				clock = function() return 0 end,
				time = function()
					timeReads = timeReads + 1
					if options.times then
						return assert(options.times[timeReads], "Unexpected clock read")
					end
					return 100
				end,
			},
			yrest = function(ms) waits[#waits + 1] = ms end,
			printf = function(format, ...)
				messages[#messages + 1] = string.format(format, ...)
			end,
		}, "functions.lua")
		env.Attack = function() end
		env.RoMScript = function(query)
			if query == "SpeakFrame:IsVisible()" then return true end
			if query == "GetNumQuest(3)" then return #quests end
			if query == "SpeakQuestReward1.itemcount" then return #rewards end
			local quest = query:match("^GetQuestNameByIndex%(3, (%d+)%)$")
			if quest then
				local entry = quests[tonumber(quest)]
				return entry[1], entry[2], entry[3]
			end
			local reward = query:match("^SpeakQuestReward1_Item(%d+)_Desc:GetText%(%)$")
			assert(reward, "Unexpected dialog query: " .. query)
			reward = tonumber(reward)
			rewardReads[#rewardReads + 1] = reward
			return rewards[reward]
		end
		env.RoMCode = function(command)
			commands[#commands + 1] = command
			if command == "CompleteQuest()" then
				attempts = attempts + 1
				assert(attempts <= (options.attempts or 1), "Unexpected completion attempt")
			end
		end
		env.getQuestStatus = function()
			return attempts < (options.attempts or 1) and "complete" or "done"
		end
		return env.CompleteQuestByName, commands, waits, messages, rewardReads
	end

	local function clickQuest(index)
		return "OnClick_QuestListButton(3, " .. index .. ")"
	end

	local function clickReward(index)
		return "SpeakFrame_ClickQuestReward(SpeakQuestReward1_Item" .. index .. ")"
	end

	test("CompleteQuestByName matches quest name and group before selecting a numeric reward", function()
		local complete, commands, waits, _, reads = fixture({})
		assert(select("#", complete("supply run", 3, "DAILYS")) == 0)
		assert(table.concat(commands, "|") == table.concat({
			clickQuest(2), clickReward(3), "CompleteQuest()", "SpeakFrame:Hide()",
		}, "|"))
		assert(#reads == 0 and table.concat(waits, "|") == "100|500|100|100|100|900|750")
	end)

	test("CompleteQuestByName selects the first matching named reward", function()
		local complete, commands, _, _, reads = fixture({})
		assert(select("#", complete("supply run (daily)", "SILVER")) == 0)
		assert(table.concat(reads, "|") == "1|2")
		assert(table.concat(commands, "|") == table.concat({
			clickQuest(2), clickReward(2), "CompleteQuest()", "SpeakFrame:Hide()",
		}, "|"))
	end)

	test("CompleteQuestByName selects the default reward after two seconds", function()
		local complete, commands, waits = fixture({ attempts = 2, times = { 100, 101, 102 } })
		assert(select("#", complete("supply run", "daily")) == 0)
		assert(table.concat(commands, "|") == table.concat({
			clickQuest(2), "CompleteQuest()", clickQuest(2), clickReward(1),
			"CompleteQuest()", "SpeakFrame:Hide()",
		}, "|"))
		assert(table.concat(waits, "|") == "100|500|100|100|100|100|100|750")
	end)

	test("CompleteQuestByName stops without completing when a named reward is missing", function()
		local complete, commands, waits, messages, reads = fixture({})
		assert(select("#", complete("supply run", "Missing Reward")) == 0)
		assert(table.concat(reads, "|") == "1|2|3")
		assert(#commands == 1 and commands[1] == clickQuest(1))
		assert(table.concat(waits, "|") == "100|500|100")
		assert(messages[1] == 'Invalid reward name or number, "Missing Reward"\n')
	end)

	test("CompleteQuestByName closes the dialog when no quest matches", function()
		local complete, commands, waits, messages = fixture({})
		assert(select("#", complete("Unknown Quest")) == 0)
		assert(#commands == 1 and commands[1] == "SpeakFrame:Hide()")
		assert(table.concat(waits, "|") == "100|500|750")
		assert(messages[1] == "Questname not found: Unknown Quest\n")
	end)
end
