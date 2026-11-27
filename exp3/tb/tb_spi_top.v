`timescale 1ns / 1ps
//=============================================================================
// tb_spi_top.v —— testbench：给时钟，跑 12 帧，把每帧的命令和响应打印出来
//
//   主机每帧自加 1：0x0000、0x0001 …… 0x000B
//   从机在收到 0x0000 / 0x0004 / 0x0008 / 0x000A 时分别回
//   0x0123 / 0x1234 / 0x2345 / 0x3456，其它回 0xABAB，且固定晚一帧。
//
//   注意：$display 的内容一律用英文。ModelSim 的控制台按本地代码页解码，
//   源文件里的中文注释没问题，但中文打印出来会是乱码。
//=============================================================================
module tb_spi_top;

    // 50 MHz 时钟，周期 20 ns
    reg clk = 1'b0;
    always #10 clk = ~clk;

    wire cs, sck, mosi, miso;

    spi_top dut (
        .clk  (clk),
        .cs   (cs),
        .sck  (sck),
        .mosi (mosi),
        .miso (miso)
    );

    //------------------------------------------------------------------
    // 每帧结束（CS 上升沿）打印一次。
    //   started 用来跳过 0 时刻 cs 由 x 变 1 的那次“假上升沿”；
    //   #100 是等从机把 rx_dat / tx_dat 更新完再打印。
    //------------------------------------------------------------------
    integer frame   = 0;
    reg     started = 1'b0;

    always @(negedge cs)
        started <= 1'b1;

    always @(posedge cs) begin
        if (started) begin
            #100;
            $display("frame %2d : cmd=%04h   slave_rx=%04h   master_rx=%04h",
                     frame, dut.u_master.cmd_now, dut.u_slave.rx_dat, dut.u_master.rx_dat);
            frame = frame + 1;
        end
    end

    initial begin
        $display("--------------------------------------------------------------");
        $display(" SPI loop-back: 16 bit, MSB first, SCK idle high, ~200 kHz");
        $display("--------------------------------------------------------------");
        #1_200_000;             // 12 帧约 1056 us，多留一点余量
        $display("--------------------------------------------------------------");
        $display(" %0d frames done", frame);
        $display("--------------------------------------------------------------");
        $finish;
    end

endmodule
