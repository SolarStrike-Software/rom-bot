
local gitForWindowsUrl = 'https://git-scm.com/download/win';
local url = 'https://github.com/SolarStrike-Software/rom-bot.git';
local branch = 'version7.4.0.2897'; -- Leave as nil to use master, or specify another branch here.

local scriptName = fixSlashes(args[1]);

function isGitInstalled()
	local file = io.popen('where git');
	local res = file:read("*a");
	return res ~= "";
end

function backup()
	local path = getExecutionPath();
	local backupName = 'gitupdate-backup';
	
	printf("Backing up current code to %s\n", backupName);
	
	local cmd = sprintf('cd "%s" && if exist "%s/" rd /s /q "%s" && robocopy . %s /s /e /xd %s',
		path, backupName, backupName, backupName, backupName);
	
	system(cmd);
end

function checkout()
	local path = getExecutionPath();
	local tmpName = '.tmp';
	local branchPart = sprintf('-b %s', branch);
	
	system(sprintf('cd "%s" && git clone %s %s %s && xcopy /E /H /-Y /Q %s . && rd /s /q "%s"',
		path, branchPart, url, tmpName, tmpName, tmpName));

	local msg = sprintf("Completed checkout.");
	printf("%s\n", msg);
	logMessage(msg);
end

function trim(str)
	return str:gsub("^%s*(.-)%s*$", "%1");
end

function update()
	local path = getExecutionPath();
	local currentBranch = io.popen(sprintf('cd "%s" && git rev-parse --abbrev-ref HEAD', path)):read('*a');
	local origRevision = io.popen(sprintf('cd "%s" && git rev-parse --short HEAD', path)):read('*a');
	
	currentBranch = trim(currentBranch);
	origRevision = trim(origRevision);
	
	local result = '';
	local cmd = '';
	if( currentBranch ~= branch ) then
		-- Switch branch before pull
		printf("`%s`, `%s`\n", currentBranch, branch);
		cmd = sprintf('cd "%s" && git checkout %s', path, branch);
		system(cmd);
	end
	
	cmd = sprintf('cd "%s" && git fetch origin && git pull', path);
	result = io.popen(cmd):read('*a');
	print(result);
	if( result:find('Already up to date.') == nil ) then
		local newRevision = io.popen(sprintf('cd "%s" && git rev-parse --short HEAD', path)):read('*a');
		newRevision = trim(newRevision);
	
		printLog(origRevision, newRevision);
	end
end

function printLog(oldRevision, newRevision)
	newRevision = newRevision or 'HEAD';
	local path = getExecutionPath();
	
	local cmd = sprintf('cd %s && git log --abbrev-commit --pretty=oneline %s..%s', path, oldRevision, newRevision);
	print(system(cmd));
end

function main()
	branch = branch or 'master';
	if( not allowSystemCommands ) then
		error("You must allow system commands in your config file in order to use this script.", 0);
	end
	
	if( not isGitInstalled() ) then
		print("Git is not installed. You must install git first.");
		print("Let me help you with that...\n\n");
		rest(1500);
		system(sprintf('start "" %s', gitForWindowsUrl));
		print("Please install Git, then press any key to continue...");
		system("pause");
		io.popen(sprintf('START micromacro \"%s\"', scriptName));
		os.exit();
		return;
	end
	
	if( not getDirectory(getExecutionPath() .. "/.git") ) then
		warning("Git has not been configured for this path yet. You must do so now.");
		backup();
		checkout();
	else
		backup();
		update();
	end
end
main();