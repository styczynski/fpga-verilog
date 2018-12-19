`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_ADJ_CLOCK_DIVIDER_STATIC_V
`define LIB_STYCZYNSKI_ADJ_CLOCK_DIVIDER_STATIC_V


/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Adjustable clock frequency divider with fixed factor
 * 
 *
 * MIT License
 */
module AdjClockDividerStatic
#(
	parameter INPUT_BIT_WIDTH = 8,
        parameter CLK_DIV_FACTOR = 1024
)
(
    input ClkInput,
    output reg ClkOutput
);

    reg [(INPUT_BIT_WIDTH-1):0] InternalCounter;

    initial InternalCounter = 0;

    always @(posedge ClkInput)
    begin
    
       InternalCounter <= InternalCounter + 1;
       if(InternalCounter >= CLK_DIV_FACTOR)
       begin
          InternalCounter <= 0;
          ClkOutput <= !ClkOutput;
       end
    
    end
    
endmodule

`endif