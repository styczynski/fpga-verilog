`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_CLA_ADDER_V
`define LIB_STYCZYNSKI_CLA_ADDER_V

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Carry-lookahead adder.
 * 
 *
 * MIT License
 */
module ClaAdder
#(
	parameter INPUT_BIT_WIDTH = 8
)
(
	input [INPUT_BIT_WIDTH-1:0] InputA,
	input [INPUT_BIT_WIDTH-1:0] InputB,
	input InputCarry,
	output [INPUT_BIT_WIDTH-1:0] Sum,
	output OutputCarry
);

    // Internal state
    wire [INPUT_BIT_WIDTH-1:0] CarryPropagate, CarryGenerate;
    wire [INPUT_BIT_WIDTH:0] Carry;

    assign Carry[0] = InputCarry;

    genvar i;

    // Compute generate/propagate carries
    generate for (i=0; i<INPUT_BIT_WIDTH; i=i+1)
        begin: pq_cla
            assign CarryPropagate[i] = InputA[i] ^ InputB[i];
            assign CarryGenerate[i] = InputA[i] & InputB[i];
        end
    endgenerate

    // Compute carry for each stage
    generate for (i=1; i<INPUT_BIT_WIDTH+1; i=i+1)
        begin: carry_cla
            assign Carry[i] = CarryGenerate[i-1] | (CarryPropagate[i-1] & Carry[i-1]);
        end
    endgenerate

    // Compute sum of carries
    generate for (i=0; i<INPUT_BIT_WIDTH; i=i+1)
        begin: sum_cla
            assign Sum[i] = CarryPropagate[i] ^ Carry[i];
        end
    endgenerate

    // Assign final output carry bit
    assign OutputCarry = Carry[INPUT_BIT_WIDTH];

endmodule

`endif
