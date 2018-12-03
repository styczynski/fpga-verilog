`timescale 1ns / 1ps
`include "./Bin2BCDConverter3.v"

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
 * Tests for binary to BCD Converter with 3 digits output
 *
 * MIT License
 */
module TestBin2BCDConverter3
#(
	parameter INPUT_BIT_WIDTH  = 16
);

    // Inputs
    reg [(INPUT_BIT_WIDTH-1):0] Input;

	// Outputs
    wire [0:3] Digit1;
    wire [0:3] Digit2;
    wire [0:3] Digit0;

	// Instantiate the Unit Under Test (UUT)
	Bin2BCDConverter3 #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH)
    ) uut(
		.Input(Input),
        .Digit2(Digit2),
        .Digit1(Digit1),
        .Digit0(Digit0)
	);

	initial begin
		// Initialize Inputs
		
        #100;
        
        Input = 0;
        #2;
        
        `assert("Input = 0", Digit2, 0);
        `assert("Input = 0", Digit1, 0);
        `assert("Input = 0", Digit0, 0);
        
        Input = 10;
        #2;
        
        `assert("Input = 10", Digit2, 0);
        `assert("Input = 10", Digit1, 1);
        `assert("Input = 10", Digit0, 0);
        
        Input = 142;
        #2;
        
        `assert("Input = 142", Digit2, 1);
        `assert("Input = 142", Digit1, 4);
        `assert("Input = 142", Digit0, 2);
        
        Input = 89;
        #2;
        
        `assert("Input = 89", Digit2, 0);
        `assert("Input = 89", Digit1, 8);
        `assert("Input = 89", Digit0, 9);
        
        Input = 33;
        #2;
        
        `assert("Input = 33", Digit2, 0);
        `assert("Input = 33", Digit1, 3);
        `assert("Input = 33", Digit0, 3);
        
        Input = 599;
        #2;
        
        `assert("Input = 599", Digit2, 5);
        `assert("Input = 599", Digit1, 9);
        `assert("Input = 599", Digit0, 9);
        
        $finish;
	end
      
endmodule

