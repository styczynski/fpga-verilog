`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_BIN_2_DEC_CONVERTER_3_V
`define LIB_STYCZYNSKI_BIN_2_DEC_CONVERTER_3_V


/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Binary to BCD Converter with 3 digits output
 * 
 *
 * MIT License
 */
module Bin2BCDConverter3
#(
	parameter INPUT_BIT_WIDTH  = 8
)
(
    input [(INPUT_BIT_WIDTH-1):0] Input,
    output reg [3:0] Digit2,
    output reg [3:0] Digit1,
    output reg [3:0] Digit0
);

    integer i;
    
    always @(*)
    begin
        Digit2 = 4'd0;
        Digit1 = 4'd0;
        Digit0 = 4'd0;
    
        for(i=INPUT_BIT_WIDTH-1; i>=0; i=i-1)
        begin
            if(Digit2 >= 5)
                Digit2 = Digit2 + 3;
            if(Digit1 >= 5)
                Digit1 = Digit1 + 3;
            if(Digit0 >= 5)
                Digit0 = Digit0 + 3;
                
            Digit2 = Digit2 << 1;
            Digit2[0] = Digit1[3];
            
            Digit1 = Digit1 << 1;
            Digit1[0] = Digit0[3];
            
            Digit0 = Digit0 << 1;
            Digit0[0] = Input[i];
        end
    end
    
endmodule

`endif