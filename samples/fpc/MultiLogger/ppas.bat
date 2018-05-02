@echo off
SET THEFILE=QuickLoggerDemo.exe
echo Linking %THEFILE%
D:\Lazarus\fpc\bin\i386-win32\ld.exe -b pei-i386 -m i386pe  --gc-sections    --entry=_mainCRTStartup    -o QuickLoggerDemo.exe link.res
if errorlevel 1 goto linkend
D:\Lazarus\fpc\bin\i386-win32\postw32.exe --subsystem console --input QuickLoggerDemo.exe --stack 16777216
if errorlevel 1 goto linkend
goto end
:asmend
echo An error occurred while assembling %THEFILE%
goto end
:linkend
echo An error occurred while linking %THEFILE%
:end
