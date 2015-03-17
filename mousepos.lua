function main()
    local lastx, lasty = 0,0;
    while(true) do
        local mx, my = mouseGetPos();
        local win = foregroundWindow();
        local wx, wy = windowRect(win);
        mx = mx - wx; my = my - wy;

        if( mx ~= lastx or my ~= lasty ) then
            printf("\rPos: (%d, %d)\t", mx, my);
            lastx = mx; lasty = my;
        end
        yrest(100);
    end
end
startMacro(main, true);