`timescale 1ns / 1ps
//=============================================================================
// spi_master.v —— 16 位 SPI 主机（Mode 2：CPOL = 1，CPHA = 0）
//
// 【时序约定】与 spi_slave.v 严格配合，双方都不在同一个沿上既改又采：
//   - SCK 空闲电平为高（CPOL = 1），CS 空闲为高
//   - 主机在 SCK 上升沿更新 MOSI，在 SCK 下降沿采样 MISO
//   - 16 位一帧，MSB first（先发 bit15，最后发 bit0）
//   - SCK = 1 MHz：50 MHz 系统时钟下，半个 SCK 周期 = 25 个时钟（HALF_CLK）
//
// 【内置数据发生器 dat_gen】
//   每完成一帧，tx_data 自加 1，于是总线上依次出现 0x0000、0x0001、0x0002 …
//   这样 testbench 只负责复位和使能，激励由主机自己产生，便于长时间连续跑帧。
//
// 【状态机】
//   S_IDLE：CS=1、SCK=1；收到 start 后拉低 CS，把 tx_data 的最高位送上 MOSI
//   S_FALL：等半个周期，拉低 SCK（产生下降沿），同一时刻采样 MISO
//   S_RISE：等半个周期，拉高 SCK（产生上升沿），MOSI 更新为下一位
//   S_END ：等半个周期，拉高 CS，锁存 rx_data、tx_data 自加 1、产生 frame_done
//
// 【为什么每个状态里都有一句 half_cnt == HALF_CLK - 1】
//   half_cnt 是半周期计数器，从 0 数到 HALF_CLK-1 共 HALF_CLK 个时钟，
//   正好等于半个 SCK 周期（25 × 20 ns = 500 ns），SCK 于是得到 1 MHz。
//   计数到顶时执行动作并清零，所以 SCK 每个沿之间恒为 500 ns，占空比 50%。
//=============================================================================
module spi_master #(
    parameter HALF_CLK = 25          // 半个 SCK 周期包含的系统时钟个数（50 MHz -> 1 MHz）
)(
    input  wire        clk,          // 系统时钟 50 MHz
    input  wire        rst_n,        // 异步复位，低有效
    input  wire        start,        // 启动一帧的脉冲（单周期），busy 期间被忽略
    input  wire        miso,         // 从机返回的数据（主机在 SCK 下降沿采样）

    output reg         sck,          // SPI 时钟，空闲为高
    output reg         cs,           // 片选，低有效（低电平期间完成 16 位传输）
    output reg         mosi,         // 主机输出数据，MSB first

    output reg  [15:0] tx_data,      // dat_gen：本帧（下一帧）要发送的命令
    output reg  [15:0] rx_data,      // 从从机收到的响应，frame_done 时有效
    output reg         busy,         // 一帧传输期间为高，帧间为低
    output reg         frame_done    // 一帧结束的单周期脉冲，供 testbench 逐帧检查
);

    // 状态机编码：位宽 3 位，够放下 4 个状态且留有余量
    localparam S_IDLE = 3'd0;
    localparam S_FALL = 3'd1;        // 拉低 SCK -> 产生下降沿，同时采样 MISO
    localparam S_RISE = 3'd2;        // 拉高 SCK -> 产生上升沿，MOSI 前进一位
    localparam S_END  = 3'd3;        // 收尾：释放 CS、发布接收结果

    reg [2:0]  state;                // 当前状态
    reg [15:0] shifter;              // 发送移位寄存器，每来一个上升沿左移一位
    reg [15:0] rx_sh;                // 接收移位寄存器，每个下降沿把 MISO 移入最低位
    reg [4:0]  bit_cnt;              // 已处理的位数，0 ~ 15
    reg [7:0]  half_cnt;             // 半周期计数器，0 ~ HALF_CLK-1

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位：总线回到空闲态（CS=1、SCK=1），所有计数器清零
            state      <= S_IDLE;
            cs         <= 1'b1;
            sck        <= 1'b1;
            mosi       <= 1'b0;
            tx_data    <= 16'h0000;  // 第一帧从 0x0000 开始发
            rx_data    <= 16'h0000;
            busy       <= 1'b0;
            frame_done <= 1'b0;
            shifter    <= 16'h0000;
            rx_sh      <= 16'h0000;
            bit_cnt    <= 5'd0;
            half_cnt   <= 8'd0;
        end else begin
            // frame_done 默认拉低，只在 S_END 里置高一拍，保证是单周期脉冲
            frame_done <= 1'b0;

            case (state)
                //-------------------------------------------------------------
                // 空闲：维持 CS=1、SCK=1。收到 start 后进入帧首准备：
                //   1) 拉低 CS，选中从机
                //   2) 把 tx_data 的第 15 位（最高位）直接送到 MOSI
                //   3) 把 tx_data 装入移位寄存器，之后靠左移逐位输出
                // 此时 SCK 仍为高，第一个下降沿要等 500 ns 才出现，
                // 因此第一位数据有充足的建立时间给从机采样。
                //-------------------------------------------------------------
                S_IDLE: begin
                    cs   <= 1'b1;
                    sck  <= 1'b1;
                    busy <= 1'b0;
                    if (start) begin
                        cs       <= 1'b0;
                        sck      <= 1'b1;
                        mosi     <= tx_data[15];
                        shifter  <= tx_data;
                        bit_cnt  <= 5'd0;
                        rx_sh    <= 16'h0000;
                        half_cnt <= 8'd0;
                        busy     <= 1'b1;
                        state    <= S_FALL;
                    end
                end

                //-------------------------------------------------------------
                // 等待半周期（CS 已低、MOSI 已稳定），然后拉低 SCK：
                //   下降沿到来时把 MISO 移入 rx_sh 的最低位，完成本位的采样。
                // 注意：这里用非阻塞赋值更新 rx_sh，实际写进寄存器是在本拍末尾，
                // 而 MISO 由从机在 SCK 上升沿就已经更新过，已稳定半个周期，
                // 所以不存在“采到新位还是旧位”的竞争。
                //-------------------------------------------------------------
                S_FALL: begin
                    if (half_cnt == HALF_CLK - 1) begin
                        half_cnt <= 8'd0;
                        sck      <= 1'b0;                          // 产生下降沿
                        rx_sh    <= {rx_sh[14:0], miso};            // 采样并左移
                        state    <= S_RISE;
                    end else begin
                        half_cnt <= half_cnt + 8'd1;
                    end
                end

                //-------------------------------------------------------------
                // 再等半周期，拉高 SCK 产生上升沿，同时把 MOSI 换成下一位：
                //   shifter 左移一位并把 0 补到最低位，
                //   下一拍 shifter[14] 就是新的下一位数据。
                // 第 16 个下降沿已经把 bit0 采进来了，所以这里判断
                // bit_cnt == 15 时直接进 S_END，不会再产生第 17 个下降沿。
                //-------------------------------------------------------------
                S_RISE: begin
                    if (half_cnt == HALF_CLK - 1) begin
                        half_cnt <= 8'd0;
                        sck      <= 1'b1;                          // 产生上升沿
                        mosi     <= shifter[14];                    // 送出下一位
                        shifter  <= {shifter[14:0], 1'b0};          // 左移，末尾补 0
                        if (bit_cnt == 5'd15) begin
                            state <= S_END;
                        end else begin
                            bit_cnt <= bit_cnt + 5'd1;
                            state   <= S_FALL;
                        end
                    end else begin
                        half_cnt <= half_cnt + 8'd1;
                    end
                end

                //-------------------------------------------------------------
                // 收尾：最后补满半个周期（保证最后一位的保持时间），然后
                //   1) 拉高 CS 结束本帧
                //   2) 把 rx_sh 锁存到 rx_data，作为本帧收到的响应
                //   3) tx_data 自加 1，作为下一帧要发的命令（dat_gen）
                //   4) 产生 frame_done 单周期脉冲，通知 testbench 本帧已结束
                //-------------------------------------------------------------
                S_END: begin
                    if (half_cnt == HALF_CLK - 1) begin
                        half_cnt   <= 8'd0;
                        sck        <= 1'b1;
                        cs         <= 1'b1;
                        rx_data    <= rx_sh;
                        tx_data    <= tx_data + 16'd1;
                        busy       <= 1'b0;
                        frame_done <= 1'b1;
                        state      <= S_IDLE;
                    end else begin
                        half_cnt <= half_cnt + 8'd1;
                    end
                end

                // 状态机跑飞时回到空闲，保证 CS 能释放、不会卡死总线
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
