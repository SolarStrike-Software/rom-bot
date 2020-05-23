
local gitForWindowsUrl = 'https://git-scm.com/download/win';
local url = 'https://github.com/SolarStrike-Software/rom-bot.git';
local branch = nil; -- Leave as nil to use master, or specify another branch here.

local scriptName = fixSlashes(args[1]);
local options = {
	force = false;
};

for i = 2,#args do
	local arg = string.lower(args[i]);
	
	if( arg == "-f" or arg == "--force" ) then
		options.force = true;
	end
end

function isGitInstalled()
	local file = io.popen('where git');
	local res = file:read("*a");
	return res ~= "";
end

function backup()
	local path = getExecutionPath();
	local backupName = 'gitupdate-backup';
	local cmd;
	
	printf("Backing up current code to %s\n", backupName);
	
	-- Remove old folder if it exists
	local backupFullPath = sprintf("%s/%s", path, backupName);
	cmd = sprintf('if exist "%s/" rd /s /q "%s"', backupFullPath, backupFullPath);
	
	-- Backup into the folder
	local cmd = sprintf('robocopy %s %s /s /e /xd %s',
		path, backupFullPath, backupName);
	
	system(cmd);
end

function checkout()
	local path = getExecutionPath();
	local tmpName = '.tmp';
	local branchPart = sprintf('-b %s', branch);
	
	local cmd;
	
	-- Remove tmp folder if needed
	local tmpFullPath = sprintf("%s/%s", path, tmpName);
	cmd = sprintf('if exist "%s/" rd /s /q "%s"', tmpFullPath, tmpFullPath);
	system(cmd);
	
	-- Clone branch into temp directory (this gets around the "directory is not empty" issue)
	cmd = sprintf('cd "%s" && git clone %s %s %s',
		path, branchPart, url, tmpName);
	system(cmd);
		
	-- Copy from temporary storage into main directory
	cmd = sprintf('robocopy /s /e "%s" "%s"', tmpFullPath, path);
	system(cmd);
	
	
	-- Remove tmp folder (again)
	cmd = sprintf('if exist "%s/" rd /s /q "%s"', tmpFullPath, tmpFullPath);
	system(cmd);
	
	
	local msg = sprintf("Completed checkout.");
	print(msg);
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
	
	local optionalForceCmd = "";
	if( options.force ) then
		cprintf_ex("|yellow|[!]|gray|Forcing hard git reset; uncommitted changes will be lost.");
		optionalForceCmd = sprintf(" git reset --hard origin/%s &&", branch or 'master');
	end
	
	cmd = sprintf('cd "%s" && git fetch origin &&%s git pull', path, optionalForceCmd);
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
		warning("Git has not been configured for this path yet. Doing project checkout now.");
		backup();
		checkout();
	else
		backup();
		update();
	end
end
main();