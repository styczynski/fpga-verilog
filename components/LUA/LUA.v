`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_LUA_V
`define LIB_STYCZYNSKI_LUA_V


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
module LUA
#(
    parameter DATA_WIDTH = 16,
    parameter BLOCK_SIZE = 0
)
(
   input wire [DATA_WIDTH-1:0] InputX,
   input wire [DATA_WIDTH-1:0] InputY,
   input wire Start,
   input wire Clk,
   output reg [(2*DATA_WIDTH)-1:0] Address,
   output wire Ready
);

   reg [DATA_WIDTH:0] InputYCopy;
   reg [(2*DATA_WIDTH)+1:0] ShiftValue;
   
   reg [$clog2(DATA_WIDTH)+1:0] Bit; 
   assign Ready = (Bit == 0);
   
   initial Bit = 0;

   always @(posedge Clk)
   begin
        if(Ready && Start)
        begin
                Bit <= DATA_WIDTH+1;
                Address <= 0;
                ShiftValue <= { {DATA_WIDTH{1'd0}}, BLOCK_SIZE };
                InputYCopy <= InputY;
            end
        else if(Bit > 1)
            begin
                if(InputYCopy[0] == 1'b1)
                begin
                    Address <= Address + ShiftValue;
                end
                InputYCopy <= InputYCopy >> 1;
                ShiftValue <= ShiftValue << 1;
                Bit <= Bit - 1;
            end
        else if(Bit == 1)
            begin
                Address <= Address + InputX;
                Bit <= Bit - 1;
            end
   end
     
endmodule

`endif