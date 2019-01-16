`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_MINI_CALC_2_V
`define LIB_STYCZYNSKI_MINI_CALC_2_V

`include "../../components/UpDownCounter/UpDownCounter.v"
`include "../../components/Bin2BCDConverter/Bin2BCDConverter_4.v"
`include "../../components/SegmentLedHexDecoder/SegmentLedHexDecoder.v"
`include "../../components/Uart/UART.v"
`include "MiniCalc2Core.v"

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
    parameter STACK_ADDR_SIZE = 9,
    parameter STATE_BIT_WIDTH = 4,
    parameter STATE_IDLE = 4'b0000,
    parameter STATE_EXECUTE = 4'b0001,
    parameter STATE_EXECUTING = 4'b0011,
    parameter STATE_EXECUTE_END = 4'b0010,
    parameter INPUT_BIT_WIDTH = 32
)
(
    input Clk,
    output reg [0:7] LED,
    output wire [0:6] LEDDisp3,
    output wire [0:6] LEDDisp2,
    output wire [0:6] LEDDisp1,
    output wire [0:6] LEDDisp0,
    input wire [7:0] Switch,
    input wire BtnPushLow,
    input wire BtnPushHi,
    input wire BtnExecute,
    input wire BtnOutputHi,
    input wire UartRxWire,
    output wire UartTxWire,
    output wire Ready
);

    assign Ready = ( State == STATE_IDLE );

    reg [15:0] CounterValue;
    reg ExecuteUart;
    
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
    wire [0:INPUT_BIT_WIDTH-1] CoreStackFirst;
    wire [0:INPUT_BIT_WIDTH-1] CoreStackSecond;
    wire [0:STACK_ADDR_SIZE-1] CoreStackSize;
    wire CoreError;
    reg CoreExecute;
    wire CoreReady;
    wire CoreStackEmpty;
     
    reg UartNotResetInput;
    reg UartNotResetOutput;
     
    UART #(
        .FREQ(100_000_000),
        .BAUD(460800)
    ) uartModuleIn (
        .clk(Clk),
        .reset(UartNotResetInput),
        .rx_i(UartRxWire),
        .rx_data_o(UartInputData),
        .rx_ack_i(UartInputEnable),
        .rx_ready_o(UartInputReady)
    );
    
    UART #(
        .FREQ(100_000_000),
        .BAUD(460800)
    ) uartModuleOut (
        .clk(Clk),
        .reset(UartNotResetOutput),
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
        .Segments(LEDDisp3),
        .Undefined(CoreStackEmpty)
    );
    
    SegmentLedHexDecoder hexDecoder2 (
        .HexDigit(CounterBCDDigit2),
        .Segments(LEDDisp2),
        .Undefined(CoreStackEmpty)
    );
    
    SegmentLedHexDecoder hexDecoder1 (
        .HexDigit(CounterBCDDigit1),
        .Segments(LEDDisp1),
        .Undefined(CoreStackEmpty)
    );
    
    SegmentLedHexDecoder hexDecoder0 (
        .HexDigit(CounterBCDDigit0),
        .Segments(LEDDisp0),
        .Undefined(CoreStackEmpty)
    );
    
    MiniCalc2Core #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH),
        .STACK_ADDR_SIZE(STACK_ADDR_SIZE)
    ) core (
        .Clk(Clk),
        .Instruction(CoreInstruction),
        .InputA(CoreInput),
        .OutputA(CoreOutput),
        .Execute(CoreExecute),
        .Ready(CoreReady),
        .StackFirst(CoreStackFirst),
        .StackSecond(CoreStackSecond),
        .StackEmpty(CoreStackEmpty),
        .StackSize(CoreStackSize),
        .OperationalError(CoreError)
    );
    
    reg [7:0] UartInputBuffer [0:(1<<UART_BUFFER_ADDR_BIT_WIDTH)-1];
    reg [0:UART_BUFFER_ADDR_BIT_WIDTH-1] UartInputBufferPointer;
    
    reg [0:STATE_BIT_WIDTH-1] State = STATE_IDLE;
    reg [0:4] CoreOutputByteCounter;
    
    reg [0:32] UartResetCounter = 0;
     
    always @(posedge Clk)
    begin
        LED[0:6] <= CoreStackSize[STACK_ADDR_SIZE-7:STACK_ADDR_SIZE-1];
        LED[7]   <= CoreError;
        UartNotResetInput <= 1;
        UartNotResetOutput <= 1;
        
        if(!BtnOutputHi)
            begin
                CounterValue <= CoreStackFirst[16:31];
            end
        else
            begin
                CounterValue <= CoreStackFirst[0:15];
            end
        
       if(State == STATE_EXECUTE_END)
            begin
                if(UartOutputIdle)
                    begin
                         if(CoreOutputByteCounter == 0)
                            begin
                                State <= STATE_EXECUTE_END;
                                UartOutputData <= CoreOutput[0:7];
                                UartOutputEnable <= 1;
                                UartInputEnable <= 0;
                                CoreOutputByteCounter <= 1;
                                CoreExecute <= 0;
                            end
                         else if(CoreOutputByteCounter == 1)
                            begin
                                State <= STATE_EXECUTE_END;
                                UartOutputData <= CoreOutput[8:15];
                                UartOutputEnable <= 1;
                                UartInputEnable <= 0;
                                CoreOutputByteCounter <= 2;
                                CoreExecute <= 0;
                            end
                         else if(CoreOutputByteCounter == 2)
                            begin
                                State <= STATE_EXECUTE_END;
                                UartOutputData <= CoreOutput[16:23];
                                UartOutputEnable <= 1;
                                UartInputEnable <= 0;
                                CoreOutputByteCounter <= 3;
                                CoreExecute <= 0;
                            end
                         else if(CoreOutputByteCounter == 3)
                            begin
                                State <= STATE_EXECUTE_END;
                                UartOutputData <= CoreOutput[24:31];
                                UartOutputEnable <= 1;
                                UartInputEnable <= 0;
                                CoreOutputByteCounter <= 4;
                                CoreExecute <= 0;
                            end
                         else
                            begin
                                State <= STATE_IDLE;
                                ExecuteUart <= 0;
                                UartOutputData <= 0;
                                UartOutputEnable <= 0;
                                UartInputEnable <= 1;
                                CoreOutputByteCounter <= 0;
                                CoreExecute <= 0;
                                UartNotResetOutput <= 1;
                            end
                    end
                else
                    begin
                         if(UartResetCounter < 25_000_000)
                            begin
                                UartResetCounter <= UartResetCounter + 1;
                                State <= STATE_EXECUTE_END;
                                UartOutputEnable <= 1;
                                UartInputEnable <= 0;
                                CoreExecute <= 0;
                            end
                         else
                            begin
                                UartNotResetOutput <= 1;
                                UartResetCounter <= 0;
                                State <= STATE_IDLE;
                                ExecuteUart <= 0;
                                UartInputBufferPointer <= 0;
                                CoreExecute <= 0;
                                UartOutputEnable <= 0;
                                UartInputEnable <= 1;
                                CoreOutputByteCounter <= 0;
                            end
                    end
            end
        else if(State == STATE_EXECUTE)
            begin
                State <= STATE_EXECUTING;
                CoreOutputByteCounter <= 0;
                CoreExecute <= 0;
            end
        else if(State == STATE_EXECUTING)
            begin
                if(CoreReady)
                    begin
                        if(ExecuteUart)
                            begin
                                State <= STATE_EXECUTE_END;
                                ExecuteUart <= 1;
                                CoreOutputByteCounter <= 0;
                                CoreExecute <= 0;
                                UartResetCounter <= 0;
                            end
                        else
                            begin
                                State <= STATE_IDLE;
                                ExecuteUart <= 0;
                                CoreOutputByteCounter <= 0;
                                CoreExecute <= 0;
                                UartResetCounter <= 0;
                            end
                    end
                else
                    begin
                        State <= STATE_EXECUTING;
                        CoreOutputByteCounter <= 0;
                        CoreExecute <= 0;
                    end
            end
        else
            begin
                UartInputEnable <= 1;
                UartOutputEnable <= 0;
                if(BtnPushLow && State == STATE_IDLE)
                    begin
                        CoreInstruction <= 8'b00000001;
                        CoreInput <= { 24'b000000000000000000000000, Switch[7:0] };
                        CoreExecute <= 1;
                        State <= STATE_EXECUTE;
                        ExecuteUart <= 0;
                        UartInputBufferPointer <= 0;
                        CoreOutputByteCounter <= 0;
                    end
                else if(BtnPushHi && State == STATE_IDLE)
                    begin
                        CoreInstruction <= 8'b00100001;
                        CoreInput <= { 24'b000000000000000000000000, Switch[7:0] };
                        CoreExecute <= 1;
                        State <= STATE_EXECUTE;
                        ExecuteUart <= 0;
                        UartInputBufferPointer <= 0;
                        CoreOutputByteCounter <= 0;
                    end
                else if(BtnExecute && BtnOutputHi && State == STATE_IDLE)
                    begin
                        // CLS
                        CoreInstruction <= 8'b10000000;
                        CoreInput <= 0;
                        CoreExecute <= 1;
                        State <= STATE_EXECUTE;
                        ExecuteUart <= 0;
                        UartInputBufferPointer <= 0;
                        CoreOutputByteCounter <= 0;
                    end
                else if(BtnExecute && State == STATE_IDLE)
                    begin
                        casez(Switch[2:0])
                            3'b000:
                                begin
                                    /* ADD */
                                    CoreInstruction <= 8'b00000100;
                                    CoreInput <= 0;
                                    CoreExecute <= 1;
                                    State <= STATE_EXECUTE;
                                    ExecuteUart <= 0;
                                    UartInputBufferPointer <= 0;
                                    CoreOutputByteCounter <= 0;
                                end
                            3'b001:
                                begin
                                    /* SUB */
                                    CoreInstruction <= 8'b00000101;
                                    CoreInput <= 0;
                                    CoreExecute <= 1;
                                    State <= STATE_EXECUTE;
                                    ExecuteUart <= 0;
                                    UartInputBufferPointer <= 0;
                                    CoreOutputByteCounter <= 0;
                                end
                            3'b010:
                                begin
                                    /* MUL */
                                    CoreInstruction <= 8'b00000110;
                                    CoreInput <= 0;
                                    CoreExecute <= 1;
                                    State <= STATE_EXECUTE;
                                    ExecuteUart <= 0;
                                    UartInputBufferPointer <= 0;
                                    CoreOutputByteCounter <= 0;
                                end
                            3'b011:
                                begin
                                    /* DIV */
                                    CoreInstruction <= 8'b00001000;
                                    CoreInput <= 0;
                                    CoreExecute <= 1;
                                    State <= STATE_EXECUTE;
                                    ExecuteUart <= 0;
                                    UartInputBufferPointer <= 0;
                                    CoreOutputByteCounter <= 0;
                                end
                            3'b100:
                                begin
                                    /* MOD */
                                    CoreInstruction <= 8'b00001010;
                                    CoreInput <= 0;
                                    CoreExecute <= 1;
                                    State <= STATE_EXECUTE;
                                    ExecuteUart <= 0;
                                    UartInputBufferPointer <= 0;
                                    CoreOutputByteCounter <= 0;
                                end
                            3'b101:
                                begin
                                    /* POP */
                                    CoreInstruction <= 8'b00000010;
                                    CoreInput <= 0;
                                    CoreExecute <= 1;
                                    State <= STATE_EXECUTE;
                                    ExecuteUart <= 0;
                                    UartInputBufferPointer <= 0;
                                    CoreOutputByteCounter <= 0;
                                end
                             3'b110:
                                begin
                                    /* COPY */
                                    CoreInstruction <= 8'b00000011;
                                    CoreInput <= 0;
                                    CoreExecute <= 1;
                                    State <= STATE_EXECUTE;
                                    ExecuteUart <= 0;
                                    UartInputBufferPointer <= 0;
                                    CoreOutputByteCounter <= 0;
                                end
                            3'b111:
                                begin
                                    /* SWAP */
                                    CoreInstruction <= 8'b00001001;
                                    CoreInput <= 0;
                                    CoreExecute <= 1;
                                    State <= STATE_EXECUTE;
                                    ExecuteUart <= 0;
                                    UartInputBufferPointer <= 0;
                                    CoreOutputByteCounter <= 0;
                                end
                            default:
                                begin
                                    State <= STATE_IDLE;
                                end
                        endcase
                    end
                else if(UartInputReady && UartInputBufferPointer < 5 && State == STATE_IDLE)
                    begin
                        State <= STATE_IDLE;
                        ExecuteUart <= 0;
                        UartInputBuffer[UartInputBufferPointer] <= UartInputData;
                        UartInputBufferPointer <= UartInputBufferPointer + 1;
                        CoreExecute <= 0;
                    end
                else if(UartInputBufferPointer >= 5 && State == STATE_IDLE)
                    begin
                        // We have collected UART data then we should send it to core for execution
                        CoreInstruction <= UartInputBuffer[0];
                        CoreInput <= { UartInputBuffer[1], UartInputBuffer[2], UartInputBuffer[3], UartInputBuffer[4] };
                        CoreExecute <= 1;
                        State <= STATE_EXECUTE;
                        ExecuteUart <= 1;
                        UartInputBufferPointer <= 0;
                        CoreOutputByteCounter <= 0;
                    end
                else
                    begin
                        if(UartResetCounter < 25_000_000)
                            begin
                                UartResetCounter <= UartResetCounter + 1;
                            end
                        else
                            begin
                                UartResetCounter <= 0;
                                State <= STATE_IDLE;
                                ExecuteUart <= 0;
                                UartInputBufferPointer <= 0;
                                CoreExecute <= 0;
                                UartNotResetInput <= 0;
                            end
                    end
            end
        
    end
     
endmodule


`endif