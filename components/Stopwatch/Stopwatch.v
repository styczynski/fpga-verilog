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
	 input ClkSel,
	 input Clk2,
    input Reset,
    input Stop,
    input Up,
    input Down,
    input [4:0] Speed,
    output reg ModeOutput0,
	 output reg ModeOutput1,
	 output reg ClkOutput,
	 output wire ModeOutput2,
    output wire [0:6] LEDDisp3,
    output wire [0:6] LEDDisp2,
    output wire [0:6] LEDDisp1,
    output wire [0:6] LEDDisp0
);

    wire ClkSrc;
    BUFGMUX clkSrc(.I0(Clk), .I1(Clk2), .S(ClkSel), .O(ClkSrc));
    //assign ClkSrc = Clk;

    wire [0:15] CounterOutput;
    
    wire [3:0] CounterBCDDigit3;
    wire [3:0] CounterBCDDigit2;
    wire [3:0] CounterBCDDigit1;
    wire [3:0] CounterBCDDigit0;

    
    reg UpDownMode;
    reg StopMode;
    
    wire CounterTriggerClk;
    wire [31:0] FrequencyDividerFactor;
    
	 assign FrequencyDividerFactor = 31'b1 << Speed;
	 
    AdjClockDivider #(
        .INPUT_BIT_WIDTH(32)
    ) clockDivider (
        .Clk(Clk),
		  .ClkEnable(ClkSrc),
        .FrequencyDividerFactor(FrequencyDividerFactor),
        .ClkEnableOutput(CounterTriggerClk)
    );
    
    UpDownCounter #(
        .INPUT_BIT_WIDTH(16),
        .MAX_VALUE(9999)
    ) upDownCounter (
	     .Stop(StopMode),
		  .Clk(Clk),
		  .ClkEnable(CounterTriggerClk),
        .Reset(Reset),
        .UpDownMode(UpDownMode),
        .Output(CounterOutput),
        .LimitReachedFlag(ModeOutput2)
	);
    
    Bin2BCDConverter_4 #(
        .INPUT_BIT_WIDTH(16)
    ) bin2BCDConverter (
		.Input(CounterOutput),
        .Digit3(CounterBCDDigit3),
        .Digit2(CounterBCDDigit2),
        .Digit1(CounterBCDDigit1),
        .Digit0(CounterBCDDigit0)
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
    
    always @(posedge Clk)
    begin
	     ClkOutput <= CounterTriggerClk;
        if(Stop)
            begin
                StopMode <= 1;
					 ModeOutput0 <= 0;
					 ModeOutput1 <= 0;
            end
        else if(Up)
            begin
				    StopMode <= 0;
					 UpDownMode <= 1;
					 ModeOutput0 <= 1;
					 ModeOutput1 <= 0;
            end
        else if(Down)
            begin
				    StopMode <= 0;
                UpDownMode <= 0;
					 ModeOutput0 <= 0;
					 ModeOutput1 <= 1;
            end
    end
    
endmodule


`endif