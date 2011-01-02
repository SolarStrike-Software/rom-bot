@echo off
ECHO YOU MUST HAVE TORTOISEVN INSTALLED FOR THIS TO WORK!
ECHO If you do not have TortoiseSVN installed, expect problems.
FOR /F "tokens=1 delims=" %%A in ('cd') do SET folder=%%A
START ../../micromacro.exe "%folder%/svnupdate.lua"