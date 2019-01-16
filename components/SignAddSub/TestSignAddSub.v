`timescale 1ns / 1ps
`include "../../utils/test.v"
`include "SignAddSub.v"

`define do_sub(a, b) \
        AddSubMode = 0; \
        InputA = a; \
        InputB = b; \
        #2; \
        `assert(Result, a-b);
        
`define do_add(a, b) \
        AddSubMode = 1; \
        InputA = a; \
        InputB = b; \
        #2; \
        `assert(Result, a+b);

`define do_add_sub(a, b) \
        `do_add(a, b); \
        `do_sub(a, b);

        
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
    `defClock(Clk, 2);
	reg signed [INPUT_BIT_WIDTH-1:0] InputA;
	reg signed [INPUT_BIT_WIDTH-1:0] InputB;
	reg AddSubMode;

	// Outputs
	wire [INPUT_BIT_WIDTH-1:0] Result;

	// Instantiate the Unit Under Test (UUT)
	SignAddSub uut (
		.AddSubMode(AddSubMode),
		.InputA(InputA),
		.InputB(InputB),
		.Clk(Clk),
        .Result(Result)
	);

	`startTest("SignAddSub");
		// Initialize Inputs
		AddSubMode = 0;
        InputA = 0;
        InputB = 0;
		Clk = 0;
		#100;
        
        `describe("Test 20 +/- 8");
            `do_add_sub(20, 8);
            
        `describe("Test 100 +/- 100");
            `do_add_sub(100, 100);
            
        `describe("Test 0 +/- 0");
            `do_add_sub(0, 0);

	`endTest

      
endmodule