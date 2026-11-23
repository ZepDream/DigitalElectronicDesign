`timescale 1ns / 1ps
//=============================================================================
// spi_slave.v : 16-bit SPI slave with 50 MHz edge detection
//
//   SCK and CS are asynchronous to clk, so they are synchronized by two
//   flip-flops.  A rising/falling edge is turned into a one-cycle pulse by
//   comparing the two synchronized versions.
//
//   - CS falling : clear input shifter, load output shifter with tx_data
//   - SCK falling: sample MOSI
//   - SCK rising : shift MISO out (MSB first)
//   - CS rising  : latch the received command, then prepare the response
//                  that will be returned in the NEXT frame
//
//   Response table (command -> response):
//       0x0000 -> 0x1111
//       0x0004 -> 0x2222
//       0x0008 -> 0x3333
//       0x000A -> 0x4444
//       others -> 0xA5A5
//=============================================================================
module spi_slave (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        sck,
    input  wire        cs,
    input  wire        mosi,
    output wire        miso,

    output reg  [15:0] rx_data,      // last command received from the master
    output reg  [15:0] tx_data       // response that will be sent next frame
);

    //------------------------------------------------------------------
    // Two-stage synchronizers and edge pulses
    //------------------------------------------------------------------
    reg [1:0] cs_sync;
    reg [1:0] sck_sync;

    wire cs_fall  =  cs_sync[1] & ~cs_sync[0];
    wire cs_rise  = ~cs_sync[1] &  cs_sync[0];
    wire sck_fall =  sck_sync[1] & ~sck_sync[0];
    wire sck_rise = ~sck_sync[1] &  sck_sync[0];

    reg [15:0] shifter_in;
    reg [15:0] shifter_out;
    reg [4:0]  bit_cnt;

    assign miso = shifter_out[15];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cs_sync    <= 2'b11;
            sck_sync   <= 2'b11;
            shifter_in <= 16'h0000;
            shifter_out<= 16'hF00F;
            rx_data    <= 16'h0000;
            tx_data    <= 16'hF00F;   // idle pattern returned in frame 0
            bit_cnt    <= 5'd0;
        end else begin
            cs_sync  <= {cs_sync[0],  cs};
            sck_sync <= {sck_sync[0], sck};

            //--------------------------------------------------------------
            // Frame start: clear the input shifter and load the response
            // that was prepared at the end of the previous frame.
            //--------------------------------------------------------------
            if (cs_fall) begin
                shifter_in  <= 16'h0000;
                shifter_out <= tx_data;
                bit_cnt     <= 5'd0;
            end

            //--------------------------------------------------------------
            // Sample MOSI on the falling edge of SCK (16 bits, MSB first)
            //--------------------------------------------------------------
            if (sck_fall && !cs_sync[1] && (bit_cnt < 5'd16)) begin
                shifter_in <= {shifter_in[14:0], mosi};
                bit_cnt    <= bit_cnt + 5'd1;
            end

            //--------------------------------------------------------------
            // Shift MISO out on the rising edge of SCK
            //--------------------------------------------------------------
            if (sck_rise && !cs_sync[1] && (bit_cnt < 5'd16)) begin
                shifter_out <= {shifter_out[14:0], 1'b0};
            end

            //--------------------------------------------------------------
            // End of frame: latch the command and prepare the next response
            //--------------------------------------------------------------
            if (cs_rise) begin
                rx_data <= shifter_in;
                case (shifter_in)
                    16'h0000: tx_data <= 16'h1111;
                    16'h0004: tx_data <= 16'h2222;
                    16'h0008: tx_data <= 16'h3333;
                    16'h000A: tx_data <= 16'h4444;
                    default : tx_data <= 16'hA5A5;
                endcase
            end
        end
    end

endmodule
