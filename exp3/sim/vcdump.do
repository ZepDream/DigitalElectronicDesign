#=============================================================================
# vcdump.do —— 把关键信号导出成 VCD（画波形图 / 给别的工具看）
#   用法（在 sim 目录下）：
#       vsim -c work.tb_spi_top -do "do vcdump.do"
#   产物：../images/wave.vcd（可用 GTKWave 打开）
#   注意：不要加 clk，50 MHz 跑满全程会把 VCD 撑到几十 MB。
#=============================================================================
vcd file ../images/wave.vcd
vcd add /tb_spi_top/cs
vcd add /tb_spi_top/sck
vcd add /tb_spi_top/mosi
vcd add /tb_spi_top/miso
vcd add /tb_spi_top/dut/u_master/tx_dat
vcd add /tb_spi_top/dut/u_master/rx_dat
vcd add /tb_spi_top/dut/u_slave/shifter_in
vcd add /tb_spi_top/dut/u_slave/shifter_out
vcd add /tb_spi_top/dut/u_slave/bit_cnt
vcd add /tb_spi_top/dut/u_slave/rx_dat
vcd add /tb_spi_top/dut/u_slave/tx_dat
vcd add /tb_spi_top/dut/u_slave/sck_fall
vcd add /tb_spi_top/dut/u_slave/sck_rise
vcd add /tb_spi_top/dut/u_slave/cs_fall
run -all
quit -f
