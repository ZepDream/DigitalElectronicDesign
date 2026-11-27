@echo off
rem ============================================================
rem  exp3 : open the ModelSim SE-64 GUI and show the SPI waves
rem  The simulation runs to 300 us (16 complete frames) so that
rem  the Wave window can be inspected interactively.
rem  Local install: C:\ZZJ\APP\modeltech64_10.6e\win64
rem ============================================================
setlocal
cd /d "%~dp0"

rem ---------- 1. locate ModelSim ------------------------------
if not defined MODELTECH call :find_modelsim
if defined MODELTECH set "PATH=%MODELTECH%;%PATH%"

where vsim >nul 2>nul
if errorlevel 1 (
    echo.
    echo *** vsim.exe not found.
    echo *** Set MODELTECH to the ModelSim folder that contains vsim.exe, e.g.
    echo ***     set MODELTECH=C:\ZZJ\APP\modeltech64_10.6e\win64
    pause
    exit /b 1
)
set "VSIM_EXE="
for /f "delims=" %%V in ('where vsim 2^>nul') do if not defined VSIM_EXE set "VSIM_EXE=%%V"
echo [ModelSim] %VSIM_EXE%

rem ---------- 2. compile -------------------------------------
if exist work rmdir /s /q work
vlib work
vmap work work >nul
vlog -work work ..\rtl\spi_master.v ..\rtl\spi_slave.v ..\rtl\spi_top.v ..\tb\tb_spi_top.v
if errorlevel 1 goto :compile_error

rem ---------- 3. open the GUI with the wave setup -------------
vsim -gui -voptargs=+acc work.tb_spi_top -do "do spi_wave.do; run 300us"
goto :eof

:compile_error
echo.
echo *** Compile failed, please check the vlog messages above. ***
pause
exit /b 1

rem ---------- helper: auto-detect the install folder ---------
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
