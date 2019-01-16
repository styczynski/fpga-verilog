`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_SIMPLE_ALU_V
`define LIB_STYCZYNSKI_SIMPLE_ALU_V

`include "../SignAddSub/SignAddSub.v"
`include "../SignDivider/SignDivider.v"
`include "../RegMux/RegMux4.v"

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Simple ALU
 * 
 *
 * MIT License
 */
module SimpleALU
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
)
(
    input Clk,
    input [INSTR_BIT_WIDTH-1:0] Instruction,
    input [INPUT_BIT_WIDTH-1:0] InputA,
    input [INPUT_BIT_WIDTH-1:0] InputB,
    output wire [INPUT_BIT_WIDTH-1:0] ResultA,
    output wire [INPUT_BIT_WIDTH-1:0] ResultB,
    output reg [FLAGS_COUNT-1:0] Flags,
    output wire Ready
);

    wire DivReadyResult = 0;
    wire [INPUT_BIT_WIDTH-1:0] SignAddSubResult;
    wire [INPUT_BIT_WIDTH-1:0] DivQuotientResult;
    wire [INPUT_BIT_WIDTH-1:0] DivRemainderResult;
    
    reg [1:0] ResultAMuxSelect;
    reg [1:0] ResultBMuxSelect;
    reg [0:0] SignAddSubMode = 0;
    reg [0:0] DivSignMode = 0;

    reg [INPUT_BIT_WIDTH-1:0] EmptyResult;
    reg [INPUT_BIT_WIDTH-1:0] InternalResult;
    
    initial EmptyResult = 42;
    initial InternalResult = 0;
    
    RegMux4 #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH)
    ) resultAMuxModule(
        .InputA(SignAddSubResult),
        .InputB(DivQuotientResult),
        .InputC(InternalResult),
        .InputD(EmptyResult),
        .Select(ResultAMuxSelect),
        .Output(ResultA)
    );
    
    RegMux4 #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH)
    ) resultBMuxModule(
        .InputA(EmptyResult),
        .InputB(DivRemainderResult),
        .InputC(InternalResult),
        .InputD(EmptyResult),
        .Select(ResultBMuxSelect),
        .Output(ResultB)
    );

    SignAddSub #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH)
    ) signAddSubModule(
		.Clk(Clk),
        .InputA(InputA),
	 	.InputB(InputB),
		.AddSubMode(SignAddSubMode),
		.Result(SignAddSubResult)
	);
    
    SignDivider #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH)
    ) dividerModule(
		.Clk(Clk),
        .Sign(DivSignMode),
	 	.Dividend(InputA),
		.Divider(InputB),
		.Quotient(DivQuotientResult),
        .Remainder(DivRemainderResult),
        .Ready(Ready)
	);
    
    always @(*)
    begin
        case (Instruction)
            CODE_INSTR_ADD:
                begin
                    ResultAMuxSelect <= 0;
                    ResultBMuxSelect <= 0;
                    SignAddSubMode <= 1;
                    DivSignMode <= 0;
                end
		    CODE_INSTR_SUB:
                begin
                    ResultAMuxSelect <= 0;
                    ResultBMuxSelect <= 0;
                    SignAddSubMode <= 0;
                    DivSignMode <= 0;
                end
			CODE_INSTR_DIV:
                begin
                    ResultAMuxSelect <= 1;
                    ResultBMuxSelect <= 1;
                    SignAddSubMode <= 0;
                    DivSignMode <= 0;
                end
            CODE_INSTR_MUL:
                begin
                    ResultAMuxSelect <= 2;
                    ResultBMuxSelect <= 2;
                    SignAddSubMode <= 0;
                    DivSignMode <= 0;
                    InternalResult <= InputA * InputB;
                end
            CODE_INSTR_SHL:
                begin
                    ResultAMuxSelect <= 2;
                    ResultBMuxSelect <= 2;
                    SignAddSubMode <= 0;
                    DivSignMode <= 0;
                    InternalResult <= InputA << 1;
                end
            CODE_INSTR_SHR:
                begin
                    ResultAMuxSelect <= 2;
                    ResultBMuxSelect <= 2;
                    SignAddSubMode <= 0;
                    DivSignMode <= 0;
                    InternalResult <= InputA >> 1;
                end
            CODE_INSTR_ROL:
                begin
                    ResultAMuxSelect <= 2;
                    ResultBMuxSelect <= 2;
                    SignAddSubMode <= 0;
                    DivSignMode <= 0;
                    InternalResult <= {InputA[(INPUT_BIT_WIDTH-1):0], InputA[INPUT_BIT_WIDTH-1]};
                end
            CODE_INSTR_ROR:
                begin
                    ResultAMuxSelect <= 2;
                    ResultBMuxSelect <= 2;
                    SignAddSubMode <= 0;
                    DivSignMode <= 0;
                    InternalResult <= {InputA[0], InputA[(INPUT_BIT_WIDTH-1):1]};
                end
            CODE_INSTR_AND:
                begin
                    ResultAMuxSelect <= 2;
                    ResultBMuxSelect <= 2;
                    SignAddSubMode <= 0;
                    DivSignMode <= 0;
                    InternalResult <= InputA & InputB;
                end
            CODE_INSTR_OR:
                begin
                    ResultAMuxSelect <= 2;
                    ResultBMuxSelect <= 2;
                    SignAddSubMode <= 0;
                    DivSignMode <= 0;
                    InternalResult <= InputA | InputB;
                end
            CODE_INSTR_XOR:
                begin
                    ResultAMuxSelect <= 2;
                    ResultBMuxSelect <= 2;
                    SignAddSubMode <= 0;
                    DivSignMode <= 0;
                    InternalResult <= InputA ^ InputB;
                end
            CODE_INSTR_NAND:
                begin
                    ResultAMuxSelect <= 2;
                    ResultBMuxSelect <= 2;
                    SignAddSubMode <= 0;
                    DivSignMode <= 0;
                    InternalResult <= ~(InputA & InputB);
                end
            CODE_INSTR_XNOR:
                begin
                    ResultAMuxSelect <= 2;
                    ResultBMuxSelect <= 2;
                    SignAddSubMode <= 0;
                    DivSignMode <= 0;
                    InternalResult <=  ~(InputA ^ InputB);
                end
            CODE_INSTR_GTH:
                begin
                    ResultAMuxSelect <= 2;
                    ResultBMuxSelect <= 2;
                    SignAddSubMode <= 0;
                    DivSignMode <= 0;
                    InternalResult <= (InputA > InputB)?({INPUT_BIT_WIDTH{1'b1}}):({INPUT_BIT_WIDTH{1'b0}});
                end
            CODE_INSTR_EQU:
                begin
                    ResultAMuxSelect <= 2;
                    ResultBMuxSelect <= 2;
                    SignAddSubMode <= 0;
                    DivSignMode <= 0;
                    InternalResult <= (InputA == InputB)?({INPUT_BIT_WIDTH{1'b1}}):({INPUT_BIT_WIDTH{1'b0}});
                end
        endcase
    end

endmodule

`endif