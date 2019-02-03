`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_GRAPHIC_CARD_V
`define LIB_STYCZYNSKI_GRAPHIC_CARD_V

`include "../../components/Bin2BCDConverter/Bin2BCDConverter_4.v"
`include "../../components/SegmentLedHexDecoder/SegmentLedHexDecoder.v"
`include "../../components/Uart/UartRx.v"
`include "../../components/Uart/UartTx.v"
`include "../../components/LUA/LUA.v"

`include "vga800x600.v"

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * GraphicCard
 * 
 *
 * MIT License
 */
module GraphicCard #(
     parameter INPUT_BIT_WIDTH = 32,
     parameter UART_BUFFER_ADDR_BIT_WIDTH = 3,
     parameter STATE_BIT_WIDTH = 8,
     parameter STATE_IDLE = 1,
     parameter STATE_EXECUTE = 2,
     parameter STATE_WRITE = 3,
     parameter STATE_UART_RESET = 4,
     parameter STATE_UART_OUTPUT = 5,
     parameter STATE_STREAM = 6,
     parameter STATE_STREAM_UART_RESET = 7,
     parameter STATE_STREAM_UART_OUTPUT = 8,
     parameter STATE_EXECUTE_CLEAR = 9,
     parameter STATE_EXECUTE_REGMUL = 10,
     parameter STATE_EXECUTE_FILL = 11,
     parameter STATE_WAIT_UART_OUTPUT = 12,
     parameter STATE_EXECUTE_REGMUL_INIT = 13,
     parameter STATE_EXECUTE_REGMUL_WAIT = 14,
     parameter STATE_EXECUTE_FILL_POST = 15,
     parameter STATE_EXECUTE_COPY = 16,
     parameter STATE_EXECUTE_COPY_READ = 17,
     parameter STATE_EXECUTE_COPY_WRITE = 18,
     parameter STATE_EXECUTE_COPY_WAIT = 19,
     parameter STATE_READ = 20,
     parameter INSTRUCTION_ECHO = 4'b0001,
     parameter INSTRUCTION_PUT = 4'b0010,
     parameter INSTRUCTION_STREAM = 4'b0011,
     parameter INSTRUCTION_CLEAR = 4'b0100,
     parameter INSTRUCTION_STORE = 4'b0101,
     parameter INSTRUCTION_FILL = 4'b0110,
     parameter INSTRUCTION_COPY = 4'b0111,
     parameter INSTRUCTION_GET = 4'b1000,
     parameter UART_CLK_TIMEOUT = 12_000_000, //25_000_000 najlepsze inne testowane: 8_000_000, 12_000_000
     parameter UART_BAUD_RATE = 230400, //230400 > 57600 najlepsze testowane także: 500000, 230400
     parameter UART_OK_CODE = 42
)
(
    input wire Clk,
    output reg [0:7] LED,
    output wire [0:6] LEDDisp3,
    output wire [0:6] LEDDisp2,
    output wire [0:6] LEDDisp1,
    output wire [0:6] LEDDisp0,
    input wire [7:0] Switch,
    input wire Rst,
    output wire VgaHSync,
    output wire VgaVSync,
    output wire VgaColorR,
    output wire VgaColorG,
    output wire VgaColorB,
    input wire UartRxWire,
    output wire UartTxWire
);


    reg [24:0] InstructionInput;
    
    reg [16:0] RegisterA;
    reg [16:0] RegisterB;
    reg [16:0] RegisterC;
    reg [16:0] RegisterD;
    reg [16:0] RegisterE;
    reg [16:0] RegisterF;
    
    reg CopyForwardMode;
    
    reg [3:0] PColor;
    
    reg [16:0] PX1;
    reg [16:0] PY1;
    wire [31:0] EA1;
    
    reg [16:0] PX2;
    reg [16:0] PY2;
    wire [31:0] EA2;
    
    reg [16:0] CX1;
    reg [16:0] CY1;
    
    reg [16:0] CX2;
    reg [16:0] CY2;
    
    reg [16:0] CX3;
    reg [16:0] CY3;
    
    reg [16:0] CX4;
    reg [16:0] CY4;
    
    
    /*wire [31:0] RegisterAB;
    wire [31:0] RegisterCD;
    
    reg [31:0] RegisterABCopy;
    reg [31:0] RegisterCDCopy;*/

    reg [0:STATE_BIT_WIDTH-1] State = STATE_IDLE;
    reg [0:STATE_BIT_WIDTH-1] FutureState = STATE_IDLE;

    reg [7:0] UartInputBuffer [0:(1<<UART_BUFFER_ADDR_BIT_WIDTH)-1];
    reg [0:UART_BUFFER_ADDR_BIT_WIDTH-1] UartInputBufferPointer;
    
    reg [0:32] UartResetCounter = 0;
    reg [7:0] StreamResetCounter;
    
    wire [7:0] UartInputData;
    reg UartInputEnable;
    wire UartInputReady;
    wire UartInputError;
    reg UartNotResetInput;
    
    UartRx #(
        .CLOCK_FREQUENCY(100_000_000),
        .BAUD_RATE(UART_BAUD_RATE)
    ) uartModule (
        .Clk(Clk),
        .Reset(UartNotResetInput),
        .RxWire(UartRxWire),
        .RxDataOutput(UartInputData),
        .RxEnable(UartInputEnable),
        .RxReady(UartInputReady),
        .RxError(UartInputError)
    );
    
    reg [7:0] UartOutputData;
    reg UartOutputEnable;
    wire UartOutputReady;
    reg UartNotResetOutput;
    
    UartTx #(
        .CLOCK_FREQUENCY(100_000_000),
        .BAUD_RATE(UART_BAUD_RATE)
    ) uartModuleOut (
        .Clk(Clk),
        .Reset(UartNotResetOutput),
        .TxWire(UartTxWire),
        .TxDataInput(UartOutputData),
        .TxReady(UartOutputReady),
        .TxEnable(UartOutputEnable)
    );
    
    wire C1Ready;
    wire C2Ready;
    reg C1Start;
    reg C2Start;
    
    LUA #(
        .DATA_WIDTH(16),
        .BLOCK_SIZE(400)
    ) multModuleAB (
        .InputX(PX1),
        .InputY(PY1),
        .Address(EA1),
        .Start(C1Start),
        .Clk(Clk),
        .Ready(C1Ready)
    );
    
    LUA #(
        .DATA_WIDTH(16),
        .BLOCK_SIZE(400)
    ) multModuleCD (
        .InputX(PX2),
        .InputY(PY2),
        .Address(EA2),
        .Start(C2Start),
        .Clk(Clk),
        .Ready(C2Ready)
    );
    
    // generate a 40 MHz pixel strobe
    reg [15:0] Cnt;
    reg PixelStrobe;
    always @(posedge Clk)
        {PixelStrobe, Cnt} <= Cnt + 16'h6666;  // divide by 2.5: (2^16)/2.5 = 0x6666
        
    reg FrameBufferWrite;
    reg [16:0] FrameBufferAddr;
    reg [2:0] FrameBufferInput;
    wire [2:0] FrameBufferOutput;
        
    vga800x600 display (
        .i_clk(Clk),
        .FrameBufferWrite(FrameBufferWrite),
        .FrameBufferAddr(FrameBufferAddr),
        .FrameBufferInput(FrameBufferInput),
        .FrameBufferOutput(FrameBufferOutput),
        .VgaColorR(VgaColorR),
        .VgaColorG(VgaColorG),
        .VgaColorB(VgaColorB),
        .i_pix_stb(PixelStrobe),
        .i_rst(Rst),
        .o_hs(VgaHSync), 
        .o_vs(VgaVSync)
    );
     
    reg [15:0] CounterValue;
    
    wire [3:0] CounterBCDDigit3;
    wire [3:0] CounterBCDDigit2;
    wire [3:0] CounterBCDDigit1;
    wire [3:0] CounterBCDDigit0;
     
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
        .Undefined(0)
    );
    
    SegmentLedHexDecoder hexDecoder2 (
        .HexDigit(CounterBCDDigit2),
        .Segments(LEDDisp2),
        .Undefined(0)
    );
    
    SegmentLedHexDecoder hexDecoder1 (
        .HexDigit(CounterBCDDigit1),
        .Segments(LEDDisp1),
        .Undefined(0)
    );
    
    SegmentLedHexDecoder hexDecoder0 (
        .HexDigit(CounterBCDDigit0),
        .Segments(LEDDisp0),
        .Undefined(0)
    ); 
    
    always @(posedge Clk)
    begin
        UartInputEnable <= 1;
        UartNotResetInput <= 1;
        UartOutputEnable <= 0;
        UartNotResetOutput <= 1;
        FrameBufferWrite <= 0;
        //LED <= State;
        
        //CounterValue <= UartInputBuffer[0];
        if(State == STATE_READ)
            begin
                State <= STATE_UART_OUTPUT;
                UartOutputData <= FrameBufferOutput;
            end
        else if(State == STATE_WAIT_UART_OUTPUT)
            begin
                State <= STATE_UART_OUTPUT;
                FrameBufferWrite <= 0;
                FrameBufferInput <= 0;
            end
        else if(State == STATE_EXECUTE_COPY)
            begin
                State <= STATE_EXECUTE_REGMUL_INIT;
                FutureState <= STATE_EXECUTE_COPY_READ;
                
                if(CopyForwardMode)
                    begin
                        PX1 <= PX1 + 1;
                        if(PX1 >= CX2)
                            begin
                                PY1 <= PY1 + 1;
                                PX1 <= CX1;
                            end
                            
                        PX2 <= PX2 + 1;
                        if(PX2 >= CX4)
                            begin
                                PY2 <= PY2 + 1;
                                PX2 <= CX3;
                            end
                        
                        if(PX1 >= CX2 && PY1 >= CY2)
                            begin
                                State <= STATE_WAIT_UART_OUTPUT;
                                UartOutputData <= UART_OK_CODE;
                            end
                        if(PX2 >= CX4 && PY2 >= CY4)
                            begin
                                State <= STATE_WAIT_UART_OUTPUT;
                                UartOutputData <= UART_OK_CODE;
                            end
                   end
               else
                   begin
                   
                        if(PX1 <= CX1 && PY1 <= CY1)
                            begin
                                State <= STATE_WAIT_UART_OUTPUT;
                                UartOutputData <= UART_OK_CODE;
                            end
                        if(PX2 <= CX3 && PY2 <= CY3)
                            begin
                                State <= STATE_WAIT_UART_OUTPUT;
                                UartOutputData <= UART_OK_CODE;
                            end
                   
                        if(PX1 == CX1)
                            begin
                                PY1 <= PY1 - 1;
                                PX1 <= CX2;
                            end
                        else
                            begin
                                PX1 <= PX1 - 1;
                            end
                            
                        if(PX2 == CX3)
                            begin
                                PY2 <= PY2 - 1;
                                PX2 <= CX4;
                            end
                        else
                            begin
                                PX2 <= PX2 - 1;
                            end
                        
                   end
            end
        else if(State == STATE_EXECUTE_COPY_READ)
            begin
                State <= STATE_EXECUTE_COPY_WAIT;
                FrameBufferWrite <= 0;
                FrameBufferAddr <= EA1[16:0];
                FrameBufferInput <= 0;
            end
        else if(State == STATE_EXECUTE_COPY_WAIT)
            begin
                State <= STATE_EXECUTE_COPY_WRITE;
            end
        else if(State == STATE_EXECUTE_COPY_WRITE)
            begin
                State <= STATE_WRITE;
                FutureState <= STATE_EXECUTE_COPY;
                FrameBufferWrite <= 1;
                FrameBufferAddr <= EA2[16:0];
                FrameBufferInput <= FrameBufferOutput;
            end
        else if(State == STATE_EXECUTE_FILL_POST)
            begin
                State <= STATE_WRITE;
                FutureState <= STATE_EXECUTE_FILL;
                FrameBufferWrite <= 1;
                FrameBufferAddr <= EA1[16:0];
                FrameBufferInput <= PColor;
            end
        else if(State == STATE_EXECUTE_FILL)
            begin
                State <= STATE_EXECUTE_REGMUL_INIT;
                FutureState <= STATE_EXECUTE_FILL_POST;
                
                PX1 <= PX1 + 1;
                if(PX1 >= CX2)
                    begin
                        PY1 <= PY1 + 1;
                        PX1 <= CX1;
                    end
                
                if(PX1 >= CX2 && PY1 >= CY2)
                    begin
                        State <= STATE_WAIT_UART_OUTPUT;
                        UartOutputData <= UART_OK_CODE;
                    end
                   
                
                /*FrameBufferWrite <= 1;
                CounterValue <= RegisterABCopy;
                FrameBufferAddr <= RegisterABCopy;
                RegisterABCopy <= RegisterABCopy + 1;
                FrameBufferInput <= 1;
                if(RegisterABCopy >= RegisterCDCopy)
                    begin
                        State <= STATE_WAIT_UART_OUTPUT;
                    end
                */
                
                /*
                    State <= STATE_EXECUTE_REGMUL_INIT;
                    FutureState <= STATE_EXECUTE_FILL;
                */
            end
        else if(State == STATE_EXECUTE_REGMUL_WAIT)
            begin
                if(!C1Ready && !C2Ready)
                    begin
                        C1Start <= 0;
                        C2Start <= 0;
                        State <= STATE_EXECUTE_REGMUL;
                    end
                else
                    begin
                        C1Start <= 1;
                        C2Start <= 1;
                    end
            end
        else if(State == STATE_EXECUTE_REGMUL_INIT)
            begin
                if(C1Ready && C2Ready)
                    begin
                        C1Start <= 1;
                        C2Start <= 1;
                        State <= STATE_EXECUTE_REGMUL_WAIT;
                    end
                else
                    begin
                        C1Start <= 0;
                        C2Start <= 0;
                    end
            end
        else if(State == STATE_EXECUTE_REGMUL)
            begin
                if(C1Ready)
                    begin
                        C1Start <= 0;
                    end
                if(C2Ready)
                    begin
                        C2Start <= 0;
                    end
                if(C1Ready && C2Ready)
                    begin
                        State <= FutureState;
                    end
            end
        else if(State == STATE_EXECUTE_CLEAR)
            begin
                FrameBufferWrite <= 1;
                FrameBufferInput <= InstructionInput[19:17];
                FrameBufferAddr <= FrameBufferAddr+1;
                if(FrameBufferAddr >= 120_000)
                    begin
                        State <= STATE_UART_OUTPUT;
                        UartOutputData <= UART_OK_CODE;
                        FrameBufferAddr <= 0;
                        FrameBufferWrite <= 0;
                    end
                else
                    begin
                        State <= STATE_EXECUTE_CLEAR;
                    end
            end
        else if(State == STATE_STREAM)
            begin
                if(UartInputReady)
                    begin
                        FrameBufferWrite <= 1;
                        FrameBufferInput <= UartInputData[7:5];
                        State <= STATE_STREAM_UART_OUTPUT;
                        UartResetCounter <= 0;
                    end
                else
                    begin
                        FrameBufferWrite <= 0;
                        if(!UartInputError && UartResetCounter < UART_CLK_TIMEOUT)
                            begin
                                UartResetCounter <= UartResetCounter + 1;
                            end
                        else
                            begin
                                UartResetCounter <= 0;
                                State <= STATE_STREAM_UART_RESET;
                                UartInputBufferPointer <= 0;
                                UartNotResetInput <= 0;
                            end
                    end
            end
        else if(State == STATE_STREAM_UART_OUTPUT)
            begin
                //State <= STATE_STREAM;
                //UartResetCounter <= 0;
                //FrameBufferAddr <= FrameBufferAddr + 1;
                if(UartOutputReady)
                    begin
                        UartOutputData <= UART_OK_CODE;
                        UartOutputEnable <= 1;
                        UartResetCounter <= 0;
                        FrameBufferAddr <= FrameBufferAddr + 1;
                        if(FrameBufferAddr >= 120_000)
                            begin
                                State <= STATE_UART_OUTPUT;
                                UartOutputData <= UART_OK_CODE;
                                UartInputBufferPointer <= 0;
                                FrameBufferWrite <= 0;
                            end
                        else
                            begin
                                State <= STATE_STREAM;
                            end
                        StreamResetCounter <= 0;
                    end
                else
                    begin
                        UartOutputEnable <= 0;
                        if(UartResetCounter < UART_CLK_TIMEOUT)
                            begin
                                UartResetCounter <= UartResetCounter + 1;
                            end
                        else
                            begin
                                UartResetCounter <= 0;
                                State <= STATE_STREAM_UART_RESET;
                                UartNotResetOutput <= 0;
                            end
                    end
            end
         else if(State == STATE_STREAM_UART_RESET)
            begin
                State <= STATE_STREAM;
                UartInputBufferPointer <= 0;
                UartNotResetInput <= 0;
                UartNotResetOutput <= 0;
                UartResetCounter <= 0;
                StreamResetCounter <= StreamResetCounter+1;
                /*if(StreamResetCounter > UART)
                    begin
                        State <= STATE_IDLE;
                    end*/
            end
        else if(State == STATE_UART_RESET)
            begin
                State <= STATE_IDLE;
                UartInputBufferPointer <= 0;
                UartNotResetInput <= 0;
                UartNotResetOutput <= 0;
                UartResetCounter <= 0;
            end
        else if(State == STATE_WRITE) 
            begin
                State <= FutureState;
                FrameBufferWrite <= 0;
                FrameBufferInput <= 0;
            end
        else if(State == STATE_UART_OUTPUT)
            begin
                if(UartOutputReady)
                    begin
                        UartOutputEnable <= 1;
                        State <= STATE_IDLE;
                    end
                else
                    begin
                        UartOutputEnable <= 1;
                        if(UartResetCounter < UART_CLK_TIMEOUT)
                            begin
                                UartResetCounter <= UartResetCounter + 1;
                            end
                        else
                            begin
                                UartResetCounter <= 0;
                                State <= STATE_IDLE;
                                UartNotResetOutput <= 0;
                            end
                    end
            end
         else if(State == STATE_EXECUTE)
            begin
                State <= STATE_UART_OUTPUT;
                UartOutputData <= UART_OK_CODE;
                casez(InstructionInput[23:20])
                    INSTRUCTION_ECHO:
                        begin
                            State <= STATE_UART_OUTPUT;
                            CounterValue <= InstructionInput[19:0];
                        end
                    INSTRUCTION_GET:
                        begin
                            State <= STATE_READ;
                            FrameBufferWrite <= 0;
                            FrameBufferAddr <= InstructionInput[16:0];
                            FrameBufferInput <= 0;
                        end
                    INSTRUCTION_PUT:
                        begin
                            State <= STATE_WRITE;
                            FutureState <= STATE_UART_OUTPUT;
                            FrameBufferWrite <= 1;
                            //CounterValue <= InstructionInput[16:0];
                            FrameBufferAddr <= InstructionInput[16:0];
                            FrameBufferInput <= InstructionInput[19:17];
                            PColor <= InstructionInput[19:17];
                        end
                    INSTRUCTION_STREAM:
                        begin
                            State <= STATE_STREAM_UART_OUTPUT;
                            StreamResetCounter <= 0;
                            FrameBufferAddr <= 0;
                        end
                    INSTRUCTION_CLEAR:
                        begin
                            State <= STATE_EXECUTE_CLEAR;
                            FrameBufferAddr <= 0;
                        end
                    INSTRUCTION_STORE:
                        begin
                            State <= STATE_WAIT_UART_OUTPUT;
                            UartOutputData <= UART_OK_CODE;
                            //CounterValue <= InstructionInput[16:0];
                            if(InstructionInput[19:17] == 3'b000)
                                begin
                                    RegisterA <= InstructionInput[16:0];
                                    CounterValue <= InstructionInput[16:0];
                                    LED <= 1;
                                end
                            else if(InstructionInput[19:17] == 3'b001)
                                begin
                                    RegisterB <= InstructionInput[16:0];
                                    CounterValue <= InstructionInput[16:0];
                                    LED <= 2;
                                end
                            else if(InstructionInput[19:17] == 3'b010)
                                begin
                                    RegisterC <= InstructionInput[16:0];
                                end
                            else if(InstructionInput[19:17] == 3'b011)
                                begin
                                    RegisterD <= InstructionInput[16:0];
                                end
                            else if(InstructionInput[19:17] == 3'b100)
                                begin
                                    RegisterE <= InstructionInput[16:0];
                                end
                            else if(InstructionInput[19:17] == 3'b101)
                                begin
                                    RegisterF <= InstructionInput[16:0];
                                end
                        end
                    INSTRUCTION_COPY:
                        begin
                            State <= STATE_EXECUTE_COPY;
                            CX1 <= RegisterA;
                            CY1 <= RegisterB;
                            CX2 <= RegisterA + RegisterE;
                            CY2 <= RegisterB + RegisterF;
                            CX3 <= RegisterC;
                            CY3 <= RegisterD;
                            CX4 <= RegisterC + RegisterE;
                            CY4 <= RegisterC + RegisterF;
                            
                            if(RegisterD >= RegisterB)
                                begin
                                    CopyForwardMode <= 0;
                                    PX1 <= RegisterA + RegisterE; 
                                    PY1 <= RegisterB + RegisterF;
                                    PX2 <= RegisterC + RegisterE;
                                    PY2 <= RegisterD + RegisterF;
                                end
                            else
                                begin
                                    CopyForwardMode <= 1;
                                    PX1 <= RegisterA; 
                                    PY1 <= RegisterB;
                                    PX2 <= RegisterC;
                                    PY2 <= RegisterD;
                                end
                        end
                    /*INSTRUCTION_BLIT:  //TODO: Add instr
                        begin
                            State <= STATE_EXECUTE_BLIT;
                            CX1 <= RegisterA;
                            CY1 <= RegisterB;
                            CX2 <= RegisterC;
                            CY2 <= RegisterD;
                            CW <= RegisterE; 
                            CH <= RegisterF;
                        end*/
                    INSTRUCTION_FILL:
                        begin
                            State <= STATE_EXECUTE_FILL;
                            CX1 <= RegisterA;
                            CY1 <= RegisterB;
                            CX2 <= RegisterC;
                            CY2 <= RegisterD;
                            
                            PX1 <= RegisterA;
                            PY1 <= RegisterB;
                            
                            PColor <= InstructionInput[19:17];
                            
                            //State <= STATE_EXECUTE_REGMUL_INIT;
                            //FutureState <= STATE_EXECUTE_FILL;
                        end
                    default:
                        begin
                            State <= STATE_IDLE;
                        end
                endcase
            end
        else if(UartInputReady && UartInputBufferPointer < 3 && State == STATE_IDLE)
            begin
                State <= STATE_IDLE;
                UartInputBuffer[UartInputBufferPointer] <= UartInputData;
                UartInputBufferPointer <= UartInputBufferPointer + 1;
            end
        else if(UartInputBufferPointer >= 3 && State == STATE_IDLE)
            begin
                // We have collected UART data then we should send it to core for execution
                State <= STATE_EXECUTE;
                InstructionInput <= { UartInputBuffer[0], UartInputBuffer[1], UartInputBuffer[2] };
                UartInputBufferPointer <= 0;
            end
        else
            begin
                if(!UartInputError && UartResetCounter < UART_CLK_TIMEOUT)
                    begin
                        UartResetCounter <= UartResetCounter + 1;
                    end
                else
                    begin
                        UartResetCounter <= 0;
                        State <= STATE_IDLE;
                        UartInputBufferPointer <= 0;
                        UartNotResetInput <= 0;
                    end
            end
    end
    
endmodule


`endif