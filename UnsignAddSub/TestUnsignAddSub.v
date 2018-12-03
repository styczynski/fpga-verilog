`timescale 1ns / 1ps
`include "UnsignAddSub.v"

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Test for UnsignAddSub module
 * 
 *
 * MIT License
 */
module TestUnsignAddSub
#(
	parameter INPUT_BIT_WIDTH = 8
);

	// Inputs
	reg [INPUT_BIT_WIDTH-1:0] InputA;
	reg [INPUT_BIT_WIDTH-1:0] InputB;
	reg AddSubMode;
	reg Clk;

	// Outputs
	wire [INPUT_BIT_WIDTH-1:0] Result;


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

