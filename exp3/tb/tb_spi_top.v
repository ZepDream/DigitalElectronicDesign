`timescale 1ns / 1ps
//=============================================================================
// tb_spi_top.v —— 自检查 testbench（回环测试）
//
// 【检查什么】每帧 frame_done 到来时比对两件事：
//   1) 从机收到的值 s_rx_data 是否等于本帧主机发出的命令 cmd_now；
//   2) 主机收到的值 m_rx_data 是否等于「上一帧命令」对应的响应。
//      从机必须收完整条命令才知道该回答什么，所以响应晚一帧回来，
//      这是设计上固定的流水线延迟，不是错误。
//
// 【为什么期望值用变量保存】
//   期望值不能按“本帧命令”算，而要按“上一帧命令”算。所以每帧检查完，
//   才用本帧命令更新 expected，供下一帧使用；第 0 帧的期望值单独预置成
//   从机复位初值 0xF00F。
//
// 【输出】逐帧打印一行，20 帧全部通过时打印 RESULT: PASS，便于批处理抓取。
//=============================================================================
module tb_spi_top;

    reg         clk;                 // 50 MHz 系统时钟
    reg         rst_n;               // 复位，低有效
    reg         run;                 // 1：启动连续发帧

    wire        spi_cs;              // SPI 总线
    wire        spi_sck;
    wire        spi_mosi;
    wire        spi_miso;
    wire [15:0] m_tx_data;           // 主机发送的命令
    wire [15:0] m_rx_data;           // 主机收到的响应
    wire [15:0] s_tx_data;           // 从机下一帧要返回的响应
    wire [15:0] s_rx_data;           // 从机收到的命令
    wire        m_busy;              // 主机忙标志
    wire        frame_done;          // 帧结束脉冲

    //------------------------------------------------------------------
    // 被测设计（DUT）：顶层把主机和从机连成回环
    //------------------------------------------------------------------
    spi_top #(
        .HALF_CLK (25),              // 半周期 25 个时钟 -> SCK 1 MHz
        .GAP_CLK  (100)              // 帧间 100 个时钟 -> 2 us
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .run        (run),
        .spi_cs     (spi_cs),
        .spi_sck    (spi_sck),
        .spi_mosi   (spi_mosi),
        .spi_miso   (spi_miso),
        .m_tx_data  (m_tx_data),
        .m_rx_data  (m_rx_data),
        .s_tx_data  (s_tx_data),
        .s_rx_data  (s_rx_data),
        .m_busy     (m_busy),
        .frame_done (frame_done)
    );

    //------------------------------------------------------------------
    // 时钟：周期 20 ns，即 50 MHz
    //------------------------------------------------------------------
    initial clk = 1'b0;
    always #10 clk = ~clk;

    //------------------------------------------------------------------
    // 期望响应函数：和 spi_slave.v 里的响应表保持一致
    //   用函数而不是写死数组，是为了让“期望值”只有一处来源，
    //   以后改响应表时只需同步改这里和从机。
    //------------------------------------------------------------------
    function [15:0] resp;
        input [15:0] cmd;
        begin
            case (cmd)
                16'h0000: resp = 16'h1111;
                16'h0004: resp = 16'h2222;
                16'h0008: resp = 16'h3333;
                16'h000A: resp = 16'h4444;
                default : resp = 16'hA5A5;
            endcase
        end
    endfunction

    integer    frame;                // 已完成的帧号，从 0 开始
    integer    errors;               // 错误计数，最后据此给出 PASS / FAIL
    reg [15:0] cmd_now;              // 本帧主机发出的命令（帧首锁存）
    reg [15:0] expected;             // 本帧主机应收到的响应（上一帧命令的响应）

    // 在 CS 下降沿锁存本帧命令：
    // 此时主机刚把 tx_data 送上总线，testbench 记下来供帧尾比对使用。
    always @(negedge spi_cs) begin
        cmd_now = m_tx_data;
    end

    // 记分板：每帧结束检查一次
    always @(posedge frame_done) begin
        // 等 200 ns：从机检测 CS 上升沿要经过两级同步（约 40 ns），
        // 再锁存 rx_data，这里留足余量，避免比对到还没更新的值。
        #200;
        if (s_rx_data !== cmd_now) begin
            errors = errors + 1;
            $display("ERROR frame %0d: slave rx=0x%04h, command=0x%04h",
                     frame, s_rx_data, cmd_now);
        end
        if (m_rx_data !== expected) begin
            errors = errors + 1;
            $display("ERROR frame %0d: master rx=0x%04h, expected=0x%04h",
                     frame, m_rx_data, expected);
        end
        // 逐帧打印一行，方便在 Transcript 里直接看结论
        $display("frame %2d | cmd=0x%04h | slave_rx=0x%04h | master_rx=0x%04h | expected=0x%04h | %s",
                 frame, cmd_now, s_rx_data, m_rx_data, expected,
                 (s_rx_data === cmd_now && m_rx_data === expected) ? "OK" : "FAIL");

        // 本帧命令的响应会在下一帧回来，所以期望值在这里才更新
        expected = resp(cmd_now);
        frame    = frame + 1;
    end

    //------------------------------------------------------------------
    // 激励：复位 -> 使能 run -> 等 20 帧 -> 输出结论
    //   主机自带数据发生器，命令从 0x0000 每帧加 1，
    //   20 帧会经过 0x0000/0x0004/0x0008/0x000A，四种特殊响应都能覆盖到。
    //------------------------------------------------------------------
    initial begin
        rst_n    = 1'b0;
        run      = 1'b0;
        frame    = 0;
        errors   = 0;
        cmd_now  = 16'h0000;
        expected = 16'hF00F;   // 第 0 帧：从机复位初值，此时还没有任何命令响应

        #100;                  // 复位保持一段时间
        @(negedge clk);        // 对齐到时钟下降沿再释放复位，避免竞争
        rst_n = 1'b1;
        #100;
        run = 1'b1;            // 启动：调度器开始自动发帧

        wait (frame == 20);    // 跑满 20 帧
        #2000;                 // 留点时间让最后一帧的打印输出完

        $display("--------------------------------------------------");
        if (errors == 0)
            $display("RESULT: PASS - %0d frames checked, 0 errors", frame);
        else
            $display("RESULT: FAIL - %0d frames checked, %0d errors", frame, errors);
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
