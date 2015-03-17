--[[
	Options:
		revert	-	Remove all changes made by the user before attempting an SVN update
]]

function checkout()
	warning("TortoiseSVN has not been configured for this path yet. You must do so now.");
	local path = getExecutionPath();
	local cmd = sprintf("TortoiseProc /command:checkout /path:\"%s\" /url:http://rom-bot.googlecode.com/svn/trunk/rom", path);
	system(cmd);

	local msg = sprintf("Completed SVN checkout.");
	printf("%s\n", msg);
	logMessage(msg);
end

function update(options)
	local path = getExecutionPath();
	local msg = sprintf("Attempting SVN update of path \'%s\'", path);
	printf("%s\n", msg);
	logMessage(msg);

	if( options.revert ) then
		-- Revert any changes first
		warning("Reverting user changes...");
		local cmd = sprintf("TortoiseProc /command:revert /path:\"%s\"", path);
		system(cmd);
	end

	local cmd = sprintf("TortoiseProc /command:update /path:\"%s\" /notempfile /closeonend:2", path);
	system(cmd);
end

function main()
	local options = {
		revert = false;
	};
	for i,v in pairs(args) do
		if( v == "revert" ) then
			options.revert = true;
		end
	end

	if( not allowSystemCommands ) then
		error("You must allow system commands in your config file in order to use this script.", 0);
	end

	if( not getDirectory(getExecutionPath() .. "/.svn") ) then
		checkout(); -- Configure the directory for TortoiseSVN
	end

	update(options); -- Perform an SVN update

	printf("Finished. You should now be up-to-date (if no error occured).\n");
end
main();