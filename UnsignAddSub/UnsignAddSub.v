`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_UNSIGN_ADD_SUB_V
`define LIB_STYCZYNSKI_UNSIGN_ADD_SUB_V

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Adder/substractor for unsigned operations
 * 
 *
 * MIT License
 */
module UnsignAddSub
#(
	parameter INPUT_BIT_WIDTH = 8
)
(
    input Clk,
    input [INPUT_BIT_WIDTH-1:0] InputA,
	input [INPUT_BIT_WIDTH-1:0] InputB,
	output reg [INPUT_BIT_WIDTH-1:0] ResultA,
    output reg [INPUT_BIT_WIDTH-1:0] ResultB
);

    always @(posedge Clk)
	begin
		ResultA <= InputA + InputB;
        ResultB <= InputA - InputB;
	end

endmodule

`endif