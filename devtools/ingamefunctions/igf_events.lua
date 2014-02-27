-- Definition of 'monitor':
----------------------------
-- In the context of this file, the name, event to monitor and filter options specified by the user is called a 'monitor'.

local InGameFrame

local igf_events ={} -- the addon namesapace
_G.igf_events = igf_events -- expose to global scope

-- Variables
local Monitors = {} -- Where the details of the user specified monitors are saved.
					-- eg. Monitors["Leaderchat"] = {Event = "CHAT_MSG_PARTY", Filter = {nil,nil,nil,"Leadername"}}
local EventLog = {} -- log of all saved triggered events for the monitors.
					-- eg. EventLog["LeaderChat"] = (First = 1, Last = 4, Data = {Time=xxxx, Args = {"Attack!", link with persons name, unknown, "Leadername"} } }
local Last = 0 -- Number of last event in event log.

-- This addon also remebers the last of every message in the following events. I'm calling this feature "LastMessage".
local LastMessageEvents = {
	"ALERT_MESSAGE",
	"WARNING_MESSAGE",
}
local LastMessageLog = {}

local function IsLastMessageEvent(event)
	for k,v in pairs(LastMessageEvents) do
		if v == event then
			return true
		end
	end

	return false
end

function igf_events:OnLoad(this)
	InGameFrame = this

	for k,v in pairs(LastMessageEvents) do
		-- Register LastMessageEvents
		InGameFrame:RegisterEvent(v)
		-- Create initial LastMessage log tables
		LastMessageLog[v] = {}
	end
	InGameFrame:RegisterEvent("COMBATMETER_DAMAGE")

end

local _lastTargetTime, _lastTargetDamage, _lastTargetTarget, _lastTargetSkill, _lastTargetType
local _lastPlayerTime, _lastPlayerDamage, _lastPlayerSource, _lastPlayerSkill, _lastPlayerType
local _lastEnemyCritical, _lastPlayerDodge, _lastEnemyDodge, _lastPlayerBlock
function igf_events:OnEvent(this, event, arg1, arg2, arg3, arg4, arg5, arg6 )
	if event == "COMBATMETER_DAMAGE" then
		if _source == UnitName("player") and _target ~= UnitName("player") then
			_lastTargetTime = GetTime()
			_lastTargetDamage, _lastTargetTarget, _lastTargetSkill, _lastTargetType = _damage, _target, _skill, _type
			if _type == "CRITIAL" then
				_lastEnemyCritical = _lastTargetTime
			elseif _type == "DODGE" then
				_lastEnemyDodge = _lastTargetTime
			end
		elseif _source ~= UnitName("player") and _target == UnitName("player") then
			_lastPlayerTime = GetTime()
			_lastPlayerDamage, _lastPlayerSource, _lastPlayerSkill, _lastPlayerType = _damage, _source, _skill, _type
			if _type == "DODGE" then
				_lastPlayerDodge = _lastPlayerTime
			elseif _type == "BLOCK" then
				_lastPlayerBlock = _lastPlayerTime
			end
		end
	end

	local args = { arg1, arg2, arg3, arg4, arg5, arg6 }
	local triggerTime = os.time()

	-- Always remember LastMessageEvents
	if IsLastMessageEvent(event) then
		LastMessageLog[event][string.lower(arg1)] = GetTime()
	end

	-- for each monitor
	for monitorName, monitorArgs in pairs(Monitors) do
		-- check if event matches and it isn't paused
		if monitorArgs.Event == event and not monitorArgs.Paused then
			local isMatch = true

			-- check if monitor has an arg filter
			if monitorArgs.Filter then
				-- for each monitor arg filter
				for argNumber, argValue in pairs(monitorArgs.Filter) do
					if argValue ~= nil then
						if args[argNumber] == nil then
							isMatch = false
							break
						elseif string.find(args[argNumber], argValue) == nil then
							isMatch = false
							break
						end
					end
				end
			end

			if isMatch then -- Save in log
				if not EventLog[monitorName] then
					-- create it
					EventLog[monitorName] = { First = 1, Last = 0 }
					EventLog[monitorName].Data = {}
				end
				-- increment last place
				EventLog[monitorName].Last = EventLog[monitorName].Last + 1
				-- save the data
				EventLog[monitorName].Data[EventLog[monitorName].Last] = {Time = triggerTime, Args = {arg1, arg2, arg3, arg4, arg5, arg6} }
			end
		end
	end
end

function igf_events:StartMonitor(monitorName, event, filter)
	-- check arguments
	if type(monitorName) ~= "string" or type(event) ~= "string" or
		(filter ~= nil and type(filter) ~= "string") then
		SendSystemChat("Incorrect argument used in 'igf_events:StartMonitor()'.")
		return false
	end

	if filter then
		-- move into table
		local t = {}
		local n = 0
		for val in string.gmatch(","..filter,"[,]([^,]*)") do
			n = n + 1
			if val ~="" and val ~= "nil" and string.find(val,"^%s*$") == nil then
				t[n] = val
			end
		end

		filter = t
	end

	-- Save monitor to table
	Monitors[monitorName] = { Event = event, Filter = filter, Paused = false }

	-- Reset the log entries
	EventLog[monitorName] = nil

	-- Register the monitor event
	InGameFrame:RegisterEvent(event)
