`timescale 1ns / 1ps
`include "../../utils/test.v"
`include "./RegMux4.v"

`define do_select(num, value) \
        #50 Select = num; \
        `assert(Output, value);

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Test for RegMux4 module
 * 
 *
 * MIT License
 */
module TestRegMux4
#(
	parameter INPUT_BIT_WIDTH = 8,
    parameter BUS_WIDTH = 2
);

	// Inputs
    reg [INPUT_BIT_WIDTH-1:0] InputA;
    reg [INPUT_BIT_WIDTH-1:0] InputB;
    reg [INPUT_BIT_WIDTH-1:0] InputC;
    reg [INPUT_BIT_WIDTH-1:0] InputD;
    reg [BUS_WIDTH-1:0] Select;

	// Outputs
	wire [INPUT_BIT_WIDTH-1:0] Output;

	// Instantiate the Unit Under Test (UUT)
	RegMux4 uut (
		.InputA(InputA),
        .InputB(InputB),
        .InputC(InputC),
        .InputD(InputD),
        .Select(Select),
        .Output(Output)
	);

	`startTest("RegMux4")
		// Initialize Inputs
		InputA = 0;
        InputB = 0;
        InputC = 0;
        InputD = 0;
        Select = 0;
		#100;
        
        `describe("Test small const inputs switching");
            InputA = 42;
            InputB = 15;
            InputC = 2;
            InputD = 0;
            Select = 0;
        
            `do_select(0, 42);
            `do_select(1, 15);
            `do_select(2, 2);
            `do_select(3, 0);
            
	`endTest
      
endmodule

