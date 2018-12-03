`timescale 1ns / 1ps
`include "./UpDownCounter.v"

`define assert(label, signal, value) \
        #1; \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: "); \
            $display("   [%s] signal != [%d] Got: [%d]", label, value, signal); \
            $finish; \
        end
        
`define runClkTicks(ticksNo)     \
    for(i=0; i<ticksNo; i=i+1)   \
        begin                    \
            #2 Clk = 0;          \
            #2 Clk = 1;          \
            #2 Clk = 0;          \
        end
        
`define runReset                 \
    #2 Reset = 1;                \
    #2 Reset = 0;

`define countUp                  \
    #2 UpDownMode = 1;
    
`define countDown                \
    #2 UpDownMode = 0;
    
/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Tests for adjustable up/down counter
 *
 * MIT License
 */
module TestUpDownCounter
#(
    parameter INPUT_BIT_WIDTH = 8
);

    // Inputs
    reg Clk;
    reg Reset;
    reg UpDownMode;
    
	// Outputs
    wire [INPUT_BIT_WIDTH-1:0] Output;

	// Instantiate the Unit Under Test (UUT)
	UpDownCounter #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH)
    ) uut(
		.Clk(Clk),
        .Reset(Reset),
        .UpDownMode(UpDownMode),
        .Output(Output)
	);
    
    integer i;
    
	initial begin
		// Initialize Inputs
		
        Reset      = 1;
        Clk        = 0;
        UpDownMode = 1;
        
        #100;
        
        `countUp
        `runReset
        `runClkTicks(5);
        `assert("Assertion 1", Output, 5);
        
        `countDown
        `runClkTicks(3);
        `assert("Assertion 2", Output, 2);
        
        `runClkTicks(10);
        `assert("Assertion 3", Output, 0);
        
        `runClkTicks(10);
        `assert("Assertion 4", Output, 0);
        
        `countUp
        `runClkTicks(127);
        `assert("Assertion 5", Output, 127);
        
        `runClkTicks(2 ** 8);
        `assert("Assertion 6", Output, 2 ** 8 - 1);
        
        `runReset
        `assert("Assertion 7", Output, 0);
        
        $finish;
	end
      
endmodule

