`timescale 1ns / 1ps
`include "RegMux4.v"

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Test for RegMux4 module
 * 
 *
 * MIT License
 */
module TestRegMux
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

	initial begin
		// Initialize Inputs
		InputA = 0;
        InputB = 0;
        InputC = 0;
        InputD = 0;
        Select = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		InputA = 42;
        InputB = 15;
        InputC = 2;
        InputD = 0;
        Select = 0;
        
        #50 Select = 1;
        #50 Select = 2;
        #50 Select = 3;
        #50 Select = 2;
        #50 Select = 0;
        
	end

    initial begin
		$monitor("InputA=%d, InputB=%d, InputC=%d, InputD=%d, Select=%d, Output=%d", InputA, InputB, InputC, InputD, Select, Output);
	end
      
endmodule

