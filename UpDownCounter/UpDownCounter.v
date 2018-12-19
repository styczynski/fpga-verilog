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
    parameter INPUT_BIT_WIDTH = 8,
    parameter MAX_VALUE = 2**INPUT_BIT_WIDTH-1,
    parameter MIN_VALUE = 0
)
(
    input Clk,
	 input ClkEnable,
    input Reset,
    input UpDownMode,
	 input Stop,
    output reg [INPUT_BIT_WIDTH-1:0] Output,
    output reg LimitReachedFlag
);

    initial Output = MIN_VALUE;

    always @(posedge Clk)
    begin
	     if(Reset)
            begin
                Output <= MIN_VALUE;
                LimitReachedFlag <= 0;
            end
        else if(Stop || !ClkEnable)
		     begin
			      // Do nothing
			  end
	     else if(UpDownMode)
            begin
                if(Output < MAX_VALUE)
                    begin
                        LimitReachedFlag <= 0;
                        Output <= Output + 1;
                    end
                else
                    begin
                        LimitReachedFlag <= 1;
                    end
            end
        else if(Output > MIN_VALUE)
            begin
                LimitReachedFlag <= 0;
                Output <= Output - 1;
            end
        else
            begin
                LimitReachedFlag <= 1;
            end
    end

endmodule

`endif