`timescale 1ns / 1ps
`include "../../utils/test.v"
`include "./ClaAdder.v"

`define assertCheckSum(a, b) \
        InputA = a; InputB = b; #100; \
        `assert(Sum, a+b);

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Test for ClaAdder module
 * 
 *
 * MIT License
 */
module TestClaAdder;

	// Inputs
	reg [7:0] InputA;
	reg [7:0] InputB;
	reg InputCarry;

	// Outputs
	wire [7:0] Sum;
	wire OutputCarry;

	// Instantiate the Unit Under Test (UUT)
	ClaAdder uut (
		.InputA(InputA), 
		.InputB(InputB), 
		.InputCarry(InputCarry), 
		.Sum(Sum), 
		.OutputCarry(OutputCarry)
	);

	`startTest("ClaAdder")
		// Initialize Inputs
		InputA = 0;
		InputB = 0;
		InputCarry = 0;
		#100;
        
        `describe("Add 5 + 12");
            `assertCheckSum(5, 12);
            
        `describe("Add 0 + 0");
            `assertCheckSum(0, 0);
        
        `describe("Add 128 + 127");
            `assertCheckSum(128, 127);
        
	`endTest
      
endmodule

