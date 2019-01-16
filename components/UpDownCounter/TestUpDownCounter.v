`timescale 1ns / 1ps
`include "../../utils/test.v"
`include "./UpDownCounter.v"       
        
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
    `defClock(Clk, 2);
    reg Reset;
    reg UpDownMode;
    
	// Outputs
    wire [INPUT_BIT_WIDTH-1:0] Output;
    wire LimitReachedFlag;

	// Instantiate the Unit Under Test (UUT)
	UpDownCounter #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH)
    ) uut(
		.Clk(Clk),
        .ClkEnable(1'b1),
        .Reset(Reset),
        .Stop(1'b0),
        .UpDownMode(UpDownMode),
        .Output(Output),
        .LimitReachedFlag(LimitReachedFlag)
	);
    
    integer i;
    
	`startTest("UpDownCounter")
		// Initialize Inputs
        Reset      = 1;
        Clk        = 0;
        UpDownMode = 1;
        #100;
        
        `describe("Test basic up counting");
            `countUp;
            `runReset;
            #10; `assert(Output, 5);
        
        `describe("Test basic down counting");
            `countDown;
            #6; `assert(Output, 2);
        
            #20; `assert(Output, 0);
            
        `describe("Test overflow prevention");
            `countUp;
            #254; `assert(Output, 128);
            
            #(2 ** 9); `assert(Output, 2 ** 8 - 1);
        
        `describe("Test counter reset");
            Reset = 1;
            #2;
            `assert(Output, 0);
    
    `endTest    
    
      
endmodule

