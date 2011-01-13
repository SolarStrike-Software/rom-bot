@echo off
FOR /F "tokens=1 delims=" %%A in ('cd') do SET folder=%%A
START ../../micromacro.exe "%folder%/bot.lua"