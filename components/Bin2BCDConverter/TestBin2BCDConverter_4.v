`timescale 1ns / 1ps
`include "../../utils/test.v"
`include "./Bin2BCDConverter_4.v"

`define assertDigitsValue(d0, d1, d2, d3) \
        `assert(Digit3, d3); \
        `assert(Digit2, d2); \
        `assert(Digit1, d1); \
        `assert(Digit0, d0);
        
`define assertDigits(value) \
       `assertDigitsValue((value/1000)%10, (value/100)%10, (value/10)%10, (value)%10);
        
`define assertSetCheckDigit(value) \
        Input = value; #2; \
        `assertDigits(value);
    
/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Tests for binary to BCD Converter with 4 digits output
 *
 * MIT License
 */
module TestBin2BCDConverter_4
#(
	parameter INPUT_BIT_WIDTH  = 16
);

    // Inputs
    reg [(INPUT_BIT_WIDTH-1):0] Input;

	// Outputs
    wire [0:3] Digit3;
    wire [0:3] Digit2;
    wire [0:3] Digit1;
    wire [0:3] Digit0;

	// Instantiate the Unit Under Test (UUT)
	Bin2BCDConverter_4 #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH)
    ) uut(
		.Input(Input),
        .Digit3(Digit0),
        .Digit2(Digit1),
        .Digit1(Digit2),
        .Digit0(Digit3)
	);

	`startTest("Bin2BCDConverter_4")
		// Initialize Inputs
        #100;
        
        `describe("Test Input = 0");
            `assertSetCheckDigit(0);
        
        `describe("Test Input = 10");
            `assertSetCheckDigit(10);
        
        `describe("Test Input = 142");
            `assertSetCheckDigit(142);
            
        `describe("Test Input = 89");
            `assertSetCheckDigit(89);
        
        `describe("Test Input = 33");
            `assertSetCheckDigit(33);
        
        `describe("Test Input = 599");
            `assertSetCheckDigit(599);
        
    `endTest
      
endmodule

