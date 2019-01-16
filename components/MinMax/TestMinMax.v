`timescale 1ns / 1ps
`include "../../utils/test.v"
`include "MinMax.v"

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Test for MinMax module
 * 
 *
 * MIT License
 */
module TestMinMax
#(
	parameter INPUT_BIT_WIDTH = 32
);

	// Inputs
    `defClock(Clk, 2);
	reg [INPUT_BIT_WIDTH-1:0] InputA;
	reg [INPUT_BIT_WIDTH-1:0] InputB;

	// Outputs
	wire [INPUT_BIT_WIDTH-1:0] Max;
	wire [INPUT_BIT_WIDTH-1:0] Min;

	// Instantiate the Unit Under Test (UUT)
	MinMax #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH)
    ) uut (
		.Clk(Clk),
        .InputA(InputA),
        .InputB(InputB),
        .Max(Max),
        .Min(Min)
	);

    `startTest("MinMax")
    
        // Initialize Inputs
        Clk = 0;
        InputA = 0;
        InputB = 0;
        #500;
        
        `describe("Test InputA = InputB");
            
            InputA = 12; InputB = 12; #2;
            `assert(Max, 12);
            `assert(Min, 12);
            
            InputA = 0; InputB = 0; #2;
            `assert(Max, 0);
            `assert(Min, 0);
        
        `describe("Test InputA > InputB");
            
            InputA = 100; InputB = 0; #2;
            `assert(Max, 100);
            `assert(Min, 0);
            
            InputA = 1024; InputB = 1023; #2;
            `assert(Max, 1024);
            `assert(Min, 1023);
            
        `describe("Test InputA < InputB");
            
            InputA = 99; InputB = 100; #2;
            `assert(Max, 100);
            `assert(Min, 99);
            
            InputA = 15; InputB = 1024; #2;
            `assert(Max, 1024);
            `assert(Min, 15);
        
    `endTest
      
endmodule

