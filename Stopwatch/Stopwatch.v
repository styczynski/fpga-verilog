`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_STOPWATCH_V
`define LIB_STYCZYNSKI_STOPWATCH_V

`include "../UpDownCounter/UpDownCounter.v"
`include "../Pow2/Pow2_32.v"
`include "../Bin2BCDConverter/Bin2BCDConverter_4.v"
`include "../SegmentLedHexDecoder/SegmentLedHexDecoder.v"
`include "../AdjClockDivider/AdjClockDivider.v"


/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Stopwatch
 * 
 *
 * MIT License
 */
module Stopwatch
(
    input Clk,
    input Reset,
    input Stop,
    input Up,
    input Down,
    input [4:0] Speed,
    output reg [2:0] ModeOutput,
    output wire [6:0] LEDDisp3,
    output wire [6:0] LEDDisp2,
    output wire [6:0] LEDDisp1,
    output wire [6:0] LEDDisp0
);

    reg UpDownMode;
    reg StopMode;
    
    wire CounterTriggerClk;
    wire CounterOutput; 
    
    wire [3:0] CounterBCDDigit3;
    wire [3:0] CounterBCDDigit2;
    wire [3:0] CounterBCDDigit1;
    wire [3:0] CounterBCDDigit0;
    
    wire [31:0] FrequencyDividerFactor;
    
    Pow2_32 speedPowScaler (
        .Input(Speed),
        .Output(FrequencyDividerFactor)
    );
    
    AdjClockDivider #(
        .INPUT_BIT_WIDTH(32)
    ) clockDivider (
        .ClkInput(Clk),
        .FrequencyDividerFactor(FrequencyDividerFactor),
        .ClkOutput(CounterTriggerClk)
    );
    
    UpDownCounter #(
        .INPUT_BIT_WIDTH(8),
        .MAX_VALUE(9999)
    ) upDownCounter (
		.Clk(CounterTriggerClk),
        .Reset(Reset),
        .UpDownMode(UpDownMode),
        .Output(CounterOutput),
        .LimitReachedFlag(ModeOutput)
	);
    
    Bin2BCDConverter_4 #(
        .INPUT_BIT_WIDTH(8)
    ) bin2BCDConverter (
		.Input(CounterOutput),
        .Digit3(CounterBCDDigit3),
        .Digit2(CounterBCDDigit2),
        .Digit1(CounterBCDDigit1),
        .Digit0(CounterBCDDigit0),
	);
    
    SegmentLedHexDecoder hexDecoder3 (
        .HexDigit(CounterBCDDigit3),
        .Segments(LEDDisp3)
    );
    
    SegmentLedHexDecoder hexDecoder2 (
        .HexDigit(CounterBCDDigit2),
        .Segments(LEDDisp2)
    );
    
    SegmentLedHexDecoder hexDecoder1 (
        .HexDigit(CounterBCDDigit1),
        .Segments(LEDDisp1)
    );
    
    SegmentLedHexDecoder hexDecoder0 (
        .HexDigit(CounterBCDDigit0),
        .Segments(LEDDisp0)
    );
    
    always @(posedge Clk or posedge Reset or posedge Stop or posedge Up or posedge Down)
    begin
        if(Stop)
            begin
                StopMode <= 1;
            end
        else if(Up)
            begin
                UpDownMode <= 1;
                ModeOutput[0] <= 0;
                ModeOutput[1] <= 1;
            end
        else if(Down)
            begin
                UpDownMode <= 0;
                ModeOutput[0] <= 1;
                ModeOutput[1] <= 0;
            end
    end
    
endmodule

`endif