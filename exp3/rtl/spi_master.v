`timescale 1ns / 1ps
//=============================================================================
// spi_master.v : 16-bit SPI master, SPI mode 1-like timing (CPOL=1, CPHA=0)
//
//   SCK idle high.  For every bit:
//     - master drives MOSI at the rising edge of SCK
//     - master samples MISO at the falling edge of SCK
//     - 16 bits, MSB first, 1 MHz SCK (50 MHz system clock / 25 half period)
//
//   The master keeps its own data generator (dat_gen): every finished frame
//   increments tx_data by one, so the bus carries 0x0000, 0x0001, 0x0002 ...
//=============================================================================
module spi_master #(
    parameter HALF_CLK = 25          // system clocks in half an SCK period
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,        // one-cycle pulse, ignored while busy
    input  wire        miso,

    output reg         sck,
    output reg         cs,
    output reg         mosi,

    output reg  [15:0] tx_data,      // dat_gen: command of the current/next frame
    output reg  [15:0] rx_data,      // response captured from the slave
    output reg         busy,
    output reg         frame_done    // one-cycle pulse after rx_data is valid
);

    localparam S_IDLE = 3'd0;
    localparam S_FALL = 3'd1;        // drive SCK low  -> sample MISO
    localparam S_RISE = 3'd2;        // drive SCK high -> advance MOSI
    localparam S_END  = 3'd3;        // release CS

    reg [2:0]  state;
    reg [15:0] shifter;              // output shift register
    reg [15:0] rx_sh;                // input shift register
    reg [4:0]  bit_cnt;              // 0 .. 15
    reg [7:0]  half_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            cs         <= 1'b1;
            sck        <= 1'b1;
            mosi       <= 1'b0;
            tx_data    <= 16'h0000;
            rx_data    <= 16'h0000;
            busy       <= 1'b0;
            frame_done <= 1'b0;
            shifter    <= 16'h0000;
            rx_sh      <= 16'h0000;
            bit_cnt    <= 5'd0;
            half_cnt   <= 8'd0;
        end else begin
            frame_done <= 1'b0;

            case (state)
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
                // Wait half a period with CS low (CS/MOSI setup), then create
                // the first falling edge and sample the first MISO bit.
                S_FALL: begin
                    if (half_cnt == HALF_CLK - 1) begin
                        half_cnt <= 8'd0;
                        sck      <= 1'b0;
                        rx_sh    <= {rx_sh[14:0], miso};
                        state    <= S_RISE;
                    end else begin
                        half_cnt <= half_cnt + 8'd1;
                    end
                end

                //-------------------------------------------------------------
                // After half a period low, raise SCK and advance MOSI to the
                // next bit.  The 16th falling edge has already sampled bit0.
                S_RISE: begin
                    if (half_cnt == HALF_CLK - 1) begin
                        half_cnt <= 8'd0;
                        sck      <= 1'b1;
                        mosi     <= shifter[14];
                        shifter  <= {shifter[14:0], 1'b0};
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
                // Finish the last bit period, release CS and publish the
                // received word.  tx_data is the next command (dat_gen + 1).
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

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
