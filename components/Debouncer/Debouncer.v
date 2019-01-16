`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_DEBOUNCER_V
`define LIB_STYCZYNSKI_DEBOUNCER_V

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Input debouncer
 * 
 *
 * MIT License
 */
module Debouncer
#(
    parameter DEBOUNCER_COUNTER_WIDTH = 19
) (
    input Clk,
    input Input,
    output reg State = 0,
    output Output
);

    reg Sync0 = 0, Sync1 = 0;

    reg [DEBOUNCER_COUNTER_WIDTH-1:0] Counter;
    wire Idle = (State == Sync1);
    wire Max = &Counter;

    always @(posedge Clk)
    begin
        Sync0 <= Input;
        Sync1 <= Sync0;
        if(Idle)
            Counter <= 0;
        else
        begin
            Counter <= Counter + 1;
            if(Max)
                State <= ~State;
        end
    end

    assign Output = ~Idle & Max & ~State;
endmodule

`endif 