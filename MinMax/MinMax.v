`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_MIN_MAX_V
`define LIB_STYCZYNSKI_MIN_MAX_V

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Min-max arithmetic module
 * 
 *
 * MIT License
 */
module MinMax
#(
	parameter INPUT_BIT_WIDTH = 8
)
(
    input Clk,
    input signed [INPUT_BIT_WIDTH-1:0] InputA,
	input signed [INPUT_BIT_WIDTH-1:0] InputB,
	output reg [INPUT_BIT_WIDTH-1:0] ResultA,
    output reg [INPUT_BIT_WIDTH-1:0] ResultB
);

    always @(posedge Clk)
	begin
		if(InputA < InputB)
            begin
                ResultA <= InputB;
                ResultB <= InputA;
            end
        else
            begin
                ResultA <= InputA;
                ResultB <= InputB;
            end
	end

endmodule

`endif