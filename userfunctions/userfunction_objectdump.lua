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

    local size = 0x1000;
    local outfile = io.open(filename, 'w');

    outfile:write(sprintf("Dump of 0x%X\n", object.Address))

    for i = 0, size-1 do
        local addr = object.Address + i;
        local value = memoryReadUByte(getProc(), addr);

        if( i == 0 or (i % 16) == 0 ) then
            outfile:write(sprintf("\n%08x:\t", i));
        end
        if( value ~= nil ) then
            outfile:write(sprintf("%02x", value));
        else
            outfile:write("--");
        end

        if( i == size ) then
            outfile:write("\n");
        elseif( (i % 16) < 15 ) then
            outfile:write(" ");
        end
    end
    outfile:close();
end
