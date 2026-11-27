#=============================================================================
# spi_wave.do —— SPI 回环测试的波形窗口设置
#   用法：在 ModelSim 里编译、加载 tb_spi_top 之后执行
#       do spi_wave.do
#       run 300us
#   运行 run_gui.bat 会自动执行这两步。
#
#   信号按用途分成四组：时钟与复位、SPI 总线、主机内部、从机内部。
#   总线上看到的是“现象”，主机/从机内部看到的是“原因”，两组对照着看最清楚。
#=============================================================================
onerror {resume}
quietly WaveActivateNextPane {} 0

# ---- 第一组：时钟、复位、使能 ----
add wave -noupdate -divider {Clock / Reset}
add wave -noupdate /tb_spi_top/clk
add wave -noupdate /tb_spi_top/rst_n
add wave -noupdate /tb_spi_top/run

# ---- 第二组：SPI 总线（四根线，主机和从机共用）----
add wave -noupdate -divider {SPI Bus}
add wave -noupdate /tb_spi_top/spi_cs
add wave -noupdate /tb_spi_top/spi_sck
add wave -noupdate /tb_spi_top/spi_mosi
add wave -noupdate /tb_spi_top/spi_miso

# ---- 第三组：主机内部状态 ----
# state 用无符号数看（0/1/2/3 对应 IDLE/FALL/RISE/END），
# 数据类信号用十六进制看，bit_cnt 用无符号数看，符合读波形的习惯。
add wave -noupdate -divider {Master}
add wave -noupdate -radix unsigned /tb_spi_top/dut/u_master/state
add wave -noupdate /tb_spi_top/dut/u_master/busy
add wave -noupdate -radix hexadecimal /tb_spi_top/m_tx_data
add wave -noupdate -radix hexadecimal /tb_spi_top/m_rx_data
add wave -noupdate -radix hexadecimal /tb_spi_top/dut/u_master/shifter
add wave -noupdate -radix hexadecimal /tb_spi_top/dut/u_master/rx_sh
add wave -noupdate -radix unsigned /tb_spi_top/dut/u_master/bit_cnt

# ---- 第四组：从机内部状态 ----
# 最后四个边沿脉冲是理解从机的关键：
# 每个真实边沿只对应一个单周期脉冲，说明两级同步 + 边沿检测没有重复响应。
add wave -noupdate -divider {Slave}
add wave -noupdate -radix hexadecimal /tb_spi_top/s_tx_data
add wave -noupdate -radix hexadecimal /tb_spi_top/s_rx_data
add wave -noupdate -radix hexadecimal /tb_spi_top/dut/u_slave/shifter_in
add wave -noupdate -radix hexadecimal /tb_spi_top/dut/u_slave/shifter_out
add wave -noupdate -radix unsigned /tb_spi_top/dut/u_slave/bit_cnt
add wave -noupdate /tb_spi_top/dut/u_slave/cs_fall
add wave -noupdate /tb_spi_top/dut/u_slave/sck_fall
add wave -noupdate /tb_spi_top/dut/u_slave/cs_rise
add wave -noupdate /tb_spi_top/dut/u_slave/sck_rise

# 信号名前面显示一层层次名（如 u_slave/），时间轴用微秒
configure wave -signalnamewidth 1
configure wave -timelineunits us
update
