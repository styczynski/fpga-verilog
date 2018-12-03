`timescale 1ns / 1ps
`include "SimpleALU.v"

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
	reg Clk;
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

	initial begin
		// Initialize Inputs
		
        Clk = 0;
        Instruction = CODE_INSTR_ADD;
        InputA = 15;
        InputB = 7;

		// Wait 100 ns for global reset to finish
		#100;
        
		  Instruction = CODE_INSTR_GTH;
        InputA = 15;
        InputB = 7;
		  
		#100;
        
		  Instruction = CODE_INSTR_OR;
        InputA = 15;
        InputB = 7;
		
		#100;
        
		  Instruction = CODE_INSTR_SUB;
        InputA = 15;
        InputB = 7;
		  
		#100;
        
		  Instruction = CODE_INSTR_SHL;
        InputA = 15;
        InputB = 7;
		  
		#100;
        
		  Instruction = CODE_INSTR_MUL;
        InputA = 15;
        InputB = 7;
		
		#100;
        
        Instruction = CODE_INSTR_DIV;
        InputA = 15;
        InputB = 7;
        
        #500;
		// Add stimulus here

	end

   initial begin
		$monitor("Clk=%d, Instruction=%d, InputA=%d, InputB=%d, ResultA=%d, ResultB=%d, Flags=%d, Ready=%d", Clk, Instruction, InputA, InputB, ResultA, ResultB, Flags, Ready);
	end
      
	always begin
		   Clk = #10 ~Clk;
	end
      
endmodule

