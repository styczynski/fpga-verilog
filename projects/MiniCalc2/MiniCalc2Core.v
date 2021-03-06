`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_MINI_CALC_2_CORE_V
`define LIB_STYCZYNSKI_MINI_CALC_2_CORE_V

`include "../../components/Ram/Ram.v"
`include "../../components/SignDivider/SignDivider.v"
`include "../../components/Multiplier/Multiplier.v"

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * MiniCalc2Core
 * 
 *
 * MIT License
 */
module MiniCalc2Core
#(
    parameter INSTR_BIT_WIDTH  = 8,
    parameter INPUT_BIT_WIDTH = 8,
    parameter STACK_ADDR_SIZE = 8,
    parameter STATE_BIT_WIDTH = 4,
    parameter CODE_INSTR_NOP    = 8'b00001111,
    parameter CODE_INSTR_ECHO   = 8'b00011111,
    parameter CODE_INSTR_PUSH   = 8'b00000001,
    parameter CODE_INSTR_POP    = 8'b00000010,
    parameter CODE_INSTR_COPY   = 8'b00000011,
    parameter CODE_INSTR_ADD    = 8'b00000100,
    parameter CODE_INSTR_SUB    = 8'b00000101,
    parameter CODE_INSTR_MUL    = 8'b00000110,
    parameter CODE_INSTR_DIV    = 8'b00001000,
    parameter CODE_INSTR_SWAP   = 8'b00001001,
    parameter CODE_INSTR_MOD    = 8'b00001010,
    parameter CODE_INSTR_GET    = 8'b00100000,
    parameter CODE_INSTR_LEN    = 8'b00100010,
    parameter CODE_INSTR_FLA    = 8'b00100100,
    parameter CODE_INSTR_ADDROT = 8'b00100001,
    parameter CODE_INSTR_CLS    = 8'b10000000,
    parameter STATE_IDLE = 0,
    parameter STATE_FETCH_OUT = 1,
    parameter STATE_FETCH_SEC = 2,
    parameter STATE_WAIT_DIV = 3,
    parameter STATE_WAIT_MOD = 4,
    parameter STATE_WAIT_MUL = 5,
    parameter STATE_EXECUTING_DIV = 6,
    parameter STATE_EXECUTING_MOD = 7,
    parameter STATE_EXECUTING_MUL = 8,
    parameter STATE_WAIT_MUL_INIT = 9
)
(
    input wire Clk,
    input wire [0:INSTR_BIT_WIDTH-1] Instruction,
    input wire [0:INPUT_BIT_WIDTH-1] InputA,
    output reg [0:INPUT_BIT_WIDTH-1] OutputA = 0,
    output reg [0:INPUT_BIT_WIDTH-1] StackFirst = 0,
    output reg [0:INPUT_BIT_WIDTH-1] StackSecond = 0,
    output reg [0:STACK_ADDR_SIZE-1] StackSize = 0,
    input wire Execute,
    output wire Ready,
    output wire StackEmpty,
    output wire OperationalError,
    output reg ErrorStackUnderflow,
    output reg ErrorInvalidArg,
    output reg ErrorInvalidInstr,
    output reg ErrorOverflow
);
    
    reg [0:STATE_BIT_WIDTH-1] State = STATE_IDLE;
    
    reg WaitFlag;
    reg RamWrite;
    reg [0:STACK_ADDR_SIZE-1] RamAddr;
    reg [INPUT_BIT_WIDTH-1:0] RamInput;
    wire [INPUT_BIT_WIDTH-1:0] RamOutput;
    
    assign Ready = ( State == STATE_IDLE && !WaitFlag );
    assign StackEmpty = (StackSize == 0);
    assign OperationalError = ( ErrorStackUnderflow | ErrorInvalidArg | ErrorInvalidInstr | ErrorOverflow );
    
    RAM #(
        .DATA_WIDTH(INPUT_BIT_WIDTH),
        .ADDR_WIDTH(STACK_ADDR_SIZE)
    ) ramModule (
        .Clk(Clk),
        .Addr(RamAddr),
        .Write(RamWrite),
        .Input(RamInput),
        .Output(RamOutput)
    );
    
    reg [0:INPUT_BIT_WIDTH-1] DividerInputA;
    reg [0:INPUT_BIT_WIDTH-1] DividerInputB;
    wire [0:INPUT_BIT_WIDTH-1] DividerQuotient;
    wire [0:INPUT_BIT_WIDTH-1] DividerRemainder;
    wire DividerReady;
    
    SignDivider #(
        .INPUT_BIT_WIDTH(INPUT_BIT_WIDTH)
    ) dividerModule (
        .Clk(Clk),
        .Sign(1'b1),
        .Dividend(DividerInputA),
        .Divider(DividerInputB),
        .Quotient(DividerQuotient),
        .Remainder(DividerRemainder),
        .Ready(DividerReady)
    );
    
    reg [0:INPUT_BIT_WIDTH-1] MultiplierInputA = 0;
    reg [0:INPUT_BIT_WIDTH-1] MultiplierInputB = 0;
    wire [0:(2*INPUT_BIT_WIDTH-1)] MultiplierProduct;
    reg MultiplierStart = 0;
    wire MultiplierReady;
    
    Multiplier #(
       .DATA_WIDTH(INPUT_BIT_WIDTH)
    ) multiplierModule (
       .Clk(Clk),
       .InputA(MultiplierInputA),
       .InputB(MultiplierInputB),
       .Product(MultiplierProduct),
       .Start(MultiplierStart),
       .Ready(MultiplierReady)
    );
    
    reg [0:STACK_ADDR_SIZE-1] StackTraversePointer;
    
    always @(posedge Clk)
    begin
        RamWrite <= 0;
        if(WaitFlag)
            begin
                WaitFlag <= 0;
                RamWrite <= 0;
            end
        else if(State == STATE_EXECUTING_DIV)
            begin
                if(DividerReady)
                    begin
                        StackFirst <= DividerQuotient;
                        StackSecond <= 0;
                        OutputA <= 0;
                        if(StackSize >= 3)
                            begin
                                State <= STATE_FETCH_SEC;
                                WaitFlag <= 1;
                                RamWrite <= 0;
                                RamAddr <= StackSize-3;
                            end
                        else
                            begin
                                State <= STATE_IDLE;
                                StackSecond <= 0;
                            end
                            
                        StackSize <= StackSize-1;
                    end
            end
        else if(State == STATE_WAIT_DIV)
            begin
                if(DividerReady)
                    begin
                        State <= STATE_EXECUTING_DIV;
                        DividerInputA <= StackSecond;
                        DividerInputB <= StackFirst;
                    end
            end
        else if(State == STATE_EXECUTING_MOD)
            begin
                StackFirst <= DividerRemainder;
                StackSecond <= 0;
                OutputA <= 0;
                if(StackSize >= 3)
                    begin
                        State <= STATE_FETCH_SEC;
                        WaitFlag <= 1;
                        RamWrite <= 0;
                        RamAddr <= StackSize-3;
                    end
                else
                    begin
                        State <= STATE_IDLE;
                        StackSecond <= 0;
                    end
                    
                StackSize <= StackSize-1;
            end
        else if(State == STATE_WAIT_MOD) 
            begin
                if(DividerReady)
                    begin
                        State <= STATE_EXECUTING_MOD;
                        DividerInputA <= StackSecond;
                        DividerInputB <= StackFirst;
                    end
            end
        else if(State == STATE_EXECUTING_MUL)
            begin
                MultiplierStart <= 0;
                if(MultiplierReady)
                    begin
                        StackFirst <= MultiplierProduct;
                        OutputA <= 0;
                        StackSecond <= 0;
                        if(StackSize >= 3)
                            begin
                                State <= STATE_FETCH_SEC;
                                WaitFlag <= 1;
                                RamWrite <= 0;
                                RamAddr <= StackSize-3;
                            end
                        else
                            begin
                                State <= STATE_IDLE;
                                StackSecond <= 0;
                            end
                            
                        StackSize <= StackSize-1;
                    end
            end
        else if(State == STATE_WAIT_MUL_INIT)
            begin
                if(!MultiplierReady)
                    begin
                        MultiplierStart <= 0;
                        State <= STATE_EXECUTING_MUL;
                    end
            end
        else if(State == STATE_WAIT_MUL)
            begin
                if(MultiplierReady)
                    begin
                        State <= STATE_WAIT_MUL_INIT;
                        MultiplierInputA <= StackFirst;
                        MultiplierInputB <= StackSecond;
                        MultiplierStart <= 1;
                    end
                else
                    begin
                        MultiplierStart <= 0;
                    end
            end
        else if(State == STATE_FETCH_SEC)
            begin
                State <= STATE_IDLE;
                StackSecond <= RamOutput;
            end
        else if(State == STATE_FETCH_OUT)
            begin
                State <= STATE_IDLE;
                OutputA <= RamOutput;
            end
        else if(State == STATE_IDLE && Execute)
            begin
                casez(Instruction)
                    CODE_INSTR_CLS:
                        begin
                            ErrorStackUnderflow <= 0;
                            ErrorInvalidArg <= 0;
                            ErrorInvalidInstr <= 0;
                            ErrorOverflow <= 0;
                            State <= STATE_IDLE;
                            StackSize <= 0;
                            StackFirst <= 0;
                            StackSecond <= 0;
                            OutputA <= 0;
                            RamWrite <= 0;
                            RamAddr <= 0;
                        end
                    CODE_INSTR_ECHO:
                        begin
                            ErrorStackUnderflow <= 0;
                            ErrorInvalidArg <= 0;
                            ErrorInvalidInstr <= 0;
                            ErrorOverflow <= 0;
                            State <= STATE_IDLE;
                            StackSize <= 0;
                            StackFirst <= InputA;
                            StackSecond <= 0;
                            OutputA <= InputA;
                        end
                    CODE_INSTR_NOP:
                        begin
                            ErrorStackUnderflow <= 0;
                            ErrorInvalidArg <= 0;
                            ErrorInvalidInstr <= 0;
                            ErrorOverflow <= 0;
                            State <= STATE_IDLE;
                            OutputA <= 0;
                        end
                    CODE_INSTR_ADDROT:
                        begin
                            if(StackSize > 0)
                                begin
                                    State <= STATE_IDLE;
                                    ErrorStackUnderflow <= 0;
                                    ErrorInvalidArg <= 0;
                                    ErrorInvalidInstr <= 0;
                                    ErrorOverflow <= 0;
                                    StackFirst <= { StackFirst[INPUT_BIT_WIDTH-23:INPUT_BIT_WIDTH-1], InputA[INPUT_BIT_WIDTH-8:INPUT_BIT_WIDTH-1] };
                                    OutputA <= 0;
                                end
                            else
                                begin
                                    ErrorStackUnderflow <= 1;
                                    ErrorInvalidArg <= 0;
                                    ErrorInvalidInstr <= 0;
                                    ErrorOverflow <= 0;
                                end
                        end
                    CODE_INSTR_PUSH:
                        begin
                            if(StackSize >= (1<<STACK_ADDR_SIZE) - 1)
                                begin
                                    ErrorStackUnderflow <= 0;
                                    ErrorInvalidArg <= 0;
                                    ErrorInvalidInstr <= 0;
                                    ErrorOverflow <= 1;
                                    State <= STATE_IDLE;
                                end
                            else
                                begin
                                    ErrorStackUnderflow <= 0;
                                    ErrorInvalidArg <= 0;
                                    ErrorInvalidInstr <= 0;
                                    ErrorOverflow <= 0;
                                    State <= STATE_IDLE;
                                    WaitFlag <= 1;
                                    StackFirst <= InputA;
                                    StackSecond <= StackFirst;
                                    OutputA <= InputA;
                                    if(StackSize >= 2)
                                        begin
                                            RamWrite <= 1;
                                            RamAddr <= StackSize-2;
                                            RamInput <= StackSecond;
                                        end
                                    StackSize <= StackSize+1;
                                end
                        end
                    CODE_INSTR_POP:
                        begin
                            if(StackSize == 0)
                                begin
                                    ErrorStackUnderflow <= 1;
                                    ErrorInvalidArg <= 0;
                                    ErrorInvalidInstr <= 0;
                                    ErrorOverflow <= 0;
                                    StackSize <= 0;
                                    StackFirst <= 0;
                                    StackSecond <= 0;
                                    OutputA <= 0;
                                    State <= STATE_IDLE;
                                end
                            else if(StackSize == 1)
                                begin
                                    ErrorStackUnderflow <= 0;
                                    ErrorInvalidArg <= 0;
                                    ErrorInvalidInstr <= 0;
                                    ErrorOverflow <= 0;
                                    StackSize <= 0;
                                    StackFirst <= 0;
                                    StackSecond <= 0;
                                    OutputA <= 0;
                                    State <= STATE_IDLE;
                                end
                            else if(StackSize == 2)
                                begin
                                    ErrorStackUnderflow <= 0;
                                    ErrorInvalidArg <= 0;
                                    ErrorInvalidInstr <= 0;
                                    ErrorOverflow <= 0;
                                    StackSize <= 1;
                                    StackFirst <= StackSecond;
                                    StackSecond <= 0;
                                    OutputA <= StackSecond;
                                    State <= STATE_IDLE;
                                end
                           else
                                begin
                                    ErrorStackUnderflow <= 0;
                                    ErrorInvalidArg <= 0;
                                    ErrorInvalidInstr <= 0;
                                    ErrorOverflow <= 0;
                                    State <= STATE_FETCH_SEC;
                                    WaitFlag <= 1;
                                    StackSize <= StackSize - 1;
                                    StackFirst <= StackSecond;
                                    OutputA <= StackSecond;
                                    StackSecond <= 0;
                                    RamWrite <= 0;
                                    RamAddr <= StackSize-3;
                                end
                        end
                    CODE_INSTR_COPY:
                        begin
                            if(StackSize > 0)
                                begin
                                    ErrorStackUnderflow <= 0;
                                    ErrorInvalidArg <= 0;
                                    ErrorInvalidInstr <= 0;
                                    ErrorOverflow <= 0;
                                    State <= STATE_IDLE;
                                    WaitFlag <= 1;
                                    StackSecond <= StackFirst;
                                    OutputA <= StackFirst;
                                    if(StackSize >= 2)
                                        begin
                                            RamWrite <= 1;
                                            RamAddr <= StackSize-2;
                                            RamInput <= StackSecond;
                                        end
                                   StackSize <= StackSize+1;
                                end
                            else    
                                begin
                                    ErrorStackUnderflow <= 1;
                                    ErrorInvalidArg <= 0;
                                    ErrorInvalidInstr <= 0;
                                    ErrorOverflow <= 0;
                                end
                        end
                    CODE_INSTR_SWAP:
                        begin
                            if(StackSize > 1)
                                begin
                                    ErrorStackUnderflow <= 0;
                                    ErrorInvalidArg <= 0;
                                    ErrorInvalidInstr <= 0;
                                    ErrorOverflow <= 0;
                                    State <= STATE_IDLE;
                                    StackFirst <= StackSecond;
                                    StackSecond <= StackFirst;
                                    OutputA <= StackSecond;
                                end
                            else
                                begin
                                    ErrorStackUnderflow <= 1;
                                    ErrorInvalidArg <= 0;
                                    ErrorInvalidInstr <= 0;
                                    ErrorOverflow <= 0;
                                end
                        end
                    CODE_INSTR_GET:
                        begin
                            if(InputA >= StackSize)
                                begin
                                    State <= STATE_IDLE;
                                    OutputA <= 0;
                                end
                            else if(InputA == StackSize-1)
                                begin
                                    State <= STATE_IDLE;
                                    OutputA <= StackFirst;
                                end
                            else if(InputA == StackSize-2)
                                begin
                                    State <= STATE_IDLE;
                                    OutputA <= StackSecond;
                                end
                            else
                                begin
                                    State <= STATE_FETCH_OUT;
                                    WaitFlag <= 1;
                                    RamWrite <= 0;
                                    RamAddr <= InputA;
                                    OutputA <= 0;
                                end
                        end
                    CODE_INSTR_LEN:
                        begin
                            State <= STATE_IDLE;
                            OutputA <= StackSize;
                        end
                    CODE_INSTR_FLA:
                        begin
                            State <= STATE_IDLE;
                            OutputA <= { StackEmpty, ErrorStackUnderflow, ErrorInvalidArg, ErrorInvalidInstr, ErrorOverflow };
                        end
                    CODE_INSTR_ADD, CODE_INSTR_SUB, CODE_INSTR_MUL, CODE_INSTR_MOD, CODE_INSTR_DIV:
                        begin
                            if(StackSize > 1)
                                begin
                                    if(Instruction == CODE_INSTR_ADD)
                                        begin
                                            ErrorStackUnderflow <= 0;
                                            ErrorInvalidArg <= 0;
                                            ErrorInvalidInstr <= 0;
                                            ErrorOverflow <= 0;
                                            StackFirst <= StackSecond + StackFirst;
                                            OutputA <= 0;
                                            StackSecond <= 0;
                                            if(StackSize >= 3)
                                                begin
                                                    State <= STATE_FETCH_SEC;
                                                    WaitFlag <= 1;
                                                    RamWrite <= 0;
                                                    RamAddr <= StackSize-3;
                                                end
                                            else
                                                begin
                                                    State <= STATE_IDLE;
                                                    StackSecond <= 0;
                                                end
                                                
                                            StackSize <= StackSize-1;
                                        end
                                    else if(Instruction == CODE_INSTR_SUB)
                                        begin
                                            if(StackSecond < StackFirst)
                                                begin
                                                    ErrorStackUnderflow <= 0;
                                                    ErrorInvalidArg <= 1;
                                                    ErrorInvalidInstr <= 0;
                                                    ErrorOverflow <= 0;
                                                    OutputA <= 0;
                                                end
                                            else
                                                begin
                                                    ErrorStackUnderflow <= 0;
                                                    ErrorInvalidArg <= 0;
                                                    ErrorInvalidInstr <= 0;
                                                    ErrorOverflow <= 0;
                                                    StackFirst <= StackSecond - StackFirst;
                                                    OutputA <= 0;
                                                    StackSecond <= 0;
                                                    if(StackSize >= 3)
                                                        begin
                                                            State <= STATE_FETCH_SEC;
                                                            WaitFlag <= 1;
                                                            RamWrite <= 0;
                                                            RamAddr <= StackSize-3;
                                                        end
                                                    else
                                                        begin
                                                            State <= STATE_IDLE;
                                                            StackSecond <= 0;
                                                        end
                                                        
                                                    StackSize <= StackSize-1;
                                                end
                                        end
                                    else if(Instruction == CODE_INSTR_MUL)
                                        begin
                                            ErrorStackUnderflow <= 0;
                                            ErrorInvalidArg <= 0;
                                            ErrorInvalidInstr <= 0;
                                            ErrorOverflow <= 0;
                                            
                                            State <= STATE_WAIT_MUL;
                                        end
                                    else if(Instruction == CODE_INSTR_MOD)
                                        begin
                                            if(StackFirst == 0)
                                                begin
                                                    ErrorStackUnderflow <= 0;
                                                    ErrorInvalidArg <= 1;
                                                    ErrorInvalidInstr <= 0;
                                                    ErrorOverflow <= 0;
                                                    OutputA <= 0;
                                                end
                                            else
                                                begin
                                                    ErrorStackUnderflow <= 0;
                                                    ErrorInvalidArg <= 0;
                                                    ErrorInvalidInstr <= 0;
                                                    ErrorOverflow <= 0;
                                                    
                                                    State <= STATE_WAIT_MOD;
                                                end
                                        end
                                    else if(Instruction == CODE_INSTR_DIV)
                                        begin
                                            if(StackFirst == 0)
                                                begin
                                                    ErrorStackUnderflow <= 0;
                                                    ErrorInvalidArg <= 1;
                                                    ErrorInvalidInstr <= 0;
                                                    ErrorOverflow <= 0;
                                                    OutputA <= 0;
                                                end
                                            else
                                                begin
                                                    ErrorStackUnderflow <= 0;
                                                    ErrorInvalidArg <= 0;
                                                    ErrorInvalidInstr <= 0;
                                                    ErrorOverflow <= 0;
                                                    State <= STATE_WAIT_DIV;
                                                end
                                        end
                                end
                            else
                                begin
                                    ErrorStackUnderflow <= 1;
                                    ErrorInvalidArg <= 0;
                                    ErrorInvalidInstr <= 0;
                                    ErrorOverflow <= 0;
                                    OutputA <= 0;
                                end
                        end
                    default:
                        begin
                            State <= STATE_IDLE;
                            ErrorStackUnderflow <= 0;
                            ErrorInvalidArg <= 0;
                            ErrorInvalidInstr <= 1;
                            ErrorOverflow <= 0;
                            OutputA <= 0;
                        end
                endcase
            end
    end 
    
endmodule


`endif