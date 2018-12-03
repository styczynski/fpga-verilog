`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_POW_2_32_V
`define LIB_STYCZYNSKI_POW_2_32_V


/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Module for fast calculation of 2 ** Input for 32-bit output
 * 
 *
 * MIT License
 */
module Pow2_32
(
    input [4:0] Input,
    output reg [31:0] Output
);

    always @(*)
    case (Input)
        0:  Output = 32'b0000_0000_0000_0000_0000_0000_0000_0001;
        1:  Output = 32'b0000_0000_0000_0000_0000_0000_0000_0010;
        2:  Output = 32'b0000_0000_0000_0000_0000_0000_0000_0100;
        3:  Output = 32'b0000_0000_0000_0000_0000_0000_0000_1000;
        4:  Output = 32'b0000_0000_0000_0000_0000_0000_0001_0000;
        5:  Output = 32'b0000_0000_0000_0000_0000_0000_0010_0000;
        6:  Output = 32'b0000_0000_0000_0000_0000_0000_0100_0000;
        7:  Output = 32'b0000_0000_0000_0000_0000_0000_1000_0000;
        8:  Output = 32'b0000_0000_0000_0000_0000_0001_0000_0000;
        9:  Output = 32'b0000_0000_0000_0000_0000_0010_0000_0000;
        10: Output = 32'b0000_0000_0000_0000_0000_0100_0000_0000;
        11: Output = 32'b0000_0000_0000_0000_0000_1000_0000_0000;
        12: Output = 32'b0000_0000_0000_0000_0001_0000_0000_0000;
        13: Output = 32'b0000_0000_0000_0000_0010_0000_0000_0000;
        14: Output = 32'b0000_0000_0000_0000_0100_0000_0000_0000;
        15: Output = 32'b0000_0000_0000_0000_1000_0000_0000_0000;
        16: Output = 32'b0000_0000_0000_0001_0000_0000_0000_0000;
        17: Output = 32'b0000_0000_0000_0010_0000_0000_0000_0000;
        18: Output = 32'b0000_0000_0000_0100_0000_0000_0000_0000;
        19: Output = 32'b0000_0000_0000_1000_0000_0000_0000_0000;
        20: Output = 32'b0000_0000_0001_0000_0000_0000_0000_0000;
        21: Output = 32'b0000_0000_0010_0000_0000_0000_0000_0000;
        22: Output = 32'b0000_0000_0100_0000_0000_0000_0000_0000;
        23: Output = 32'b0000_0000_1000_0000_0000_0000_0000_0000;
        24: Output = 32'b0000_0001_0000_0000_0000_0000_0000_0000;
        25: Output = 32'b0000_0010_0000_0000_0000_0000_0000_0000;
        26: Output = 32'b0000_0100_0000_0000_0000_0000_0000_0000;
        27: Output = 32'b0000_1000_0000_0000_0000_0000_0000_0000;
        28: Output = 32'b0001_0000_0000_0000_0000_0000_0000_0000;
        29: Output = 32'b0010_0000_0000_0000_0000_0000_0000_0000;
        30: Output = 32'b0100_0000_0000_0000_0000_0000_0000_0000;
        31: Output = 32'b1000_0000_0000_0000_0000_0000_0000_0000;
        default: Output = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
    endcase
    
endmodule

`endif