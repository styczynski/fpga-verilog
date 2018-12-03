`timescale 1ns / 1ps
`include "./Pow2_32.v"

`define assert(param, signal, value) \
        #1; \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m:"); \
            $display("  [pow2(%d)] signal != [%d], got: [%d]", param, value, signal); \
            $finish; \
        end

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Tests for fast calculation of 2 ** Input for 32-bit output
 *
 * MIT License
 */
module TestPow2_32
#(
    parameter MAX_VALUE_TO_TEST = 31
);

    // Inputs
    reg [4:0] Input;

	// Outputs
    wire [31:0] Output;

	// Instantiate the Unit Under Test (UUT)
	Pow2_32 uut(
		.Input(Input),
        .Output(Output)
	);

    integer i;
    
	initial begin
		// Initialize Inputs
		
        #100;
        
        for(i=0; i<=MAX_VALUE_TO_TEST; i=i+1)
        begin
            Input = i;
            #2;
            `assert(i, Output, 2**i);
        end
        
        
        $finish;
	end
      
endmodule

