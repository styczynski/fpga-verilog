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
module debounce(
    input Clk,
    input Input,
    output reg State,
    output Output
);

    reg Sync0, Sync1;
    always @(posedge Clk) Sync0 <= Input;
    always @(posedge Clk) Sync1 <= Sync0;

    reg [18:0] Counter;
    wire Idle = (State == Sync1);
    wire Max = &Counter;

    always @(posedge Clk)
    begin
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