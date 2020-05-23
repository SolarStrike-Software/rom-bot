local path = getExecutionPath();
local dir = getFilePath(path .. "/../");

if( string.sub(path, 1, #dir) == dir ) then
	local loc = #dir + 1;
	if( string.sub(path, loc, loc) == "/" ) then
		loc = loc + 1;
	end
	path = string.sub(path, loc);
end

error(sprintf("Update script is deprecated\nUse %s/addrupdate instead.", path));
