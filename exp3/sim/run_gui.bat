@echo off
rem ============================================================
rem  exp3 : open the ModelSim SE-64 GUI and show the SPI waves
rem  The simulation runs to 300 us (16 complete frames) so that
rem  the Wave window can be inspected interactively.
rem ============================================================
setlocal
set MODELTECH=G:\APP\modeltech64_10.6e\win64
set PATH=%MODELTECH%;%PATH%
cd /d "%~dp0"

if exist work rmdir /s /q work
vlib work
vmap work work >nul
vlog -work work ..\rtl\spi_master.v ..\rtl\spi_slave.v ..\rtl\spi_top.v ..\tb\tb_spi_top.v
if errorlevel 1 goto :compile_error

vsim -gui -voptargs=+acc work.tb_spi_top -do "do spi_wave.do; run 300us"
goto :eof

:compile_error
echo.
echo *** Compile failed, please check the vlog messages above. ***
exit /b 1
