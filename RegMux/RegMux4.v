`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_REG_MUX_4_V
`define LIB_STYCZYNSKI_REG_MUX_4_V

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * 4 to 1 MUX
 * 
 *
 * MIT License
 */
module RegMux4
#(
	parameter INPUT_BIT_WIDTH = 8,
    parameter BUS_WIDTH = 2
)
(
    input [INPUT_BIT_WIDTH-1:0] InputA,
    input [INPUT_BIT_WIDTH-1:0] InputB,
    input [INPUT_BIT_WIDTH-1:0] InputC,
    input [INPUT_BIT_WIDTH-1:0] InputD,
    input [BUS_WIDTH-1:0] Select, 
    output reg [INPUT_BIT_WIDTH-1:0] Output
);

	always@(*) begin
		case(Select[1:0])
			2'b00:	Output<=InputA;
			2'b01:	Output<=InputB;
			2'b10:	Output<=InputC;
			2'b11:	Output<=InputD;
		endcase
	end
    
endmodule

`endif