end

function igf_events:StopMonitor(monitorName)
	-- check argument
	if Monitors[monitorName] == nil then
		SendSystemChat("Cannot stop monitor '"..monitorName.."'. No such monitor name exists.")
		return
	end

	-- temporarily remember the event
	local event = Monitors[monitorName].Event

	-- Delete monitor
	Monitors[monitorName] = nil

	-- Delete 'monitorName' log entries.
	EventLog[monitorName] = nil

	-- We don't stop system messages
	if IsLastMessageEvent(event) then
		return
	end

	-- Check if any other monitor is using the event
	for n, v in pairs(Monitors) do
		if v.Event == event then
			-- Another monitor is using the event. Don't unregister it.
			return
		end
	end

	-- Unregister the event
	InGameFrame:UnregisterEvent(event)
end

function igf_events:PauseMonitor(monitorName)
	-- check argument
	if Monitors[monitorName] == nil then
		SendSystemChat("Cannot pause monitor '"..monitorName.."'. No such monitor name exists.")
		return
	end

	Monitors[monitorName].Paused = true
end

function igf_events:ResumeMonitor(monitorName)
	-- check argument
	if Monitors[monitorName] == nil then
		SendSystemChat("Cannot resume monitor '"..monitorName.."'. No such monitor name exists.")
		return
	end

	Monitors[monitorName].Paused = false
end

function igf_events:GetLogEvent(monitorName, returnFilter, lastEntryOnly)
	-- check arguments
	if Monitors[monitorName] == nil then
		SendSystemChat("Cannot get log event for monitor '"..monitorName.."'. No such monitor name exists.")
		return
	end
	if type(monitorName) ~= "string" or
		(returnFilter ~= nil and type(returnFilter) ~= "string" ) or
		(lastEntryOnly ~= nil and type(lastEntryOnly) ~= "boolean" ) then

		SendSystemChat("Incorrect argument used in 'igf_events:GetLogEvent()'.")
		return
	end

	-- Check if log entries exist
	if EventLog[monitorName] == nil then
		return
	end

	-- First find which to send and remove from log.
	local found, moreFound = false, false
	local entryToSend
	if lastEntryOnly == true then
		entryToSend = EventLog[monitorName].Data[EventLog[monitorName].Last]
		-- Clear the log
		EventLog[monitorName] = nil
	else
		entryToSend = EventLog[monitorName].Data[EventLog[monitorName].First]
		if EventLog[monitorName].Last == EventLog[monitorName].First then
			-- No more left. Clear log.
			EventLog[monitorName] = nil
		else
			-- remove from log
			EventLog[monitorName].Data[EventLog[monitorName].First] = nil
			EventLog[monitorName].First = EventLog[monitorName].First + 1
			moreFound = true
		end
	end

	-- if no entry to return
	if entryToSend == nil then
		return
	end

	-- filter returned args
	local toSend = {}
	if returnFilter then
		for val in string.gmatch(returnFilter,"[^]+(.*)[,]+") do
			local val = tonumber(val)
			if val and entryToSend.Args[val] then
				table.insert(toSend,entryToSend.Args[val])
			end
		end
	else
		for k, v in pairs(entryToSend.Args) do
			if v ~= nil  then
				table.insert(toSend,v)
			end
		end
	end

	entryToSend.Args = toSend

	return entryToSend.Time, moreFound, unpack(entryToSend.Args)
end

function igf_events:getLastEventMessage(event, text, age)
	if not LastMessageLog[event] then
		SendSystemChat("Bad LastMessage event used "..(event or "nil"))
		return
	end

	if text then text = string.lower(text) end

	if LastMessageLog[event][text] then
		if age == nil or (GetTime()-LastMessageLog[event][text]) <= age then
			return LastMessageLog[event][text], text
		end
	else
		for message, time in pairs(LastMessageLog[event]) do
			if string.match(message,text,1,true) then
				if age == nil or (GetTime()-time) <= age then
					return time, message
				end
			end
		end
	end
end

function igf_events:getLastEnemyDamage()
	return _lastTargetTime, _lastTargetDamage, _lastTargetTarget, _lastTargetSkill, _lastTargetType
end

function igf_events:getLastPlayerDamage()
	return _lastPlayerTime, _lastPlayerDamage, _lastPlayerSource, _lastPlayerSkill, _lastPlayerType
end

function igf_events:getLastPlayerBlockTime()
	return _lastPlayerBlock
end

function igf_events:getLastPlayerDodgeTime()
	return _lastPlayerDodge
end

function igf_events:getLastEnemyCriticalTime()
	return _lastEnemyCritical
end

function igf_events:getLastEnemyDodgeTime()
	return _lastEnemyDodge
end