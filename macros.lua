commandMacro = 0
resultMacro = 0

COMMAND_MACRO_NAME = "RB Command"
RESULT_MACRO_NAME = "RB"

function setupMacros()
	-- See if there is old version macros
	local body, name, icon, id = readMacro(1)
	if( settings.options.LANGUAGE == "spanish" ) then
		scriptDef = "/redactar";
	else
		scriptDef = "/script";
	end
	local oldpattern = scriptDef.." r='' a={.*" ..
	"} for i=1,#a do r=r\.\.tostring.a.i.." ..
	" r=r\.\.'\t' end" ..
	" EditMacro.2,'',7,r.;";

	if name ~= COMMAND_MACRO_NAME and
			string.match(body,oldpattern) then
		-- Safe to assume old macros so use macro 1 and 2
		commandMacro = 1
		writeToMacro(commandMacro, null, COMMAND_MACRO_NAME, 1)
		resultMacro = 2
		writeToMacro(resultMacro, null, RESULT_MACRO_NAME, 7)
	else
		-- Find commandMacro
		commandMacro = findMacroByName(COMMAND_MACRO_NAME)
		if commandMacro == null then -- No command macro found.
			commandMacro = findEmptyMacro() -- Find an empty.
			if commandMacro then -- Name the new macro
				writeToMacro(commandMacro, null, COMMAND_MACRO_NAME, 1)
			else
				error("No empty macros left.")
			end
		end
		-- Find resultMacro
		resultMacro = findMacroByName(RESULT_MACRO_NAME)
		if resultMacro == null then -- No result macro found.
			resultMacro = findEmptyMacro() -- Find an empty.
			if resultMacro then -- Name the new macro
				writeToMacro(resultMacro, null, RESULT_MACRO_NAME, 7)
			else
				error("No empty macros left.")
			end
		end
	end

	if(settings.options.DEBUGGING_MACRO) then
		printf("commandMacro set to " .. commandMacro .. ".\n")
		printf("resultMacro set to " .. resultMacro .. ".\n")
	end

	setupMacroHotkey()
	setupAttackKey()
	-- To do: setupSkillKeys()
end

function setupMacroHotkey()
	-- Find the action key that points to the command macro.
	local actionKey, hotkey = findActionKeyForMacro(commandMacro)
	if actionKey then
		-- A hotkey for the macro is no longer needed.
		printf("You no longer need to place the macro into the actionbar. It will be removed.\n")
		setActionKeyToId(actionKey, "delete")
	end

	-- Set settings.profile.hotkeys.MACRO.key
	local hotkey, modifier = getHotkeyByName("TOGGLEPLATES") -- The "Toggle title/guild" hotkey
	if hotkey == 0 or modifier ~= nil then
		error("Please assign a hotkey to 'Show title/guild' in the games 'Key Bindings' interface. Dont use a modifier(CTRL,SHIFT,ALT).")
	end
	settings.profile.hotkeys.MACRO.key = hotkey

	if( settings.options.DEBUGGING_MACRO ) then
		printf("The macro hotkey is ".. string.char(hotkey) .. ".\n")
	end
end

settings.profile.hotkeys.AttackType = nil
function setupAttackKey()
	settings.profile.hotkeys.AttackType = nil

	-- See if user speicfied a prefered key.
	if settings.profile.hotkeys.ATTACK and string.lower(settings.profile.hotkeys.ATTACK.key) ~= "macro" then
		-- First see if 'Attack' already exists in action bar
		local tmpActionKey , tmpkey = findActionKeyForId(540000)
		if tmpkey ~= nil then
			settings.profile.hotkeys.AttackType = tmpkey
		else
			local actionkey, hotkey = findUsableActionKey(settings.profile.hotkeys.ATTACK.key)
			if actionkey and hotkey then
				settings.profile.hotkeys.AttackType = hotkey
				setActionKeyToId(actionkey, 540000)
			end
		end
	end

	if settings.profile.hotkeys.AttackType == nil then
		settings.profile.hotkeys.AttackType = "macro"
	end

	if( settings.options.DEBUGGING_MACRO ) then
		printf("The 'Attack' hotkey is set to '".. settings.profile.hotkeys.AttackType .. "'.\n")
	end
end

