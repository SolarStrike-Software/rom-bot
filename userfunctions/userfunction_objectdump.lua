function objectDump(object, filename)
    if( filename == nil ) then
        object:update();
        path = getExecutionPath() .. "/objdump/";

        local dir = getDirectory(path);
        if( dir == nil ) then
            os.execute(sprintf('md "%s" >nul 2>&1', path));
        end

        local id = (object.Id or 0);
        local name = (object.Name or 'unknown');

        if( player ~= nil and object.Address == player.Address ) then
            name = 'Player';
        end
        filename = sprintf("%s%d-%s.dat", path, id, name);
    end

    local size = 0x400;
    local outfile = io.open(filename, 'w');

    for i = 0,size do
        local addr = object.Address + i;
        local value = memoryReadUByte(getProc(), addr);

        if( (i % 16) == 1 ) then
            outfile:write(sprintf("%08x:\t", i - 1));
        end
        outfile:write(sprintf("%02x", value));

        if( (i > 0 and i % 16 == 0) or i == size ) then
            outfile:write("\n");
        else
            outfile:write(" ");
        end
    end
    outfile:close();
end
