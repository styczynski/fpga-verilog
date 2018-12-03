`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_SEGMENT_LED_HEX_DECODER_V
`define LIB_STYCZYNSKI_SEGMENT_LED_HEX_DECODER_V


/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * 8-segment led hex decoder
 * 
 *
 * MIT License
 */
module SegmentLedHexDecoder
(
    input [3:0] HexDigit,
    output reg [6:0] Segments
);

    always @(*)
    case (HexDigit)
        4'h0: Segments = 7'b100_0000;
        4'h1: Segments = 7'b111_1001;
        4'h2: Segments = 7'b010_0100;
        4'h3: Segments = 7'b011_0000;
        4'h4: Segments = 7'b001_1001;
        4'h5: Segments = 7'b001_0010;
        4'h6: Segments = 7'b000_0010;
        4'h7: Segments = 7'b111_1000;
        4'h8: Segments = 7'b000_0000;
        4'h9: Segments = 7'b001_0000;
        4'hA: Segments = 7'b000_1000;
        4'hB: Segments = 7'b000_0011;
        4'hC: Segments = 7'b100_0110;
        4'hD: Segments = 7'b010_0001;
        4'hE: Segments = 7'b000_0110;
        4'hF: Segments = 7'b000_1110;   
        default: Segments = 7'h7f;
    endcase
endmodule

`endif