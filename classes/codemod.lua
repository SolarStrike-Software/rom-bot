
CCodeMod = class(function(self, base, origCode, replacement)
	self.base = base;
	self.origCode = origCode;
	self.replacement = replacement;
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
			break;
		end
	end
	
	return modified;
end

function CCodeMod:safeInstall()
	if( not self:checkModified() ) then
		self:install();
		return true;
	end
	
	return false;
end