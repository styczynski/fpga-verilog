`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_MULTIPLIER_V
`define LIB_STYCZYNSKI_MULTIPLIER_V

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Divider for integer division.
 * Integers are INPUT_BIT_WIDTH bits width.
 * The divider supports signed and unsigned inputs.
 *
 * If you want to use only unisgned mode please set input Sign to 0.
 * If you want to use signed mode please set input Sign to 1.
 * 
 *
 * MIT License
 */
module Multiplier
#(
    parameter DATA_WIDTH = 16
)
(
   input wire [DATA_WIDTH-1:0] InputA,
   input wire [DATA_WIDTH-1:0] InputB,
   input wire Start,
   input wire Clk,
   output reg [(2*DATA_WIDTH)-1:0] Product,
   output wire Ready
);

   reg [DATA_WIDTH:0] InputACopy;
   reg [(2*DATA_WIDTH)-1:0] InputBCopy;
   
   reg [$clog2(DATA_WIDTH):0] Bit; 
   assign Ready = (Bit == 0);
   
   initial Bit = 0;

   always @(posedge Clk)
   begin
        if(Ready && Start)
        begin
                Bit <= DATA_WIDTH;
                Product <= 0;
                InputBCopy <= { {DATA_WIDTH{1'd0}}, InputB };
                InputACopy <= InputA;
            end
        else if(Bit)
            begin
                if(InputACopy[0] == 1'b1)
                begin
                    Product <= Product + InputBCopy;
                end
                InputACopy <= InputACopy >> 1;
                InputBCopy <= InputBCopy << 1;
                Bit <= Bit - 1;
            end
   end
     
endmodule

`endif