`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_SEGMENT_LED_HEX_ENCODER_V
`define LIB_STYCZYNSKI_SEGMENT_LED_HEX_ENCODER_V


/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * 8-segment led hex encoder
 * 
 *
 * MIT License
 */
module SegmentLedHexEncoder
(
    input [6:0] Segments,
    output reg [3:0] HexDigit,
    output reg Undefined
);
    always @(*)
    begin
        case (Segments)
            7'b111_1110: { Undefined, HexDigit } = 5'b10000;
            7'b000_0001: { Undefined, HexDigit } = 0;
            7'b111_1001: { Undefined, HexDigit } = 1;
            7'b001_0010: { Undefined, HexDigit } = 2;
            7'b000_0110: { Undefined, HexDigit } = 3;
            7'b100_1100: { Undefined, HexDigit } = 4;
            7'b010_0100: { Undefined, HexDigit } = 5;
            7'b010_0000: { Undefined, HexDigit } = 6;
            7'b000_1111: { Undefined, HexDigit } = 7;
            7'b000_0000: { Undefined, HexDigit } = 8;
            7'b000_0100: { Undefined, HexDigit } = 9;
            default: { Undefined, HexDigit } = 5'b11111;
        endcase
    end
endmodule

`endif