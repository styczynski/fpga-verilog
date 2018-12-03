`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_TEST_SIGN_ADD_SUB_V
`define LIB_STYCZYNSKI_TEST_SIGN_ADD_SUB_V

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Test for SignAddSub module
 * 
 *
 * MIT License
 */
module TestSignAddSub
#(
	parameter INPUT_BIT_WIDTH = 8
);

	// Inputs
	reg signed [INPUT_BIT_WIDTH-1:0] InputA;
	reg signed [INPUT_BIT_WIDTH-1:0] InputB;
	reg AddSubMode;
	reg Clk;

	// Outputs
	wire [INPUT_BIT_WIDTH-1:0] Result;

	// Instantiate the Unit Under Test (UUT)
	SignDivider uut (
		.Quotient(Quotient),
		.AddSubMode(AddSubMode),
		.InputA(InputA),
		.InputB(InputB),
		.Clk(Clk),
        .Result(Result)
	);

	initial begin
		// Initialize Inputs
		AddSubMode = 0;
        InputA = 20;
        InputB = 8;
		Clk = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		#500;
		// Add stimulus here

	end

   initial begin
		$monitor("Clk=%d, AddSubMode=%d, InputA=%d, InputB=%d", Clk, AddSubMode, InputA, InputB);
	end
      
	always begin
		   Clk = #10 ~Clk;
	end
      
endmodule

`endif