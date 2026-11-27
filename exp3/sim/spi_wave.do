#=============================================================================
# spi_wave.do —— 回环仿真的波形窗口设置
#   用法：在 ModelSim 里编译、加载 tb_spi_top 之后执行
#       do spi_wave.do
#       run -all
#   运行 run_gui.bat 会自动执行这两步。
#
#   信号分三组：时钟、SPI 总线、主机/从机内部。
#   总线是“现象”，移位寄存器和边沿脉冲是“原因”。
#=============================================================================
onerror {resume}
quietly WaveActivateNextPane {} 0

# ---- 第一组：时钟 ----
add wave -noupdate -divider {Clock}
add wave -noupdate /tb_spi_top/clk

# ---- 第二组：SPI 总线（四根线，主机和从机共用）----
add wave -noupdate -divider {SPI Bus}
add wave -noupdate /tb_spi_top/cs
add wave -noupdate /tb_spi_top/sck
add wave -noupdate /tb_spi_top/mosi
add wave -noupdate /tb_spi_top/miso

# ---- 第三组：主机（仿真模型）----
add wave -noupdate -divider {Master}
add wave -noupdate -radix hexadecimal /tb_spi_top/dut/u_master/tx_dat
add wave -noupdate -radix hexadecimal /tb_spi_top/dut/u_master/rx_dat
add wave -noupdate -radix hexadecimal /tb_spi_top/dut/u_master/cmd_now

# ---- 第四组：从机边沿检测 ----
# 四个脉冲都是一个时钟宽，说明一个真实边沿只被响应一次
add wave -noupdate -divider {Slave / edge}
add wave -noupdate /tb_spi_top/dut/u_slave/cs_tmp
add wave -noupdate /tb_spi_top/dut/u_slave/sck_tmp
add wave -noupdate /tb_spi_top/dut/u_slave/cs_fall
add wave -noupdate /tb_spi_top/dut/u_slave/cs_rise
add wave -noupdate /tb_spi_top/dut/u_slave/sck_fall
add wave -noupdate /tb_spi_top/dut/u_slave/sck_rise

# ---- 第五组：从机的移位寄存器与收发数据 ----
add wave -noupdate -divider {Slave / shifter}
add wave -noupdate -radix hexadecimal /tb_spi_top/dut/u_slave/shifter_in
add wave -noupdate -radix hexadecimal /tb_spi_top/dut/u_slave/shifter_out
add wave -noupdate -radix unsigned  /tb_spi_top/dut/u_slave/bit_cnt
add wave -noupdate -radix hexadecimal /tb_spi_top/dut/u_slave/rx_dat
add wave -noupdate -radix hexadecimal /tb_spi_top/dut/u_slave/tx_dat

configure wave -signalnamewidth 1
configure wave -timelineunits us
WaveRestoreZoom {0 ns} {300 us}
update
