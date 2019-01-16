`timescale 1ns / 1ps
`include "../../utils/test.v"
`include "MiniCalc.v"

`define do_op(code, a, b, outA, outB) \
        Instruction = code; \
        InputA = a; \
        InputB = b; \
        #100; \
        `assert(OutputA, outA); \
        `assert(OutputB, outB);

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Test for MiniCalc module
 *
 * MIT License
 */
module TestMiniCalc
#(
	parameter INPUT_BIT_WIDTH  = 8,
    parameter INSTR_BIT_WIDTH  = 4,
    parameter CODE_INSTR_NOP       = 4'b1111,
    parameter CODE_INSTR_ADD_SUB   = 4'b0111,
    parameter CODE_INSTR_MIN_MAX   = 4'b1011,
    parameter CODE_INSTR_MUL       = 4'b1101,
    parameter CODE_INSTR_DIV       = 4'b1110
);

    // Inputs
	`defClock(Clk, 2);
    reg [INSTR_BIT_WIDTH-1:0] Instruction;
    reg [INPUT_BIT_WIDTH-1:0] InputA;
    reg [INPUT_BIT_WIDTH-1:0] InputB;

	// Outputs
	wire [INPUT_BIT_WIDTH-1:0] OutputA;
    wire [INPUT_BIT_WIDTH-1:0] OutputB;

	// Instantiate the Unit Under Test (UUT)
	MiniCalc uut (
		.Clk(Clk),
        .Instruction(Instruction),
        .InputA(InputA),
        .InputB(InputB),
        .OutputA(OutputA),
        .OutputB(OutputB)
	);

	`startTest("MiniCalc")
		// Initialize Input
        Clk = 0;
        Instruction = CODE_INSTR_NOP;
        InputA = 0;
        InputB = 0;
        #100;
        
        `describe("Test add/sub operation");
            `do_op(CODE_INSTR_ADD_SUB, 6, 3, 9, 3);
            `do_op(CODE_INSTR_ADD_SUB, 8, 5, 13, 3);
            
         `describe("Test min/max operation");
            `do_op(CODE_INSTR_MIN_MAX, 6, 3, 6, 3);
            `do_op(CODE_INSTR_MIN_MAX, 10, 2, 10, 2);
            `do_op(CODE_INSTR_MIN_MAX, 3, 11, 11, 3);
            `do_op(CODE_INSTR_MIN_MAX, 0, 2, 2, 0);
            
        `describe("Test min/max operation when swapping");
            `do_op(CODE_INSTR_MIN_MAX, 8, 5, 8, 5);
            `do_op(CODE_INSTR_MIN_MAX, 5, 8, 8, 5);
        
        `describe("Test mul operation");
            `do_op(CODE_INSTR_MUL, 6, 3, 18, 0);
        
        `describe("Test nop operation");
            `do_op(CODE_INSTR_NOP, 6, 3, 0, 0);
        
        `describe("Test div operation");
            `do_op(CODE_INSTR_DIV, 15, 2, 7, 1);
        
        
    `endTest

      
endmodule

