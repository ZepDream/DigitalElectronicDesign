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
rem  Why the extra step: ModelSim always saves absolute paths into
rem  the mpf. This script removes the project-root prefix after the
rem  project is created, so the entries become rtl\xxx.v / tb\xxx.v
rem  and the whole folder can be moved anywhere.
rem ============================================================
setlocal
cd /d "%~dp0.."

if not defined MODELTECH call :find_modelsim
if defined MODELTECH set "PATH=%MODELTECH%;%PATH%"

where vsim >nul 2>nul
if errorlevel 1 (
    echo.
    echo *** vsim.exe not found. Set MODELTECH first, e.g.
    echo ***     set MODELTECH=C:\ZZJ\APP\modeltech64_10.6e\win64
    pause
    exit /b 1
)

echo [ModelSim] %MODELTECH%
echo Rebuilding exp3.mpf ...

if exist exp3.mpf ren exp3.mpf exp3.mpf.bak

vsim -c -do "project new . exp3; project addfile rtl/spi_master.v; project addfile rtl/spi_slave.v; project addfile rtl/spi_top.v; project addfile tb/tb_spi_top.v; quit -f"

if not exist exp3.mpf (
    echo.
    echo *** Failed to create the project, restoring the old mpf.
    if exist exp3.mpf.bak ren exp3.mpf.bak exp3.mpf
    pause
    exit /b 1
)

rem  Strip the "current project root + slash" prefix, so the file
rem  entries become relative; also turn on the soft-path option and
rem  point the modelsim.ini reference at $MODEL_TECH (install-independent).
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='exp3.mpf'; $root=(Get-Location).Path.Replace('\','/') + '/'; $mt=$env:MODELTECH.Replace('\','/'); $t=[IO.File]::ReadAllText($p); $t=$t.Replace($root,'').Replace($mt + '/../modelsim.ini','$MODEL_TECH/../modelsim.ini').Replace('ForceSoftPaths = 0','ForceSoftPaths = 1'); [IO.File]::WriteAllText($p,$t,[Text.Encoding]::ASCII)"

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
    "C:\ZZJ\APP\modeltech64_10.6e\win64"
    "C:\modeltech64_10.6e\win64"
    "C:\Programs\modeltech64_10.6e\win64"
    "C:\intelFPGA\17.1\modelsim_ase\win32aloem"
    "C:\ZZJ\APP\intelFPGA\17.1\modelsim_ase\win32aloem"
) do (
    if not defined MODELTECH if exist "%%~D\vsim.exe" set "MODELTECH=%%~D"
)
exit /b 0
