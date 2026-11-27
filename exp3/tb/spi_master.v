`timescale 1ns / 1ps
//=============================================================================
// spi_master.v —— 仿真用的 SPI 主机模型（真机的主机是 STM32，不用综合这个）
//
//   课件第 9 页：仿真时让主机“传输的内容自加 1”，这样一帧接一帧跑，能看到
//   从机在收到 0x0000、0x0004、0x0008、0x000A 时分别回 0x0123、0x1234、
//   0x2345、0x3456。
//
//   时序与 Keil 工程里的 SPI.c 一致（16 位、MSB first、SCK 空闲高）：
//       CS 拉低 → 等半个周期（让从机装载输出移位寄存器）
//       每一位：把这一位摆到 MOSI → 等半周期 → SCK 拉低（从机采样、主机采样）
//               → 等半周期 → SCK 拉高（从机移位）
//       补半周期 → CS 拉高 → 帧间空隙 → 数据自加 1
//=============================================================================
module spi_master #(
    parameter HALF_NS = 2000,       // 半个 SCK 周期 = 2 us，SCK 约 200 kHz
    parameter GAP_NS  = 20000,      // 帧间 CS 高电平 20 us
    parameter FRAMES  = 12          // 一共发多少帧
)(
    input  wire       miso,
    output reg        cs,
    output reg        sck,
    output reg        mosi,
    output reg [15:0] tx_dat,       // 本帧要发的内容（每帧自加 1）
    output reg [15:0] rx_dat        // 本帧收回来的数据
);

    reg [15:0] cmd_now;             // 本帧正在发的内容（看波形用）
    reg [15:0] rx_sh;               // 接收移位寄存器
    integer    i;
    integer    n;

    initial begin
        cs     = 1'b1;              // 空闲：CS = 1、SCK = 1
        sck    = 1'b1;
        mosi   = 1'b0;
        tx_dat = 16'h0000;
        rx_dat = 16'h0000;
        rx_sh  = 16'h0000;

        #100;
        for (n = 0; n < FRAMES; n = n + 1) begin
            cmd_now = tx_dat;       // 本帧内容
            cs      = 1'b0;
            #(HALF_NS);

            rx_sh = 16'h0000;
            for (i = 0; i < 16; i = i + 1) begin
                mosi = cmd_now[15 - i];     // SCK 为高时摆好这一位
                #(HALF_NS);
                sck = 1'b0;                 // 下降沿
                rx_sh = {rx_sh[14:0], miso};
                #(HALF_NS);
                sck = 1'b1;                 // 上升沿
            end

            #(HALF_NS);
            rx_dat = rx_sh;                 // 一帧收完，锁存
            cs     = 1'b1;
            if (n < FRAMES - 1)
                tx_dat = tx_dat + 16'd1;    // 内容自加 1（最后一帧不再加）
            #(GAP_NS);
        end
        // 发完 FRAMES 帧后保持空闲
    end

endmodule
