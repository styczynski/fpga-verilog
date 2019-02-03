`timescale 1ns / 1ps
`include "../../utils/test.v"
`include "./LUA.v"


/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Test for Multiplier module
 * 
 *
 * MIT License
 */
module LUATest;

	// Inputs
	reg [15:0] InputX;
	reg [15:0] InputY;
	reg Start;

	// Outputs
	wire [31:0] Address;
	wire Ready;

    `defClock(Clk, 2);
    
	// Instantiate the Unit Under Test (UUT)
	LUA #(
        .DATA_WIDTH(16),
        .BLOCK_SIZE(10)
    ) uut (
		.Clk(Clk),
        .InputX(InputX),
        .InputY(InputY),
        .Start(Start),
        .Address(Address),
        .Ready(Ready)
	);

	`startTest("LUA")
		// Initialize Inputs
		InputX = 0;
        InputY = 0;
        Start = 0;
        Clk = 0;
		#100;
        
        `describe("Test BLOCK_SIZE=10, X=4, Y=5");
            Start = 0; wait(Ready == 1);
            InputX = 4;
            InputY = 5;
            Start = 1;
            wait(Ready == 0);
            Start = 0;
            wait(Ready == 1);
            `assert(Address, 54);
        
	`endTest
      
endmodule

