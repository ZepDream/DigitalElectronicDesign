@echo off
rem ============================================================
rem  Rebuild exp3.mpf on THIS machine, with relative source paths
rem
rem  When to use:
rem    1. After cloning the repo, the paths stored in exp3.mpf may
rem       not match this machine;
rem    2. ModelSim rewrote exp3.mpf into absolute paths when the
rem       project was opened, and you want relative paths again.
rem
rem  How it works: ModelSim always saves absolute paths into the mpf.
rem  This script creates the project, then rewrites the entries so that
rem  they read  ../rtl/xxx.v  and  ../tb/xxx.v  (relative to this sim
rem  folder). The whole exp3 folder can then be moved anywhere.
rem ============================================================
setlocal
cd /d "%~dp0"

if not defined MODELTECH call :find_modelsim
if defined MODELTECH set "PATH=%MODELTECH%;%PATH%"

where vsim >nul 2>nul
if errorlevel 1 (
    echo.
    echo *** vsim.exe not found. Set MODELTECH first, e.g.
    echo ***     set MODELTECH=G:\APP\modeltech64_10.6e\win64
    pause
    exit /b 1
)

echo [ModelSim] %MODELTECH%
echo Rebuilding exp3.mpf ...

if exist exp3.mpf ren exp3.mpf exp3.mpf.bak

vsim -c -do "project new . exp3; project addfile ../rtl/spi_slave.v; project addfile ../tb/spi_master.v; project addfile ../tb/spi_top.v; project addfile ../tb/tb_spi_top.v; quit -f"

if not exist exp3.mpf (
    echo.
    echo *** Failed to create the project, restoring the old mpf.
    if exist exp3.mpf.bak ren exp3.mpf.bak exp3.mpf
    pause
    exit /b 1
)

rem  Strip the "project root + slash" prefix, then add ../ in front of the
rem  tb/ and rtl/ entries (the sources live one level above this folder).
rem  Also turn on the soft-path option and point the modelsim.ini
rem  reference at $MODEL_TECH, so the file is install-independent.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='exp3.mpf'; $root=(Get-Location).Path.Replace('\','/') + '/'; $mt=$env:MODELTECH.Replace('\','/'); $t=[IO.File]::ReadAllText($p); $t=$t.Replace($root,'').Replace('= tb/','= ../tb/').Replace('= rtl/','= ../rtl/').Replace($mt + '/../modelsim.ini','$MODEL_TECH/../modelsim.ini').Replace('ForceSoftPaths = 0','ForceSoftPaths = 1'); [IO.File]::WriteAllText($p,$t,[Text.Encoding]::ASCII)"

if errorlevel 1 (
    echo.
    echo *** Path rewrite failed, restoring the old mpf.
    del /q exp3.mpf
    if exist exp3.mpf.bak ren exp3.mpf.bak exp3.mpf
    pause
    exit /b 1
)

if exist exp3.mpf.bak del /q exp3.mpf.bak
if exist work rmdir /s /q work

echo.
echo Done. Source files stored in exp3.mpf:
findstr /b /c:"Project_File_" exp3.mpf
pause
goto :eof

:find_modelsim
for %%D in (
    "G:\APP\modeltech64_10.6e\win64"
    "D:\APP\modeltech64_10.6e\win64"
    "C:\ZZJ\APP\modeltech64_10.6e\win64"
    "C:\modeltech64_10.6e\win64"
    "C:\Programs\modeltech64_10.6e\win64"
    "G:\APP\Quartus\17.1\modelsim_ase\win32aloem"
    "C:\intelFPGA\17.1\modelsim_ase\win32aloem"
) do (
    if not defined MODELTECH if exist "%%~D\vsim.exe" set "MODELTECH=%%~D"
)
exit /b 0
