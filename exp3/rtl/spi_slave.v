`timescale 1ns / 1ps
//=============================================================================
// spi_slave.v —— SPI 从机（EPM240T100C5，50 MHz 时钟，课件写法）
//
// 【思路，和课件一致】
//   1. 边沿检测：把 cs、sck 各用寄存器打一拍，再和原信号做位运算，
//      就得到 1 个时钟宽的边沿脉冲（“<=”赋值下一拍才生效，所以 cs_tmp
//      里存的就是上一拍的 cs）。
//   2. 每个 SCK 边沿，输入、输出移位寄存器同时工作：
//        下降沿：shifter_in  左移，把 MOSI 收到最低位
//        上升沿：shifter_out 左移，MISO 自动换到下一位
//   3. CS 上升沿：锁存收到的命令 rx_dat，用 case 判断该回什么，填 tx_dat
//      给下一帧用。
//
// 【响应表】收到什么 → 下一帧回什么
//   16'h0000 → 16'h0123      16'h0004 → 16'h1234
//   16'h0008 → 16'h2345      16'h000A → 16'h3456
//   其它      → 16'hABAB
//
// 【为什么响应晚一帧】
//   MISO 在 CS 拉低时就得装好，那一刻 16 位命令还没收完，所以只能回上一帧
//   的答案。这是固定的“一帧延迟”，不是错误。
//
// 【为什么不用复位】
//   MAX II 的寄存器上电为 0；这里给寄存器写了初值，ModelSim 也从 0 开始，
//   上电即可工作，省掉一个复位引脚。
//=============================================================================
module spi_slave (
    input  wire clk,        // 50 MHz 系统时钟
    input  wire cs,         // 片选，低有效
    input  wire sck,        // SPI 时钟，空闲为高
    input  wire mosi,       // 主机输出
    output wire miso        // 从机输出
);

    //------------------------------------------------------------------
    // 打一拍 + 边沿检测
    //------------------------------------------------------------------
    reg cs_tmp  = 1'b1;
    reg sck_tmp = 1'b1;

    wire cs_fall  =  cs_tmp & ~cs;      // 上一拍 1、这一拍 0：CS  下降沿
    wire cs_rise  = ~cs_tmp &  cs;      // 上一拍 0、这一拍 1：CS  上升沿
    wire sck_fall =  sck_tmp & ~sck;    // SCK 下降沿
    wire sck_rise = ~sck_tmp &  sck;    // SCK 上升沿

    //------------------------------------------------------------------
    // 移位寄存器与收发数据
    //------------------------------------------------------------------
    reg [15:0] shifter_in  = 16'h0000;  // 收 MOSI
    reg [15:0] shifter_out = 16'h0000;  // 发 MISO
    reg [4:0]  bit_cnt     = 5'd0;      // 已收位数

    reg [15:0] rx_dat = 16'h0000;       // 最近一帧收到的命令
    reg [15:0] tx_dat = 16'h0000;       // 下一帧要回的响应

    assign miso = shifter_out[15];

    always @(posedge clk) begin
        cs_tmp  <= cs;
        sck_tmp <= sck;

        // ---------------- 帧首：CS 下降 ----------------
        if (cs_fall) begin
            shifter_in  <= 16'h0000;
            shifter_out <= tx_dat;      // 把上一帧算好的响应装进来
            bit_cnt     <= 5'd0;
        end
        else begin
            // ---------------- SCK 下降沿：收一位 ----------------
            if (sck_fall && bit_cnt < 5'd16) begin
                shifter_in <= {shifter_in[14:0], mosi};
                bit_cnt    <= bit_cnt + 5'd1;
            end
            // ---------------- SCK 上升沿：发下一位 ----------------
            if (sck_rise && bit_cnt < 5'd16) begin
                shifter_out <= {shifter_out[14:0], 1'b0};
            end
        end

        // ---------------- 帧尾：CS 上升 ----------------
        if (cs_rise) begin
            rx_dat <= shifter_in;
            case (shifter_in)
                16'h0000: tx_dat <= 16'h0123;
                16'h0004: tx_dat <= 16'h1234;
                16'h0008: tx_dat <= 16'h2345;
                16'h000A: tx_dat <= 16'h3456;
                default : tx_dat <= 16'hABAB;
            endcase
        end
    end

endmodule
