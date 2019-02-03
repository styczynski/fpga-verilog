`timescale 1ns / 1ps
`include "../../utils/test.v"
`include "./Multiplier.v"


/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Test for Multiplier module
 * 
 *
 * MIT License
 */
module TestClaAdder;

	// Inputs
	reg [15:0] InputA;
	reg [15:0] InputB;
	reg Start;

	// Outputs
	wire [31:0] Product;
	wire Ready;

    `defClock(Clk, 2);
    
	// Instantiate the Unit Under Test (UUT)
	Multiplier #(
        .DATA_WIDTH(16)
    ) uut (
		.Clk(Clk),
        .InputA(InputA),
        .InputB(InputB),
        .Start(Start),
        .Product(Product),
        .Ready(Ready)
	);

	`startTest("Multiplier")
		// Initialize Inputs
		InputA = 0;
        InputB = 0;
        Start = 0;
        Clk = 0;
		#100;
        
        `describe("Multiply 4*5");
            Start = 0; wait(Ready == 1);
            InputA = 4;
            InputB = 5;
            Start = 1;
            wait(Ready == 0);
            Start = 0;
            wait(Ready == 1);
            `assert(Product, 20);
        
	`endTest
      
endmodule

