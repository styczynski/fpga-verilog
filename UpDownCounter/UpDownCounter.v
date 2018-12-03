`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_UP_DOWN_COUNTER_V
`define LIB_STYCZYNSKI_UP_DOWN_COUNTER_V


/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Adjustable up/down counter
 * 
 *
 * MIT License
 */
module UpDownCounter
#(
    parameter INPUT_BIT_WIDTH = 8
)
(
    input Clk,
    input Reset,
    input UpDownMode,
    output reg [INPUT_BIT_WIDTH-1:0] Output
);

    always @(posedge Clk or posedge Reset)
    begin
        if(Reset)
            begin
                Output <= {INPUT_BIT_WIDTH{1'b0}};
            end
        else if(UpDownMode == 1)
            begin
                if(Output < 2**INPUT_BIT_WIDTH-1)
                begin
                    Output <= Output + 1;
                end
            end
        else if(Output > 0)
            begin
                Output <= Output - 1;
            end
    end

endmodule

`endif