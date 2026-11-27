`timescale 1ns / 1ps
//=============================================================================
// spi_top.v —— SPI 主机 + 从机回环的顶层
//
// 【顶层做三件事】
//   1. 把主机的 spi_cs / spi_sck / spi_mosi 直接连到从机的 cs / sck / mosi，
//      把从机的 miso 接回主机，构成“回环”测试结构；
//   2. 内置一个帧调度器：run=1 时，只要主机空闲且距上一帧已过 GAP_CLK 个时钟，
//      就产生一个 start 脉冲；
//   3. 把内部状态引到端口上（m_tx_data 等），方便波形窗口直接观察。
//
// 【为什么需要调度器】
//   仿真开始后如果没人给 start，主机就一直空闲，波形上什么都没有。加了这个
//   调度器，testbench 只需要复位 + 拉高 run，系统就会自己连续发帧，
//   20 帧自检也就能自动跑完。
//
// 【本文件在综合时的用途】
//   如果要做实物（EPM240 + STM32），只需把 spi_cs / spi_sck / spi_mosi /
//   spi_miso 接到顶层引脚，从机部分去掉，改由 STM32 充当对端即可。
//=============================================================================
module spi_top #(
    parameter HALF_CLK = 25,          // 半个 SCK 周期的时钟数：50 MHz -> 1 MHz
    parameter GAP_CLK  = 100          // 帧间 CS 高电平时间（100 × 20 ns = 2 us）
)(
    input  wire        clk,           // 系统时钟 50 MHz
    input  wire        rst_n,         // 异步复位，低有效
    input  wire        run,           // 1：自由连续发帧；0：停发

    output wire        spi_cs,        // SPI 片选（主机输出）
    output wire        spi_sck,       // SPI 时钟（主机输出）
    output wire        spi_mosi,      // 主机 -> 从机数据
    output wire        spi_miso,      // 从机 -> 主机数据

    output wire [15:0] m_tx_data,     // 主机本帧发送的命令（自加 1）
    output wire [15:0] m_rx_data,     // 主机本帧收到的响应
    output wire [15:0] s_tx_data,     // 从机下一帧要返回的响应
    output wire [15:0] s_rx_data,     // 从机本帧收到的命令
    output wire        m_busy,        // 主机忙标志（一帧期间为高）
    output wire        frame_done     // 帧结束单周期脉冲（由主机产生）
);

    //------------------------------------------------------------------
    // 帧调度器：产生 start 脉冲
    //   主机忙（m_busy=1）时计数器不动，等这一帧结束；
    //   主机空闲时开始数间隔，数满 GAP_CLK 就发一个 start，同时清零重数。
    //   run=0 时计数器保持清零，保证重新使能后第一帧的间隔也是完整的 2 us。
    //------------------------------------------------------------------
    reg [15:0] gap_cnt;               // 帧间间隔计数器
    reg        start;                 // 送给主机的启动脉冲（单周期）

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gap_cnt <= 16'd0;
            start   <= 1'b0;
        end else begin
            // start 默认拉低，只在数满间隔时置高一拍
            start <= 1'b0;
            if (!run) begin
                gap_cnt <= 16'd0;             // 停发：间隔计数复位
            end else if (!m_busy) begin
                if (gap_cnt >= GAP_CLK) begin  // 间隔够了，启动下一帧
                    gap_cnt <= 16'd0;
                    start   <= 1'b1;
                end else begin
                    gap_cnt <= gap_cnt + 16'd1;
                end
            end
            // m_busy=1（正在传一帧）时 gap_cnt 保持不变，帧结束立即开始重新计时
        end
    end

    //------------------------------------------------------------------
    // 主机实例
    //   miso 接从机的 spi_miso，sck/cs/mosi 同时输出到顶层端口（即总线）
    //------------------------------------------------------------------
    spi_master #(
        .HALF_CLK (HALF_CLK)
    ) u_master (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .miso       (spi_miso),
        .sck        (spi_sck),
        .cs         (spi_cs),
        .mosi       (spi_mosi),
        .tx_data    (m_tx_data),
        .rx_data    (m_rx_data),
        .busy       (m_busy),
        .frame_done (frame_done)
    );

    //------------------------------------------------------------------
    // 从机实例
    //   和主机挂在同一组总线上，相当于把 MOSI 与 MISO 首尾相连的回环测试
    //------------------------------------------------------------------
    spi_slave u_slave (
        .clk     (clk),
        .rst_n   (rst_n),
        .sck     (spi_sck),
        .cs      (spi_cs),
        .mosi    (spi_mosi),
        .miso    (spi_miso),
        .rx_data (s_rx_data),
        .tx_data (s_tx_data)
    );

endmodule
