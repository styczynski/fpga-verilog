`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_MINI_CALC_2_V
`define LIB_STYCZYNSKI_MINI_CALC_2_V

`include "../UpDownCounter/UpDownCounter.v"
`include "../Pow2/Pow2_32.v"
`include "../Bin2BCDConverter/Bin2BCDConverter_4.v"
`include "../SegmentLedHexDecoder/SegmentLedHexDecoder.v"
`include "../AdjClockDivider/AdjClockDivider.v"
`include "../Uart/UartRx.v"
`include "../Uart/UartTx.v"
`include "../Uart/UART.v"

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * MiniCalc2
 * 
 *
 * MIT License
 */
module MiniCalc2
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
    output wire [0:6] LEDDisp0,
	 input wire UartRxWire,
	 output wire UartTxWire
);

    wire ClkSrc;
    BUFGMUX clkSrc(.I0(Clk), .I1(Clk2), .S(ClkSel), .O(ClkSrc));
    //assign ClkSrc = Clk;

    wire [0:15] CounterOutput;
	 reg [15:0] CounterValue;
    
    wire [3:0] CounterBCDDigit3;
    wire [3:0] CounterBCDDigit2;
    wire [3:0] CounterBCDDigit1;
    wire [3:0] CounterBCDDigit0;

    reg [7:0] UartOutputData;
    reg UartOutputEnable;
    wire UartOutputIdle;
    
	 wire [7:0] UartInputData;
	 reg UartInputEnable;
	 wire UartInputReady;
	 
    UART #(
        .FREQ(100_000_000),
        .BAUD(115200)
    ) uartModule (
	     .clk(Clk),
		  .reset(1),
        .rx_i(UartRxWire),
		  .rx_data_o(UartInputData),
		  .rx_ack_i(UartInputEnable),
		  .rx_ready_o(UartInputReady),
        .tx_o(UartTxWire),
        .tx_data_i(UartOutputData),
        .tx_ready_i(UartOutputEnable),
        .tx_ack_o(UartOutputIdle)
    );
    
    /*wire UartReady;
	wire [7:0] UartData;

    reg UartTxDV;
    reg [7:0] UartTxData;
    wire UartTxBusy;
	 wire UartReceived;
	 
    UartTx uartTx (
       .clk(Clk),
		 .rst(0),
       .rx(UartRxWire),
		 .tx(UartTxWire),
		 .transmit(UartTxDV),
       .tx_byte(UartTxData), 
		 .rx_byte(UartData),
       .is_transmitting(UartTxBusy),
		 .received(UartReceived)
    );*/
	 
	 /*
	 input clk, // The master clock for this module
    input rst, // Synchronous reset.
    input rx, // Incoming serial line
    output tx, // Outgoing serial line
    input transmit, // Signal to transmit
    input [7:0] tx_byte, // Byte to transmit
    output received, // Indicated that a byte has been received.
    output [7:0] rx_byte, // Byte received
    output is_receiving, // Low when receive line is idle.
    output is_transmitting, // Low when transmit line is idle.
    output recv_error // Indicates error in receiving packet.
	 */
    
    /*UartRx #(
	    .CLKS_PER_BIT(87)
    ) uartRx
    (
	    .i_Clock(Clk),
       .i_Rx_Serial(UartRxWire),
       .o_Rx_DV(UartReady),
       .o_Rx_Byte(UartData)
     );*/
    
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
		.Input(CounterValue),
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
		UartOutputEnable <= 1;
        UartInputEnable <= 1;
        UartOutputData <= CounterOutput;
	
        if(UartInputReady)
            begin
                CounterValue <= UartInputData;
            end
                
        
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