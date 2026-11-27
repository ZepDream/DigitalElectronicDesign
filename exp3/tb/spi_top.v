`timescale 1ns / 1ps
//=============================================================================
// spi_top.v —— 仿真顶层：把主机模型和从机连起来（课件第 11 页“建立顶层模块”）
//
//   cs / sck / mosi 三根线由主机驱动、从机接收；miso 由从机驱动、主机接收。
//   真机上这三根线是 STM32 的 GPIO，仿真里换成 spi_master 模型。
//=============================================================================
module spi_top (
    input  wire clk,        // 50 MHz，从机的工作时钟
    output wire cs,         // 以下四根就是 SPI 总线
    output wire sck,
    output wire mosi,
    input  wire miso
);

    wire miso_w;

    spi_master u_master (
        .miso   (miso_w),
        .cs     (cs),
        .sck    (sck),
        .mosi   (mosi),
        .tx_dat (),
        .rx_dat ()
    );

    spi_slave u_slave (
        .clk  (clk),
        .cs   (cs),
        .sck  (sck),
        .mosi (mosi),
        .miso (miso_w)
    );

    assign miso = miso_w;

endmodule
