`timescale 1ns / 1ps
`include "../../utils/test.v"
`include "Debouncer.v"

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Test for Debouncer module
 * 
 *
 * MIT License
 */
module TestDebouncer;

	// Inputs
    `defClock(Clk, 2);
	reg Input;

	// Outputs
	wire Output;

	// Instantiate the Unit Under Test (UUT)
	Debouncer #(
        .DEBOUNCER_COUNTER_WIDTH(3)
    ) uut (
		.Clk(Clk),
        .Input(Input),
        .Output(Output)
	);

    `startTest("Debouncer")
    
        // Initialize Inputs
        Clk = 0;
        Input = 0;
        #500;
        
        `describe("Test oscillating input");
            
            Input = 1; #2; `assert(Output, 0);
            Input = 0; #2; `assert(Output, 0);
            Input = 1; #2; `assert(Output, 0);
            Input = 0; #2; `assert(Output, 0);
            Input = 0; #2; `assert(Output, 0);
            Input = 0; #2; `assert(Output, 0);
            Input = 0; #2; `assert(Output, 0);
            Input = 1; #2; `assert(Output, 0);
            Input = 1; #2; `assert(Output, 0);
            Input = 1; #2; `assert(Output, 0);
            Input = 1; #2; `assert(Output, 0);
            Input = 1; #2; `assert(Output, 0);
            Input = 1; #2; `assert(Output, 1);
            for(int i=0;i<20;i=i+1)
                begin
                    Input = 1; #2; `assert(Output, 0);
                end
            for(int i=0;i<500;i=i+1)
                begin
                    Input = 0; #2; `assert(Output, 0);
                end
            
            
        
    `endTest
      
endmodule

