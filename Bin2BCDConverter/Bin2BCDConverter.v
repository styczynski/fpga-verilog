`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_BIN_2_DEC_CONVERTER_V
`define LIB_STYCZYNSKI_BIN_2_DEC_CONVERTER_V


/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Binary to BCD Converter
 * 
 *
 * MIT License
 */
module Bin2BCDConverter
#(
	parameter INPUT_BIT_WIDTH  = 8,
    parameter OUTPUT_DIGITS_COUNT = 3
)
(
    input [(INPUT_BIT_WIDTH-1):0] Input,
    output reg [0:(OUTPUT_DIGITS_COUNT*4-1)] Output
);

    integer i;
    integer j;
    
    always @(*)
    begin
    
        Output = {(OUTPUT_DIGITS_COUNT*4){1'b0}};
        
        //for(i=INPUT_BIT_WIDTH-1; i>=0; i=i-1)
        //begin
            for(j=0; j<OUTPUT_DIGITS_COUNT*4; j=j+4)
            begin
                if(Output[j:(j+3)] >= 5)
                begin
                    Output[j:(j+3)] = Output[j:(j+3)] + 3;
                end
            end
            
            for(j=0; j<(OUTPUT_DIGITS_COUNT-1)*4; j=j+4)
            begin
                Output[j:(j+3)] = Output[j:(j+3)] << 1;
                Output[(j+3)] = Output[(j+4)];
            end
            
            Output[((OUTPUT_DIGITS_COUNT-1)*4):(OUTPUT_DIGITS_COUNT*4-1)] = Output[((OUTPUT_DIGITS_COUNT-1)*4):(OUTPUT_DIGITS_COUNT*4-1)] << 1;
            Output[OUTPUT_DIGITS_COUNT*4-1] = Input[0];
        //end
    
    end
    
endmodule

`endif