-- Macro functions
function writeToMacro(macroNum, body, name, icon)
	-- Check macroNum
	if type(macroNum) ~= "number" or macroNum < 1 or macroNum > 49 then
		error("Macro number needs to be between 1 and 49.")
	end

	--- Get macros base address
	local macro_address = memoryReadUInt(getProc(), addresses.staticbase_macro);

	--- Write the macro body
	if body ~= null and type(body) == "string" then
		local byte;
		for i = 0, 254, 1 do
			byte = string.byte(body, i + 1);
			if( byte == nil or byte == 0 ) then
				byte = 0;

				memoryWriteByte(getProc(), macro_address + addresses.macroSize *(macroNum - 1) + addresses.macroBody_offset + i, 0);
				break;
			end
			memoryWriteByte(getProc(), macro_address + addresses.macroSize *(macroNum - 1) + addresses.macroBody_offset + i, byte);
		end
	end

	--- Write the macro name
	if name ~= null and type(name) == "string" then
		local byte;
		for i = 0, 31, 1 do
			byte = string.byte(name, i + 1);
			if( byte == nil or byte == 0 ) then
				byte = 0;

				memoryWriteByte(getProc(), macro_address + addresses.macroSize *(macroNum - 1) + addresses.macroName_offset + i, 0);
				break;
			end
			memoryWriteByte(getProc(), macro_address + addresses.macroSize *(macroNum - 1) + addresses.macroName_offset + i, byte);
		end
	end

	-- Set the macro icon
	if icon ~= null and type(icon) == "number" and icon > 0 and icon <= 60 then
		memoryWriteInt(getProc(), macro_address + addresses.macroSize *(macroNum - 1) + addresses.macroIcon_offset , icon);
	end

end

function readMacro(macroNum)
	if macroNum == null or type(macroNum) ~= "number" or macroNum < 1 or macroNum > 49 then
		error("The macro number must be a number between 1 and 49.")
	end

	--- Get macros base address
	local macro_address = memoryReadUInt(getProc(), addresses.staticbase_macro);

	--- Read the macro body
	local body = "";
	for i = 0, 254, 1 do
		local byte = memoryReadUByte(getProc(), macro_address + addresses.macroSize *(macroNum - 1) + addresses.macroBody_offset + i);

		if( byte == 0 ) then -- Break on NULL terminator
			break;
		else
			body = body .. string.char(byte);
		end
	end

	--- Read the macro name
	local name = "";
	for i = 0, 31, 1 do
		local byte = memoryReadUByte(getProc(), macro_address + addresses.macroSize *(macroNum - 1) + addresses.macroName_offset + i);

		if( byte == 0 ) then -- Break on NULL terminator
			break;
		else
			name = name .. string.char(byte);
		end
	end

	-- Read the macro icon
	local icon = memoryReadUInt(getProc(), macro_address + addresses.macroSize *(macroNum - 1) + addresses.macroIcon_offset);

	-- Read the macro id
	local id = memoryReadUInt(getProc(), macro_address + addresses.macroSize *(macroNum - 1) + addresses.macroId_offset);

	return body, name, icon, id
end


function searchForMacro(bodypattern, namematch, iconmatch, idmatch)
	if bodypattern == null and namematch == null and iconmatch == null and idmatch == null then
		error("You need to include at least 1 argument to the 'searchForMacro()' function.")
	end

	for i = 1, 49 do
		local body, name, icon, id = readMacro(i)
		if (namematch == null or name == namematch) and
			(iconmatch == null or icon == iconmatch) and
			(idmatch == null or id == idmatch) and
			(bodypattern == null or string.find(body,bodypattern)) then
			return i
		end
	end
end

function findMacroByName(macroName)
	return searchForMacro(null,macroName)
end

function findEmptyMacro()
	return searchForMacro("","",0xFFFFFFFF)
end

-- Action Key functions
function getActionKeyInfo(actionKey)
	local actionBar_base = memoryReadUInt(getProc(), addresses.actionBarPtr)
	local actionBar_offset = 0x640 * player.Class1
	local actionKey_offset = 0x14 * (actionKey - 1)
	local actionKey_address = actionBar_base + actionBar_offset + actionKey_offset
	local id =  memoryReadInt(getProc(), actionKey_address + addresses.actionKeyId_offset)
	local type =  memoryReadInt(getProc(), actionKey_address + addresses.actionKeyType_offset) -- 4 = macro, 3 = skill, 1 = item, 0 = empty
	return id, type
end

