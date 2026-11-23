`timescale 1ns / 1ps
//=============================================================================
// spi_top.v : SPI master + slave loop-back top level
//
//   The top level contains a small frame scheduler.  When run=1 it generates
//   a start pulse whenever the master is idle and the inter-frame gap has
//   elapsed, so the complete system runs from clk/rst_n alone.
//
//   Board-level pins: spi_cs, spi_sck, spi_mosi (master outputs) and
//   spi_miso (slave output).  In this simulation top they are connected
//   directly, which is the "SPI loop-back" test.
//=============================================================================
module spi_top #(
    parameter HALF_CLK = 25,          // 50 MHz -> 1 MHz SCK
    parameter GAP_CLK  = 100          // 2 us idle time between frames
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        run,           // 1: free-running frame scheduler

    output wire        spi_cs,
    output wire        spi_sck,
    output wire        spi_mosi,
    output wire        spi_miso,

    output wire [15:0] m_tx_data,
    output wire [15:0] m_rx_data,
    output wire [15:0] s_tx_data,
    output wire [15:0] s_rx_data,
    output wire        m_busy,
    output wire        frame_done
);

    //------------------------------------------------------------------
    // Frame scheduler
    //------------------------------------------------------------------
    reg [15:0] gap_cnt;
    reg        start;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gap_cnt <= 16'd0;
            start   <= 1'b0;
        end else begin
            start <= 1'b0;
            if (!run) begin
                gap_cnt <= 16'd0;
            end else if (!m_busy) begin
                if (gap_cnt >= GAP_CLK) begin
                    gap_cnt <= 16'd0;
                    start   <= 1'b1;
                end else begin
                    gap_cnt <= gap_cnt + 16'd1;
                end
            end
        end
    end

    //------------------------------------------------------------------
    // Master / slave connection
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
