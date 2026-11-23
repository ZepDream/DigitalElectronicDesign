@echo off
rem ============================================================
rem  exp3 : SPI master/slave loop-back simulation (batch mode)
rem  ModelSim SE-64 10.6e
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

vsim -c work.tb_spi_top -do "run -all; quit -f"
if "%~1"=="" pause
goto :eof

:compile_error
echo.
echo *** Compile failed, please check the vlog messages above. ***
exit /b 1
