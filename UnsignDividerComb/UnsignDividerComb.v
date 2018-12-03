`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_UNSIGN_DIVIDER_COMB_V
`define LIB_STYCZYNSKI_UNSIGN_DIVIDER_COMB_V

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Divider for signed integer division.
 * Integers are INPUT_BIT_WIDTH bits width.
 * 
 *
 * MIT License
 */
module UnsignDividerComb
#(
    parameter INPUT_BIT_WIDTH = 8
)
(
    input Clk,
    input [INPUT_BIT_WIDTH-1:0] Dividend,
    input [INPUT_BIT_WIDTH-1:0] Divider,
    output reg [INPUT_BIT_WIDTH-1:0] Quotient,
    output reg [INPUT_BIT_WIDTH-1:0] Remainder
);

    initial Quotient = 0;
    initial Remainder = 0;

    reg [INPUT_BIT_WIDTH-1:0] QuotientTemp;
    reg [INPUT_BIT_WIDTH-1:0] RemainderBuf;
    reg [INPUT_BIT_WIDTH:0] RemainderTemp;   
    integer i;

    always @(Dividend, Divider)
    begin
        QuotientTemp = Dividend;
        RemainderBuf = Divider;
        RemainderTemp = 0;
        for(i=0;i < INPUT_BIT_WIDTH;i=i+1)
            begin
                RemainderTemp = {RemainderTemp[INPUT_BIT_WIDTH-2:0], QuotientTemp[INPUT_BIT_WIDTH-1]};
                QuotientTemp[INPUT_BIT_WIDTH-1:1] = QuotientTemp[INPUT_BIT_WIDTH-2:0];
                RemainderTemp = RemainderTemp - RemainderBuf;
                if(RemainderTemp[INPUT_BIT_WIDTH-1] == 1)
                    begin
                        QuotientTemp[0] = 0;
                        RemainderTemp = RemainderTemp + RemainderBuf;
                    end
                else
                    QuotientTemp[0] = 1;
            end
            
        Quotient = QuotientTemp;
        Remainder = RemainderTemp[INPUT_BIT_WIDTH-1:0];
    end
        
endmodule

`endif