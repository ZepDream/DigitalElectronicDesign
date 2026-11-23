`timescale 1ns / 1ps
//=============================================================================
// tb_spi_top.v : self-checking loop-back testbench
//
//   Checks, for every frame:
//     1) slave.rx_data == command sent by the master in the same frame
//     2) master.rx_data == response prepared from the PREVIOUS command
//        (the slave can only answer after it has seen the whole command,
//         so the response is returned one frame later)
//=============================================================================
module tb_spi_top;

    reg         clk;
    reg         rst_n;
    reg         run;

    wire        spi_cs;
    wire        spi_sck;
    wire        spi_mosi;
    wire        spi_miso;
    wire [15:0] m_tx_data;
    wire [15:0] m_rx_data;
    wire [15:0] s_tx_data;
    wire [15:0] s_rx_data;
    wire        m_busy;
    wire        frame_done;

    //------------------------------------------------------------------
    // DUT
    //------------------------------------------------------------------
    spi_top #(
        .HALF_CLK (25),
        .GAP_CLK  (100)
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
    // 50 MHz clock
    //------------------------------------------------------------------
    initial clk = 1'b0;
    always #10 clk = ~clk;

    //------------------------------------------------------------------
    // Expected response for a command
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

    integer    frame;
    integer    errors;
    reg [15:0] cmd_now;
    reg [15:0] expected;

    // Capture the command at the start of each frame
    always @(negedge spi_cs) begin
        cmd_now = m_tx_data;
    end

    // Scoreboard at the end of each frame
    always @(posedge frame_done) begin
        #200;   // let the slave synchronize the CS rising edge and latch rx_data
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
        $display("frame %2d | cmd=0x%04h | slave_rx=0x%04h | master_rx=0x%04h | expected=0x%04h | %s",
                 frame, cmd_now, s_rx_data, m_rx_data, expected,
                 (s_rx_data === cmd_now && m_rx_data === expected) ? "OK" : "FAIL");

        expected = resp(cmd_now);
        frame    = frame + 1;
    end

    //------------------------------------------------------------------
    // Stimulus
    //------------------------------------------------------------------
    initial begin
        rst_n    = 1'b0;
        run      = 1'b0;
        frame    = 0;
        errors   = 0;
        cmd_now  = 16'h0000;
        expected = 16'hF00F;   // slave idle pattern returned in frame 0

        #100;
        @(negedge clk);
        rst_n = 1'b1;
        #100;
        run = 1'b1;

        // 20 frames: commands 0x0000 .. 0x0013, covers 0/4/8/A and defaults
        wait (frame == 20);
        #2000;

        $display("--------------------------------------------------");
        if (errors == 0)
            $display("RESULT: PASS - %0d frames checked, 0 errors", frame);
        else
            $display("RESULT: FAIL - %0d frames checked, %0d errors", frame, errors);
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
