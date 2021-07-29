local path = getExecutionPath();
local dev = false;

local tag = nil;
for i,arg in pairs(args) do
    if( arg == "--dev" ) then
        tag = "latest";
    end
end


-- Try to get the latest release version
if( tag == nil ) then
    local cmd = sprintf('cd "%s" && bin\\rombot_updater.exe check', path);
    local results = io.popen(cmd):read('*a');
    local releases = results:gmatch("[^\r\n]+")
    releases() -- discard first results ("Recent releases:" string)
    tag = releases()
end


cprintf_ex("|white|Installing RoM-bot `|turquoise|%s|white|`... ", tag)

local cmd = sprintf('cd "%s" && bin\\rombot_updater.exe update', path);
local results = io.popen(cmd):read('*a');

if( string.find(results, "status 200") ) then
    cprintf_ex("|lightgreen|OK|white|!\n")
else
    cprintf(cli.red, "Failed!\n");
    print(results)
end
