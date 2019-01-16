`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_FREQ_DIVIDER_V
`define LIB_STYCZYNSKI_FREQ_DIVIDER_V

module FreqDivider #(
        parameter FREQUENCY_IN = 2,
        parameter FREQUENCY_OUT = 1,
        parameter INITIAL_CLOCK_PHASE = 1'b1
    ) (
        input  Reset,
        input  Clk,
        output reg ClkOutput = INITIAL_CLOCK_PHASE
    );

    /* Calculate counter width for desired frequencies */
    localparam COUNTER_PARAM = FREQUENCY_IN / FREQUENCY_OUT / 2 - 1;

    reg [$clog2(COUNTER_PARAM):0] Counter = 0;
    
    always @(posedge Clk or negedge Reset)
    begin
        if(!Reset)
            begin
                Counter <= 0;
                ClkOutput <= INITIAL_CLOCK_PHASE;
            end
        else
            begin
                if(Counter == 0)
                    begin
                        ClkOutput <= ~ClkOutput;
                        Counter <= COUNTER_PARAM;
                    end
                else
                    begin
                        Counter <= Counter - 1;
                    end
        end
    end
        
endmodule

`endif