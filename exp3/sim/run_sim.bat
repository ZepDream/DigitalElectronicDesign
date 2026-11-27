@echo off
rem ============================================================
rem  exp3 : SPI loop-back (master model + EPM240 slave) -- batch mode
rem  Compiles rtl + tb, runs the self-checking testbench and
rem  prints PASS / FAIL in the console.
rem  Local install: G:\APP\modeltech64_10.6e\win64
rem  Usage: run_sim.bat            (pause at the end)
rem         run_sim.bat nopause    (no pause, for scripting)
rem ============================================================
setlocal
cd /d "%~dp0"

rem ---------- 1. locate ModelSim ------------------------------
rem  MODELTECH may be preset in the environment (e.g. set MODELTECH=D:\modelsim\win64).
rem  Otherwise try the usual install paths, and finally accept a vsim already on PATH.
if not defined MODELTECH call :find_modelsim
if defined MODELTECH set "PATH=%MODELTECH%;%PATH%"

where vsim >nul 2>nul
if errorlevel 1 (
    echo.
    echo *** vsim.exe not found.
    echo *** Set MODELTECH to the ModelSim folder that contains vsim.exe, e.g.
    echo ***     set MODELTECH=G:\APP\modeltech64_10.6e\win64
    exit /b 1
)
rem  show the vsim that will actually be used (the first match on PATH)
set "VSIM_EXE="
for /f "delims=" %%V in ('where vsim 2^>nul') do if not defined VSIM_EXE set "VSIM_EXE=%%V"
echo [ModelSim] %VSIM_EXE%
echo.

rem ---------- 2. compile -------------------------------------
if exist work rmdir /s /q work
vlib work
vmap work work >nul
vlog -work work ..\rtl\spi_slave.v ..\tb\spi_master.v ..\tb\spi_top.v ..\tb\tb_spi_top.v
if errorlevel 1 goto :compile_error

rem ---------- 3. run -----------------------------------------
vsim -c work.tb_spi_top -do "run -all; quit -f"
if /i not "%~1"=="nopause" pause
goto :eof

:compile_error
echo.
echo *** Compile failed, please check the vlog messages above. ***
exit /b 1

rem ---------- helper: auto-detect the install folder ---------
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
