`timescale 1ns / 1ps
`include "./MiniCalc.v"

`define assert(signal, value) \
        #1; \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
            $finish; \
        end

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
	reg Clk;
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

	initial begin
		// Initialize Inputs
		
        Clk = 0;
        Instruction = CODE_INSTR_ADD_SUB;
        InputA = 6;
        InputB = 3;
        
        #100;
        
        `assert(OutputA, 9);
		`assert(OutputB, 3);
        
		Instruction = CODE_INSTR_MIN_MAX;
        InputA = 6;
        InputB = 3;
        #2;
            
        `assert(OutputA, 6);
		`assert(OutputB, 3);
        
		Instruction = CODE_INSTR_MUL;
        InputA = 6;
        InputB = 3;
        #2;
        
        `assert(({OutputB, OutputA}), 18);
  
		Instruction = CODE_INSTR_NOP;
        InputA = 6;
        InputB = 3;
        #2;
        
        `assert(OutputA, 0);
		`assert(OutputB, 0);
     
		Instruction = CODE_INSTR_ADD_SUB;
        InputA = 8;
        InputB = 5;
		#5;
        
        `assert(OutputA, 13);
		`assert(OutputB, 3);
        
		Instruction = CODE_INSTR_MIN_MAX;
        InputA = 8;
        InputB = 5;
		#2;
        
        `assert(OutputA, 8);
		`assert(OutputB, 5);
       
        Instruction = CODE_INSTR_MIN_MAX;
        InputA = 5;
        InputB = 8;
        #2;
        
        `assert(OutputA, 8);
		`assert(OutputB, 5);
        
        Instruction = CODE_INSTR_DIV;
        InputA = 15;
        InputB = 2;
        #2;
        
        `assert(OutputA, 7);
		`assert(OutputB, 1);
        
        Instruction = CODE_INSTR_DIV;
        InputA = 10;
        InputB = 2;
        #5;
        
        `assert(OutputA, 5);
		`assert(OutputB, 0);
        
        Instruction = CODE_INSTR_DIV;
        InputA = 3;
        InputB = 11;
        #5;
        
        `assert(OutputA, 0);
		`assert(OutputB, 3);
        
        Instruction = CODE_INSTR_DIV;
        InputA = 0;
        InputB = 2;
        #2;
        
        `assert(OutputA, 0);
		`assert(OutputB, 0);
        
        $finish;
	end

      
	always begin
		#1 Clk = ~Clk;
	end
      
endmodule

