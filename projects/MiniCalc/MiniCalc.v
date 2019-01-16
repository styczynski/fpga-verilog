`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_MINI_CALC_V
`define LIB_STYCZYNSKI_MINI_CALC_V

`include "../../components/RegMux/RegMux4.v"
`include "../../components/UnsignDividerComb/UnsignDividerComb.v"
`include "../../components/SignAddSub/SignAddSub.v"
`include "../../components/MinMax/MinMax.v"

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Mini calculator
 * 
 *
 * MIT License
 */
module MiniCalc
#(
	parameter INPUT_BIT_WIDTH  = 8,
    parameter INSTR_BIT_WIDTH  = 4,
    parameter CODE_INSTR_NOP       = 4'b1111,
    parameter CODE_INSTR_ADD_SUB   = 4'b0111,
    parameter CODE_INSTR_MIN_MAX   = 4'b1011,
    parameter CODE_INSTR_MUL       = 4'b1101,
    parameter CODE_INSTR_DIV       = 4'b1110
)
(
    input Clk,
    input [INSTR_BIT_WIDTH-1:0] Instruction,
    input [INPUT_BIT_WIDTH-1:0] InputA,
    input [INPUT_BIT_WIDTH-1:0] InputB,
    output wire [INPUT_BIT_WIDTH-1:0] OutputA,
    output wire [INPUT_BIT_WIDTH-1:0] OutputB
);

    reg [1:0] OutputSelect;
    
    wire [INPUT_BIT_WIDTH-1:0] DivQuotientOutput;
    wire [INPUT_BIT_WIDTH-1:0] DivRemainderOutput;
    wire [INPUT_BIT_WIDTH-1:0] AddSubAOutput;
    wire [INPUT_BIT_WIDTH-1:0] AddSubBOutput;
    wire [INPUT_BIT_WIDTH-1:0] MinMaxAOutput;
    wire [INPUT_BIT_WIDTH-1:0] MinMaxBOutput;
    
    reg [INPUT_BIT_WIDTH-1:0] InternalAOutput;
    reg [INPUT_BIT_WIDTH-1:0] InternalBOutput;
    
    RegMux4 #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH)
    ) outputAMuxModule(
        .InputA(DivQuotientOutput),
        .InputB(AddSubAOutput),
        .InputC(MinMaxAOutput),
        .InputD(InternalAOutput),
        .Select(OutputSelect),
        .Output(OutputA)
    );
    
    RegMux4 #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH)
    ) outputBMuxModule(
        .InputA(DivRemainderOutput),
        .InputB(AddSubBOutput),
        .InputC(MinMaxBOutput),
        .InputD(InternalBOutput),
        .Select(OutputSelect),
        .Output(OutputB)
    );
    
    UnsignDividerComb #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH)
    ) dividerCombModule (
		.Quotient(DivQuotientOutput),
		.Remainder(DivRemainderOutput), 
		.Dividend(InputA), 
		.Divider(InputB), 
		.Clk(Clk)
	);
    
    SignAddSub #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH)
    ) addSubModule (
        .Result(AddSubBOutput),
        .ResultB(AddSubAOutput),
        .InputA(InputA),
        .InputB(InputB),
        .Clk(Clk)
    );
    
    MinMax #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH)
    ) minMaxModule (
        .Max(MinMaxAOutput),
        .Min(MinMaxBOutput),
        .InputA(InputA),
        .InputB(InputB),
        .Clk(Clk)
    );
    
    
    always @(InputA, InputB, Instruction)
    begin
        casez(Instruction)
            CODE_INSTR_DIV:
                begin
                    OutputSelect <= 2'b00;
                    //InternalAOutput <= {INPUT_BIT_WIDTH-1{x}};
                    //InternalBOutput <= {INPUT_BIT_WIDTH-1{x}};
                end
            CODE_INSTR_ADD_SUB:
                begin
                    OutputSelect <= 2'b01;
                    //InternalAOutput <= {INPUT_BIT_WIDTH-1{x}};
                    //InternalBOutput <= {INPUT_BIT_WIDTH-1{x}};
                end
            CODE_INSTR_MIN_MAX:
                begin
                    OutputSelect <= 2'b10;
                    //InternalAOutput <= {INPUT_BIT_WIDTH-1{x}};
                    //InternalBOutput <= {INPUT_BIT_WIDTH-1{x}};
                end
            CODE_INSTR_MUL:
                begin
                    OutputSelect <= 2'b11;
                    {InternalBOutput, InternalAOutput} <= InputA * InputB;
                end
            CODE_INSTR_NOP:
                begin
                    OutputSelect <= 2'b11;
                    InternalAOutput <= 0;
                    InternalBOutput <= 0;
                end
            default:
                begin
                    OutputSelect <= 2'b11;
                    InternalAOutput <= InputA;
                    InternalBOutput <= InputB;
                end
        endcase
    end

endmodule

`endif