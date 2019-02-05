`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_SNAKE_V
`define LIB_STYCZYNSKI_SNAKE_V

`include "../../components/LUA/LUA.v"

`include "vga800x600.v"

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Snake graphic card
 * 
 *
 * MIT License
 */
module GraphicCard #(
     parameter INPUT_BIT_WIDTH = 32,
     parameter STATE_BIT_WIDTH = 8,
     parameter STATE_IDLE = 1,
     parameter STATE_EXECUTE = 2,
     parameter STATE_WRITE = 3,
     parameter STATE_IDLE = 5,
     parameter STATE_EXECUTE_CLEAR = 9,
     parameter STATE_EXECUTE_REGMUL = 10,
     parameter STATE_EXECUTE_FILL = 11,
     parameter STATE_WAIT = 12,
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
     parameter INSTRUCTION_CLEAR = 4'b0100,
     parameter INSTRUCTION_STORE = 4'b0101,
     parameter INSTRUCTION_FILL = 4'b0110,
     parameter INSTRUCTION_COPY = 4'b0111,
     parameter INSTRUCTION_GET = 4'b1000
)
(
    input wire Clk,
    input wire Rst,
    output wire VgaHSync,
    output wire VgaVSync,
    output wire VgaColorR,
    output wire VgaColorG,
    output wire VgaColorB,
    input wire InstructionExecute
    input wire [24:0] InstructionInput,
    output wire [24:0] DataOutput,
    output wire Ready
);

    assign Ready = (State == STATE_IDLE);

    reg [24:0] InstructionInputCopy;
    
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

    reg [0:STATE_BIT_WIDTH-1] State = STATE_IDLE;
    reg [0:STATE_BIT_WIDTH-1] FutureState = STATE_IDLE;
    
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
     
    always @(posedge Clk)
    begin
        FrameBufferWrite <= 0;
        
        if(State == STATE_READ)
            begin
                State <= STATE_IDLE;
                DataOutput <= FrameBufferOutput;
            end
        else if(State == STATE_WAIT)
            begin
                State <= STATE_IDLE;
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
                                State <= STATE_WAIT;
                                DataOutput <= OK_CODE;
                            end
                        if(PX2 >= CX4 && PY2 >= CY4)
                            begin
                                State <= STATE_WAIT;
                                DataOutput <= OK_CODE;
                            end
                   end
               else
                   begin
                   
                        if(PX1 <= CX1 && PY1 <= CY1)
                            begin
                                State <= STATE_WAIT;
                                DataOutput <= OK_CODE;
                            end
                        if(PX2 <= CX3 && PY2 <= CY3)
                            begin
                                State <= STATE_WAIT;
                                DataOutput <= OK_CODE;
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
                        State <= STATE_WAIT;
                        DataOutput <= OK_CODE;
                    end
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
                FrameBufferInput <= InstructionInputCopy[19:17];
                FrameBufferAddr <= FrameBufferAddr+1;
                if(FrameBufferAddr >= 120_000)
                    begin
                        State <= STATE_IDLE;
                        DataOutput <= OK_CODE;
                        FrameBufferAddr <= 0;
                        FrameBufferWrite <= 0;
                    end
                else
                    begin
                        State <= STATE_EXECUTE_CLEAR;
                    end
            end
        else if(State == STATE_WRITE) 
            begin
                State <= FutureState;
                FrameBufferWrite <= 0;
                FrameBufferInput <= 0;
            end
         else if(State == STATE_EXECUTE)
            begin
                State <= STATE_IDLE;
                DataOutput <= OK_CODE;
                casez(InstructionInputCopy[23:20])
                    INSTRUCTION_ECHO:
                        begin
                            State <= STATE_IDLE;
                            DataOutput <= InstructionInputCopy[19:0];
                        end
                    INSTRUCTION_GET:
                        begin
                            State <= STATE_READ;
                            FrameBufferWrite <= 0;
                            FrameBufferAddr <= InstructionInputCopy[16:0];
                            FrameBufferInput <= 0;
                        end
                    INSTRUCTION_PUT:
                        begin
                            State <= STATE_WRITE;
                            FutureState <= STATE_IDLE;
                            FrameBufferWrite <= 1;
                            FrameBufferAddr <= InstructionInputCopy[16:0];
                            FrameBufferInput <= InstructionInputCopy[19:17];
                            PColor <= InstructionInputCopy[19:17];
                        end
                    INSTRUCTION_CLEAR:
                        begin
                            State <= STATE_EXECUTE_CLEAR;
                            FrameBufferAddr <= 0;
                        end
                    INSTRUCTION_STORE:
                        begin
                            State <= STATE_WAIT;
                            DataOutput <= OK_CODE;
                            if(InstructionInputCopy[19:17] == 3'b000)
                                begin
                                    RegisterA <= InstructionInputCopy[16:0];
                                end
                            else if(InstructionInputCopy[19:17] == 3'b001)
                                begin
                                    RegisterB <= InstructionInputCopy[16:0];
                                end
                            else if(InstructionInputCopy[19:17] == 3'b010)
                                begin
                                    RegisterC <= InstructionInputCopy[16:0];
                                end
                            else if(InstructionInputCopy[19:17] == 3'b011)
                                begin
                                    RegisterD <= InstructionInputCopy[16:0];
                                end
                            else if(InstructionInputCopy[19:17] == 3'b100)
                                begin
                                    RegisterE <= InstructionInputCopy[16:0];
                                end
                            else if(InstructionInputCopy[19:17] == 3'b101)
                                begin
                                    RegisterF <= InstructionInputCopy[16:0];
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
                    INSTRUCTION_FILL:
                        begin
                            State <= STATE_EXECUTE_FILL;
                            CX1 <= RegisterA;
                            CY1 <= RegisterB;
                            CX2 <= RegisterC;
                            CY2 <= RegisterD;
                            
                            PX1 <= RegisterA;
                            PY1 <= RegisterB;
                            
                            PColor <= InstructionInputCopy[19:17];
                        end
                    default:
                        begin
                            State <= STATE_IDLE;
                        end
                endcase
            end
        else if(InstructionExecute && State == STATE_IDLE)
            begin
                State <= STATE_EXECUTE;
                InstructionInputCopy <= InstructionInput;
            end
    end
    
endmodule


`endif