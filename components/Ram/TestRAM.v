`timescale 1ns / 1ps
`include "../../utils/test.v"
`include "./RAM.v"

`define do_write(addr, value) \
        Addr = addr; Write = 1; Input = value; #2;

`define do_read(addr, value) \
        Addr = addr; Write = 0; Input = 0; #2; \
        `assert(Output, value);
        
/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Test for RAM module
 * 
 *
 * MIT License
 */
module TestRam #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
);

	// Inputs
    `defClock(Clk, 2);
	reg [ADDR_WIDTH-1:0] Addr;
    reg Write;
    reg [DATA_WIDTH-1:0] Input;

	// Outputs
	wire [DATA_WIDTH-1:0] Output;

	// Instantiate the Unit Under Test (UUT)
	RAM #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
		.Clk(Clk),
        .Addr(Addr),
        .Write(Write),
        .Input(Input),
        .Output(Output)
	);

    `startTest("RAM")
    
        // Initialize Inputs
        Clk = 0;
        Addr = 0;
        Write = 0;
        Input = 0;
        #500;
        
        `describe("Test write and read");
            
            `do_write(0, 42);
            `do_read(0, 42);
           
        `describe("Multiple sequential writes then sequential reads");
            
            for (int i=0; i<100; i=i+1) begin
                `do_write(i, i);
            end
            
            for (int i=0; i<100; i=i+1) begin
                `do_read(i, i);
            end
            
        
    `endTest
      
endmodule

