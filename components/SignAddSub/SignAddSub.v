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
    input [INPUT_BIT_WIDTH-1:0] InputA,
	input [INPUT_BIT_WIDTH-1:0] InputB,
	input wire AddSubMode,
	output reg [INPUT_BIT_WIDTH-1:0] Result,
    output reg [INPUT_BIT_WIDTH-1:0] ResultB
);

    always @(posedge Clk)
	begin
		if(AddSubMode)
            begin
                Result <= InputA + InputB;
                ResultB <= InputA - InputB;
            end
		else
            begin
                Result <= InputA - InputB;
                ResultB <= InputA + InputB;
            end
	end

endmodule

`endif