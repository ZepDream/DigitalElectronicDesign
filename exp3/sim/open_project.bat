@echo off
rem ============================================================
rem  exp3 : open exp3.mpf as a ModelSim project (GUI)
rem  Use this when double-clicking exp3.mpf does nothing because
rem  the .mpf extension is not associated with ModelSim.
rem  Local install: C:\ZZJ\APP\modeltech64_10.6e\win64
rem ============================================================
setlocal
cd /d "%~dp0"

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

set "VSIM_EXE="
for /f "delims=" %%V in ('where vsim 2^>nul') do if not defined VSIM_EXE set "VSIM_EXE=%%V"
echo [ModelSim] %VSIM_EXE%

rem  After the project is open: Compile > Compile All, then run
rem      do spi_wave.do
rem      run -all
vsim -gui -do "project open exp3.mpf"
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
