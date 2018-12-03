`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_SIGN_ADD_SUB_V
`define LIB_STYCZYNSKI_SIGN_ADD_SUB_V

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Adder/substractor for signed operations
 * 
 *
 * MIT License
 */
module SignAddSub
#(
	parameter INPUT_BIT_WIDTH = 8
)
(
    input Clk,
    input signed [INPUT_BIT_WIDTH-1:0] InputA,
	input signed [INPUT_BIT_WIDTH-1:0] InputB,
	input wire AddSubMode,
	output reg signed [INPUT_BIT_WIDTH-1:0] Result
);

    always @(posedge Clk)
	begin
		if(AddSubMode)
			Result <= InputA + InputB;
		else
			Result <= InputA - InputB;
	end

endmodule

`endif