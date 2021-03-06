`timescale 1ns / 1ps
`default_nettype none
`ifndef LIB_STYCZYNSKI_FREQ_DIVIDER_V
`define LIB_STYCZYNSKI_FREQ_DIVIDER_V

module FreqDivider #(
        parameter FREQUENCY_IN = 2,
        parameter FREQUENCY_OUT = 1,
        parameter MAX_PPM = 1_000_000,
        parameter PHASE = 1'b0
    ) (
        input wire Reset,
        input wire Clk,
        output reg ClkOutput = PHASE,
        output reg ClkEnableOutput = PHASE
    );

    // This calculation always rounds frequency up.
    localparam COUNTER_VALUE = FREQUENCY_IN / FREQUENCY_OUT / 2 - 1;
    localparam ACTUAL_FREQUENCY = FREQUENCY_IN / ((COUNTER_VALUE + 1) * 2);
    localparam PPM = 64'd1_000_000 * (ACTUAL_FREQUENCY - FREQUENCY_OUT) / FREQUENCY_OUT;

    generate
        if(COUNTER_VALUE < 0)
            _ERROR_FREQ_TOO_HIGH_ error();
        if(PPM > MAX_PPM)
            _ERROR_FREQ_DEVIATION_TOO_HIGH_ error();
    endgenerate
    
    reg [$clog2(COUNTER_VALUE)+1:0] Counter = 0;
    
    always @(posedge Clk or negedge Reset)
    begin
        if(!Reset)
            begin
                Counter <= 0;
                ClkEnableOutput <= PHASE;
                ClkOutput <= PHASE;
            end
        else
            begin
                if(Counter == 0)
                    begin
                        Counter <= COUNTER_VALUE;
                        ClkOutput <= ~ClkOutput;
                        ClkEnableOutput <= ~ClkOutput;
                    end
                else
                    begin
                        ClkEnableOutput <= 0;
                        Counter <= Counter - 1;
                    end
        end
    end
        
endmodule

`endif