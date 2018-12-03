`timescale 1ns / 1ps
`include "UnsignDividerComb.v"

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Test for UnsignDividerComb module
 * 
 *
 * MIT License
 */
module TestUnsignDividerComb
#(
	parameter INPUT_BIT_WIDTH = 8
);

	// Inputs
	reg [INPUT_BIT_WIDTH-1:0] Dividend;
	reg [INPUT_BIT_WIDTH-1:0] Divider;
	reg Clk;

	// Outputs
	wire [INPUT_BIT_WIDTH-1:0] Quotient;
	wire [INPUT_BIT_WIDTH-1:0] Remainder;

	// Instantiate the Unit Under Test (UUT)
	UnsignDividerComb uut (
		.Quotient(Quotient), 
		.Remainder(Remainder), 
		.Dividend(Dividend), 
		.Divider(Divider), 
		.Clk(Clk)
	);

	initial begin
		// Initialize Inputs
		Dividend = 13;
		Divider = 2;
		Clk = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		#500;
		// Add stimulus here

	end

   initial begin
		$monitor("Clk=%d, Dividend=%d, Divider=%d, Quotient=%d, Remainder=%d", Clk, Dividend, Divider, Quotient, Remainder);
	end
      
	always begin
		   Clk = #50 ~Clk;
	end
      
endmodule

