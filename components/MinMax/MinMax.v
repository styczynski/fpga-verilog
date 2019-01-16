`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_MIN_MAX_V
`define LIB_STYCZYNSKI_MIN_MAX_V

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Min-max arithmetic module
 * 
 *
 * MIT License
 */
module MinMax
#(
	parameter INPUT_BIT_WIDTH = 8
)
(
    input Clk,
    input [INPUT_BIT_WIDTH-1:0] InputA,
	input [INPUT_BIT_WIDTH-1:0] InputB,
	output reg [INPUT_BIT_WIDTH-1:0] Max,
    output reg [INPUT_BIT_WIDTH-1:0] Min
);

    always @(posedge Clk)
	begin
		if(InputA < InputB)
            begin
                Max <= InputB;
                Min <= InputA;
            end
        else
            begin
                Max <= InputA;
                Min <= InputB;
            end
	end

endmodule

`endif