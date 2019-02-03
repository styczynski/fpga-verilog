`timescale 1ns / 1ps
`include "../../utils/test.v"
`include "./SignDivider.v"

`define do_div(a, b) \
        wait(Ready == 1); \
        Dividend = a; \
        Divider = b; \
        wait(Ready == 0); \
        wait(Ready == 1); \
        `assert(Quotient, a/b); \
        `assert(Remainder, a%b);

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Test for SignDivider module
 * 
 *
 * MIT License
 */
module TestSignDivider
#(
	parameter INPUT_BIT_WIDTH = 8
);

	// Inputs
    `defClock(Clk, 2);
	reg [INPUT_BIT_WIDTH-1:0] Dividend;
	reg [INPUT_BIT_WIDTH-1:0] Divider;
	reg Sign;

	// Outputs
	wire Ready;
	wire [INPUT_BIT_WIDTH-1:0] Quotient;
	wire [INPUT_BIT_WIDTH-1:0] Remainder;

	// Instantiate the Unit Under Test (UUT)
	SignDivider uut (
		.Ready(Ready), 
		.Quotient(Quotient), 
		.Remainder(Remainder), 
		.Dividend(Dividend), 
		.Divider(Divider), 
		.Sign(Sign), 
		.Clk(Clk)
	);

    `startTest("SignDivider");
        // Initialize Inputs
		Dividend = 0;
		Divider = 0;
		Sign = 0;
		Clk = 0;
		#100;
    
        `describe("Test 13 / 2");
            `do_div(13, 2);
            
        `describe("Test 69 / 42");
            `do_div(69, 42);
    
        `describe("Test 255 / 5");
            `do_div(255, 5);
        
        `describe("Test 77 / 1");
            `do_div(77, 1);
            
         `describe("Test 150 / 150");
            `do_div(150, 150);
    `endTest
      
endmodule

