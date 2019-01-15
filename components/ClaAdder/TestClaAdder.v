`timescale 1ns / 1ps

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

	initial begin
		// Initialize Inputs
		InputA = 0;
		InputB = 0;
		InputCarry = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		InputA = 5;
		InputB = 12;
		
		#100;
		
		  
		// Add stimulus here

	end
	
	initial begin
		$monitor("Input=%d + %d [carry=%d], Output=%d [carry=%d]", InputA, InputB, InputCarry, Sum, OutputCarry);
	end
      
endmodule

