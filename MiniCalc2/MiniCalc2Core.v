`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_MINI_CALC_2_CORE_V
`define LIB_STYCZYNSKI_MINI_CALC_2_CORE_V

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
    parameter STATE_BIT_WIDTH = 2,
    parameter CODE_INSTR_NOP  = 8'b00001111,
    parameter CODE_INSTR_ECHO = 8'b00011111,
    parameter CODE_INSTR_PUSH = 8'b00000001,
    parameter CODE_INSTR_POP  = 8'b00000010,
    parameter CODE_INSTR_COPY = 8'b00000011,
    parameter CODE_INSTR_ADD  = 8'b00000100,
    parameter CODE_INSTR_SUB  = 8'b00000101,
    parameter CODE_INSTR_MUL  = 8'b00000110,
    parameter CODE_INSTR_DIV  = 8'b00001000,
    parameter CODE_INSTR_SWAP = 8'b00001001,
    parameter CODE_INSTR_MOD  = 8'b00001010,
    parameter CODE_INSTR_DUMP = 8'b00000111,
    parameter CODE_INSTR_CLS  = 8'b10000000,
    parameter STACK_ADDR_SIZE = 3,
    parameter STATE_IDLE = 2'b00,
    parameter STATE_ACCUMULATE = 2'b01,
    parameter STATE_EXECUTE = 2'b10,
    parameter STATE_DUMP = 2'b11
)
(
    input Clk,
	input [0:INSTR_BIT_WIDTH-1] Instruction,
    input [0:INPUT_BIT_WIDTH-1] InputA,
    output reg [0:INPUT_BIT_WIDTH-1] OutputA = 0,
    output reg [0:INPUT_BIT_WIDTH-1] StackTop = 0,
    input Execute,
    output reg Ready,
    output reg HasNext = 0,
    output wire StackEmpty,
    output reg OperationalError = 0,
    input Next
);
    
    reg [0:STATE_BIT_WIDTH-1] State = STATE_IDLE;
    
    reg [INPUT_BIT_WIDTH-1:0] Stack [0:(1<<STACK_ADDR_SIZE)-1];
    reg [0:STACK_ADDR_SIZE-1] StackPointer;
    
    reg [0:STACK_ADDR_SIZE-1] StackTraversePointer;
    
    reg [INPUT_BIT_WIDTH-1:0] Arg1;
    reg [INPUT_BIT_WIDTH-1:0] Arg2;
    
    assign StackEmpty = (StackPointer == 0);
    
    always @(posedge Clk)
    begin
        if(State == STATE_DUMP)
            begin
                if(StackTraversePointer <= StackPointer)
                    begin
                        State <= STATE_DUMP;
                        Ready <= 0;
                        HasNext <= 1;
                        OutputA <= Stack[StackTraversePointer];
                        if(Next)
                            begin
                                StackTraversePointer <= StackTraversePointer+1;
                            end     
                    end
                else
                    begin
                        OutputA <= 0;
                        State <= STATE_IDLE;
                        Ready <= 1;
                        StackTraversePointer <= 0;
                        HasNext <= 0;
                    end
            end
        else if(State == STATE_IDLE && Execute)
            begin
                HasNext <= 0;
                //StackTop <= Stack[StackPointer];
                OperationalError <= 0;
                casez(Instruction)
                    CODE_INSTR_CLS:
                        begin
                            State <= STATE_IDLE;
                            Ready <= 1;
                            StackTop <= 0;
                            StackPointer <= 0;
                        end
                    CODE_INSTR_ECHO:
                        begin
                            State <= STATE_IDLE;
                            Ready <= 1;
                            StackTop <= InputA;
                        end
                    CODE_INSTR_NOP:
                        begin
                            State <= STATE_IDLE;
                            Ready <= 1;
                        end
                    CODE_INSTR_PUSH:
                        begin
                            State <= STATE_IDLE;
                            Ready <= 1;
                            StackTop <= InputA;
                            Stack[StackPointer] <= InputA;
                            StackPointer <= StackPointer+1;
                        end
                    CODE_INSTR_POP:
                        begin
                            State <= STATE_IDLE;
                            Ready <= 1;
                            if(StackPointer == 0)
                                begin
                                    OperationalError <= 1;
                                    StackTop <= 0;
                                end
                            else if(StackPointer == 1)
                                begin
                                    StackTop <= 0;
                                    StackPointer <= 0;
                                end
                            else
                                begin
                                    StackTop <= Stack[StackPointer-2];
                                    StackPointer <= StackPointer-1;
                                end
                        end
                    CODE_INSTR_COPY:
                        begin
                            State <= STATE_IDLE;
                            Ready <= 1;
                            Stack[StackPointer] <= StackTop;
                            StackPointer <= StackPointer+1;
                        end
                    CODE_INSTR_DUMP:
                        begin
                            State <= STATE_DUMP;
                            Ready <= 0;
                            OutputA <= Stack[0];
                            StackTraversePointer <= 0;
                            HasNext <= 1;
                        end
                    CODE_INSTR_ADD, CODE_INSTR_SUB, CODE_INSTR_MUL, CODE_INSTR_MOD, CODE_INSTR_SWAP:
                        begin
                            State <= STATE_ACCUMULATE;
                            Ready <= 0;
                            Arg1 <= Stack[StackPointer-1];
                        end
                    default:
                        begin
                            State <= STATE_IDLE;
                            Ready <= 1;
                        end
                endcase
            end
        else if(State == STATE_ACCUMULATE)
            begin
                State <= STATE_EXECUTE;
                Ready <= 0;
                Arg2 <= Stack[StackPointer-2];
                if(Instruction == CODE_INSTR_SWAP)
                    begin
                        Stack[StackPointer-2] <= Arg1;
                    end
            end
        else if(State == STATE_EXECUTE)
            begin
                 casez(Instruction)
                    CODE_INSTR_ADD:
                        begin
                            State <= STATE_IDLE;
                            Ready <= 1;
                            StackTop <= Arg1 + Arg2;
                            Stack[StackPointer-2] <= Arg1 + Arg2;
                            StackPointer <= StackPointer-1;
                        end
                    CODE_INSTR_SUB:
                        begin
                            State <= STATE_IDLE;
                            Ready <= 1;
                            StackTop <= Arg1 - Arg2;
                            Stack[StackPointer-2] <= Arg1 - Arg2;
                            StackPointer <= StackPointer-1;
                        end
                    CODE_INSTR_MUL:
                        begin
                            State <= STATE_IDLE;
                            Ready <= 1;
                            StackTop <= Arg1 * Arg2;
                            Stack[StackPointer-2] <= Arg1 * Arg2;
                            StackPointer <= StackPointer-1;
                        end
                    CODE_INSTR_DIV:
                        begin
                            State <= STATE_IDLE;
                            Ready <= 1;
                            StackTop <= Arg1 / Arg2;
                            Stack[StackPointer-2] <= Arg1 / Arg2;
                            StackPointer <= StackPointer-1;
                        end
                    CODE_INSTR_MOD:
                        begin
                            State <= STATE_IDLE;
                            Ready <= 1;
                            StackTop <= Arg1 % Arg2;
                            Stack[StackPointer-2] <= Arg1 % Arg2;
                            StackPointer <= StackPointer-1;
                        end
                    CODE_INSTR_SWAP:
                        begin
                            State <= STATE_IDLE;
                            Ready <= 1;
                            StackTop <= Arg2;
                            Stack[StackPointer-1] <= Arg2;
                        end
                    default:
                        begin
                            State <= STATE_IDLE;
                            Ready <= 1;
                        end
                endcase
            end
       end
	 
endmodule


`endif