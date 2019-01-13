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
`include "./MiniCalc2Core.v"

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
#(
    parameter UART_BUFFER_ADDR_BIT_WIDTH = 3,
    parameter STATE_BIT_WIDTH = 4,
    parameter STATE_IDLE = 4'b0000,
    parameter STATE_UART_COLLECT = 4'b0001,
    parameter STATE_EXECUTE = 4'b0011,
    parameter STATE_EXECUTE_WAIT = 4'b0100,
    parameter UART_COMMAND_TERMINATOR = 8'b00000000,
    parameter INPUT_BIT_WIDTH = 8
)
(
    input Clk,
	 input ClkSel,
	 input Clk2,
    input Reset,
    input Stop,
    input Up,
    input Down,
    input [4:0] Speed,
    output wire ModeOutput0,
	 output wire ModeOutput1,
	 output reg ClkOutput,
	 output wire ModeOutput2,
    output wire [0:6] LEDDisp3,
    output wire [0:6] LEDDisp2,
    output wire [0:6] LEDDisp1,
    output wire [0:6] LEDDisp0,
	 input wire UartRxWire,
	 output wire UartTxWire
);

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
	 
	 reg [0:7] CoreInstruction;
     reg [0:INPUT_BIT_WIDTH-1] CoreInput;
     wire [0:INPUT_BIT_WIDTH-1] CoreOutput;
     wire [0:INPUT_BIT_WIDTH-1] CoreStackTop;
	 reg CoreExecute;
     wire CoreReady;
     reg CoreNext;
     wire CoreHasNext;
     wire CoreStackEmpty;
	 
    reg [0:32] UartTimeoutCounter;
     
    UART #(
        .FREQ(100_000_000),
        .BAUD(57600)
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
    
	MiniCalc2Core #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH)
    ) core (
		.Clk(Clk),
		.Instruction(CoreInstruction),
        .InputA(CoreInput),
        .OutputA(CoreOutput),
		.Execute(CoreExecute),
        .Ready(CoreReady),
        .HasNext(CoreHasNext),
        .Next(CoreNext),
        .StackTop(CoreStackTop),
        .StackEmpty(CoreStackEmpty)
	);
    
    reg [7:0] UartInputBuffer [0:(1<<UART_BUFFER_ADDR_BIT_WIDTH)-1];
    reg [0:UART_BUFFER_ADDR_BIT_WIDTH-1] UartInputBufferPointer;
    
    reg [0:STATE_BIT_WIDTH-1] State = STATE_IDLE;
	 
    assign { ModeOutput0, ModeOutput1 } = State;
    assign ModeOutput2 = ( UartInputReady );
     
    always @(posedge Clk)
    begin
        CounterValue <= CoreStackTop;
        if(State == STATE_EXECUTE_WAIT)
            begin
                CoreNext <= 0;
                CoreExecute <= 1;
                State <= STATE_EXECUTE;
            end
        else if(State == STATE_EXECUTE)
            begin
                if(CoreHasNext)
                    begin
                        if(UartOutputIdle)
                            begin
                                State <= STATE_EXECUTE_WAIT;
                                CoreExecute <= 1;
                                UartOutputData <= CoreOutput;
                                CoreNext <= 1;
                                UartOutputEnable <= 1;
                                UartInputEnable <= 0;
                            end
                         else
                            begin
                                CoreExecute <= 1;
                                CoreNext <= 0;
                                UartOutputEnable <= 1;
                                UartInputEnable <= 0;
                            end
                    end
                else if(CoreReady)
                    begin
                        State <= STATE_IDLE;
                        UartInputEnable <= 1;
                        UartOutputEnable <= 0;
                        CoreExecute <= 0;
                        CoreNext <= 0;
                    end
                else
                    begin
                        UartOutputEnable <= 0;
                        UartInputEnable <= 0;
                        CoreExecute <= 1;
                        CoreNext <= 0;
                    end
            end
        else
            begin
                UartInputEnable <= 1;
                UartOutputEnable <= 0;
                if(UartInputReady && UartInputData != UART_COMMAND_TERMINATOR && (State == STATE_IDLE || State == STATE_UART_COLLECT))
                    begin
                        State <= STATE_UART_COLLECT;
                        UartInputBuffer[UartInputBufferPointer] <= UartInputData;
                        UartInputBufferPointer <= UartInputBufferPointer + 1;
                        CoreNext <= 0;
                        CoreExecute <= 0;
                    end
                else if(UartInputReady && UartInputData == UART_COMMAND_TERMINATOR && State == STATE_UART_COLLECT)
                    begin
                        // We have collected UART data then we should send it to core for execution
                        CoreInstruction <= UartInputBuffer[0];
                        CoreInput <= UartInputBuffer[1];
                        CoreExecute <= 1;
                        CoreNext <= 0;
                        State <= STATE_EXECUTE;
                        UartInputBufferPointer <= 0;
                    end
                else
                    begin
                        CoreExecute <= 0;
                    end
            end
    end
	 
endmodule


`endif