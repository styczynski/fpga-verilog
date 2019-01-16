`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_ADJ_CLOCK_DIVIDER_V
`define LIB_STYCZYNSKI_ADJ_CLOCK_DIVIDER_V


/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Adjustable clock frequency divider
 * 
 *
 * MIT License
 */
module AdjClockDivider
#(
	parameter INPUT_BIT_WIDTH = 8
)
(
    input Clk,
    input ClkEnable,
    input [(INPUT_BIT_WIDTH-1):0] FrequencyDividerFactor,
    output reg ClkOutput,
	output reg ClkEnableOutput
);

    reg [(INPUT_BIT_WIDTH-1):0] InternalCounter;

    initial InternalCounter = 0;

    always @(posedge Clk)
    begin
	    ClkEnableOutput <= 0;
	    if(ClkEnable)
			 begin
				 InternalCounter <= InternalCounter + 1;
				 if(InternalCounter >= FrequencyDividerFactor - 1)
				 begin
					 InternalCounter <= 0;
					 ClkOutput <= !ClkOutput;
					 ClkEnableOutput <= 1;
				 end
			 end
    end
    
endmodule

`endif