`timescale 1ns / 1ps
`include "./Bin2BCDConverter.v"

`define assert(label, signal, value) \
        #1; \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m:"); \
            $display("  [%s] signal != value", label); \
            $finish; \
        end

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Tests for binary to BCD Converter
 *
 * MIT License
 */
module TestBin2BCDConverter
#(
	parameter INPUT_BIT_WIDTH  = 8,
    parameter OUTPUT_DIGITS_COUNT = 3
);

    // Inputs
    reg [(INPUT_BIT_WIDTH-1):0] Input;

	// Outputs
    wire [0:(OUTPUT_DIGITS_COUNT*4-1)] Output;

	// Instantiate the Unit Under Test (UUT)
	Bin2BCDConverter #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH),
        .OUTPUT_DIGITS_COUNT(OUTPUT_DIGITS_COUNT)
    ) uut(
		.Input(Input),
        .Output(Output)
	);

	initial begin
		// Initialize Inputs
		
        #100;
        
        $display("output = %d", Output);
        
        $finish;
	end
      
endmodule

