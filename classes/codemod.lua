
CCodeMod = class(function(self, base, origCode, replacement)
	self.base = base;
	self.origCode = origCode;
	self.replacement = replacement;
	
	if( self.base) then
		if( not origCode ) then
			error("Cannot create a codemod without original code", 3);
		end
		
		if( not replacement ) then
			error("Cannot create a codemod without replacement code", 3);
		end
	end
end);

function CCodeMod:install()
	local address = getBaseAddress(self.base);
	memoryWriteString(getProc(), address, self.replacement);
end

function CCodeMod:uninstall()
	local address = getBaseAddress(self.base);
	memoryWriteString(getProc(), address, self.origCode);
end

function CCodeMod:checkModified()
	local address = getBaseAddress(self.base);
	local currentData = memoryReadBatch(getProc(), address, string.rep('B', #self.origCode));
	local modified = false;
	for i,v in pairs(currentData) do
		-- reading batches of unsigned bytes isn't working correctly for some reason,
		-- so we manually convert it instead.
		if( v < 0 ) then v = v + 256; end;
		
		local expectedByte = string.byte(self.origCode:sub(i, i + 1));
		
		if( v ~= expectedByte ) then
			modified = false;
			--printf("0x%X <> 0x%X = false\n", expectedByte, v);
			break;
		else
			--printf("0x%X <> 0x%X = true\n", expectedByte, v);
		end
	end
	
	return modified;
end

function CCodeMod:checkInstalled()
	local address = getBaseAddress(self.base);
	local currentData = memoryReadBatch(getProc(), address, string.rep('B', #self.replacement));
	local installed = true;
	for i,v in pairs(currentData) do
		-- reading batches of unsigned bytes isn't working correctly for some reason,
		-- so we manually convert it instead.
		if( v < 0 ) then v = v + 256; end;
		
		local expectedByte = string.byte(self.replacement:sub(i, i + 1));
		if( v ~= expectedByte ) then
			installed = false;
			break;
		end
	end
	
	return installed;
end


function CCodeMod:safeInstall()
	-- Is it in its original state?
	local state = self:checkModified();
	if( self:checkModified() == false ) then
		self:install();
		return true;
	end
	
	-- Is it already installed? Pretend it was successful
	if( self:checkInstalled() == true ) then
		return true;
	end
	
	-- Didn't work
	return false;
end

function CCodeMod:safeUninstall()
	if( self:checkInstalled() == true ) then
		self:uninstall();
		return true;
	end
	
	return false;
end