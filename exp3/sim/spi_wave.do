#=============================================================================
# wave.do : ModelSim wave window setup for the SPI loop-back test
#=============================================================================
onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider {Clock / Reset}
add wave -noupdate /tb_spi_top/clk
add wave -noupdate /tb_spi_top/rst_n
add wave -noupdate /tb_spi_top/run

add wave -noupdate -divider {SPI Bus}
add wave -noupdate /tb_spi_top/spi_cs
add wave -noupdate /tb_spi_top/spi_sck
add wave -noupdate /tb_spi_top/spi_mosi
add wave -noupdate /tb_spi_top/spi_miso

add wave -noupdate -divider {Master}
add wave -noupdate -radix unsigned /tb_spi_top/dut/u_master/state
add wave -noupdate /tb_spi_top/dut/u_master/busy
add wave -noupdate -radix hexadecimal /tb_spi_top/m_tx_data
add wave -noupdate -radix hexadecimal /tb_spi_top/m_rx_data
add wave -noupdate -radix hexadecimal /tb_spi_top/dut/u_master/shifter
add wave -noupdate -radix hexadecimal /tb_spi_top/dut/u_master/rx_sh
add wave -noupdate -radix unsigned /tb_spi_top/dut/u_master/bit_cnt

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

configure wave -signalnamewidth 1
configure wave -timelineunits us
update
