`timescale 1ns / 1ps
`include "../../utils/test.v"
`include "SimpleALU.v"

`define do_op(code, a, b, out) \
        wait(Ready == 1); \
        Instruction = code; \
        InputA = a; \
        InputB = b; \
        wait(Ready == 0); \
        wait(Ready == 1); \
        `assert(ResultA, out);

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Test for SimpleALU module
 * 
 *
 * MIT License
 */
module TestSimpleALU
#(
    parameter INPUT_BIT_WIDTH  = 8,
    parameter INSTR_BIT_WIDTH  = 5,
    parameter FLAGS_COUNT      = 1,
    parameter CODE_INSTR_NOP   = 5'b00000,
    parameter CODE_INSTR_ADD   = 5'b00001,
    parameter CODE_INSTR_SUB   = 5'b00010,
    parameter CODE_INSTR_MUL   = 5'b00011,
    parameter CODE_INSTR_DIV   = 5'b00100,
    parameter CODE_INSTR_SHL   = 5'b00101,
    parameter CODE_INSTR_SHR   = 5'b00110,
    parameter CODE_INSTR_ROL   = 5'b00111,
    parameter CODE_INSTR_ROR   = 5'b01000,
    parameter CODE_INSTR_AND   = 5'b01001,
    parameter CODE_INSTR_XOR   = 5'b01011,
    parameter CODE_INSTR_OR   = 5'b01101,
    parameter CODE_INSTR_NAND = 5'b01110,
    parameter CODE_INSTR_XNOR = 5'b01111,
    parameter CODE_INSTR_GTH   = 5'b10000,
    parameter CODE_INSTR_EQU   = 5'b10001
);

    // Inputs
    `defClock(Clk, 2);
    reg [INSTR_BIT_WIDTH-1:0] Instruction;
    reg [INPUT_BIT_WIDTH-1:0] InputA;
    reg [INPUT_BIT_WIDTH-1:0] InputB;

    // Outputs
    wire [INPUT_BIT_WIDTH-1:0] ResultA;
    wire [INPUT_BIT_WIDTH-1:0] ResultB;
    wire [FLAGS_COUNT-1:0] Flags;
    wire Ready;

    // Instantiate the Unit Under Test (UUT)
    SimpleALU uut (
        .Clk(Clk),
        .Instruction(Instruction),
        .InputA(InputA),
        .InputB(InputB),
        .ResultA(ResultA),
        .ResultB(ResultB),
        .Flags(Flags),
        .Ready(Ready)
    );

    `startTest("SimpleALU")
        // Initialize Inputs
        Clk = 0;
        Instruction = CODE_INSTR_NOP;
        InputA = 0;
        InputB = 0;
        #100;
        
        `describe("Test add operation");
            `do_op(CODE_INSTR_ADD, 15, 7, 22);
          
        `describe("Test gth operation");
            `do_op(CODE_INSTR_GTH, 15, 7, 255);
       
       `describe("Test or operation");
            `do_op(CODE_INSTR_OR, 15, 7, 15);
       
       `describe("Test sub operation");
            `do_op(CODE_INSTR_SUB, 15, 7, 8);
       
       `describe("Test shl operation");
            `do_op(CODE_INSTR_SHL, 15, 7, 30);
       
       `describe("Test add operation");
            `do_op(CODE_INSTR_MUL, 15, 7, 105);
       
       `describe("Test div operation");
            `do_op(CODE_INSTR_DIV, 15, 7, 2);

    `endTest
   
      
endmodule