function setActionKeyToId(actionkey, id)
	local actionBar_base = memoryReadUInt(getProc(), addresses.actionBarPtr)
	local actionBar_offset = 0x640 * player.Class1
	local actionKey_offset = 0x14 * (actionkey - 1)
	local actionKey_address = actionBar_base + actionBar_offset + actionKey_offset

	-- write id
	if id == "delete" then
		memoryWriteInt(getProc(), actionKey_address + addresses.actionKeyId_offset, 0)
	else
		memoryWriteInt(getProc(), actionKey_address + addresses.actionKeyId_offset, id)
	end

	-- get type
	local type;
	if id == "delete" then
		type = 0 -- type empty
	elseif id >= 0 and id < 49 then
		type = 4 -- type macro
	elseif id > 490000 and id < 541000 then
		type = 3 -- type skill
	else
		type = 1 -- type item
	end
	-- Don't know if there is a type 2

	-- write type
	memoryWriteInt(getProc(), actionKey_address + addresses.actionKeyType_offset, type)
end

function setActionKeyToMacro(actionkey, macroNum)
	local __, __, __, macroId = readMacro(macroNum)
	setActionKeyToId(actionkey, macroId)
end

function findActionKeyForId(id)
	local firstActionKey = getHotkeyByName("ACTIONBAR1BUTTON1")

	-- Only returns usable action keys with a hotkey and no modifier.
	for i = 1, 80 do
		local keyId, type = getActionKeyInfo(i)
		if keyId == id  and type ~= 0 then -- need 'type' to be valid
			-- Check the hotkey and modifier
			local hotkey, modifier = getHotkey(firstActionKey - 1 + i) -- actionbars hotkeys start at 89 in the hotkeys list
			if hotkey ~= 0 and modifier == null then
				return i, hotkey
			end
		end
	end
end

function findActionKeyForMacro(macroNum)
	local __, __, __, macroId = readMacro(macroNum)
	return findActionKeyForId(macroId)
end

function findUsableActionKey(preferable)
	local firstActionKey = getHotkeyByName("ACTIONBAR1BUTTON1")

	-- Only returns usable action keys with a hotkey and no modifier.
	local bestkey, hotkey, modifier;
	for i = 1, 80 do
		-- if empty
		local keyId, type = getActionKeyInfo(i)
		if type == 0 then

			-- And has hotkey with no modifier
			hotkey, modifier = getHotkey(firstActionKey - 1 + i) -- actionbars hotkeys start at 89 in the hotkeys list
			if hotkey ~= 0 and modifier == null then
				-- Best choice is an empty with users chosen hotkey.
				if preferable and hotkey == preferable then
					return i, hotkey
				end

				-- remember the first empty so we can keep looking for the users hotkey.
				if bestkey == null then
					bestkey = i
					besthot = hotkey
				end
			end
		end
	end
	return bestkey, besthot
end

-- Hotkey functions
function getHotkey(number)
	local hotkeysTableAddress = memoryReadIntPtr(getProc(), addresses.hotkeysPtr, addresses.hotkeys_offset)
	local hotkeyAddress = memoryReadInt(getProc(), hotkeysTableAddress + (0x4 * (number - 1)))
	if hotkeyAddress < 1 then return end -- invalid number
	local hotkey = memoryReadUByte(getProc(), hotkeyAddress + addresses.hotkeysKey_offset)

	local name = memoryReadString(getProc(), hotkeyAddress + addresses.hotkeysName_offset)
	if name ~= string.match(name,"[%u%d_]*") or name == "" then
		name = memoryReadStringPtr(getProc(), hotkeyAddress + addresses.hotkeysName_offset, 0)
	end
	local tempModifier = memoryReadUByte(getProc(), hotkeyAddress + addresses.hotkeysKey_offset + 2)
	local modifier;
	if tempModifier == 1 then
		modifier = key.VK_SHIFT
	elseif tempModifier == 2 then
		modifier = key.VK_CONTROL
	elseif tempModifier == 4 then
		modifier = key.VK_ALT
	else
		modifier = null
	end

	return hotkey, modifier, name
end

function getHotkeyByName(_name)
	local number = 0
	local hotkey, modifier, name
	repeat
		number = number + 1
		hotkey, modifier, name = getHotkey(number)
		if hotkey == nil then
			return -- nothing found
		end
	until name == _name

	return hotkey, modifier, number
end
