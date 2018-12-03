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
    input ClkInput,
    input [(INPUT_BIT_WIDTH-1):0] FrequencyDividerFactor,
    output wire ClkOutput
);

    reg [(INPUT_BIT_WIDTH-1):0] InternalCounter;

    always @(posedge ClkInput)
    begin
    
       InternalCounter <= InternalCounter + 1;
       if(InternalCounter == FrequencyDividerFactor)
       begin
          InternalCounter <= 0;
          ClkOutput <= !ClkOutput;
       end
    
    end
    
endmodule

`endif