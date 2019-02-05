`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_UART_RX
`define LIB_STYCZYNSKI_UART_RX

`include "../../components/FreqDivider/FreqDivider.v"

module UartRx
#(
    parameter CLOCK_FREQUENCY  = 1_000_000,
    parameter BAUD_RATE  = 9600,
    parameter STATE_RX_IDLE  = 3'd0,
    parameter STATE_RX_START = 3'd1,
    parameter STATE_RX_DATA  = 3'd2,
    parameter STATE_RX_STOP  = 3'd3,
    parameter STATE_RX_FULL  = 3'd4,
    parameter STATE_RX_ERROR = 3'd5
) (
    input wire Reset,
    input wire Clk,
    input wire RxWire,
    output wire [7:0] RxDataOutput,
    output wire RxReady,
    input wire RxEnable,
    output wire RxError
);

    // RX oversampler
    reg RxSamplerReset = 1'b0;
    wire RxSamplerClockEnable;
    
    FreqDivider #(
        .FREQUENCY_IN(CLOCK_FREQUENCY),
        .FREQUENCY_OUT(BAUD_RATE * 3)
    ) rx_sampler_clk_div (
        .Reset(RxSamplerReset),
        .Clk(Clk),
        .ClkEnableOutput(RxSamplerClockEnable)
    );

    reg [2:0] RxSample = 3'b000;
    wire RxSample1 = ( RxSample == 3'b111 || RxSample == 3'b110 || RxSample == 3'b101 || RxSample == 3'b011 );
    
    always @(posedge Clk or negedge RxSamplerReset)
    begin
        if(!RxSamplerReset)
            begin
                RxSample <= 3'b000;
            end
        else if(RxSamplerClockEnable)
            begin
                RxSample <= {RxSample[1:0], RxWire};
            end
    end
                
    (* fsm_encoding="one-hot" *)
    reg [1:0] RxSampleNo = 2'd2;
    wire RxSampleReady = ( RxSampleNo == 2'd2 );
    
    always @(posedge Clk or negedge RxSamplerReset)
    begin
        if(!RxSamplerReset)
            begin
                RxSampleNo <= 2'd2;
            end
        else if(RxSamplerClockEnable)
            begin
                case(RxSampleNo)
                    2'd0: RxSampleNo <= 2'd1;
                    2'd1: RxSampleNo <= 2'd2;
                    2'd2: RxSampleNo <= 2'd0;
                endcase
            end
    end

    // RX strobe generator
    reg  [1:0] RxStrobeReg = 2'b00;
    wire RxStrobe = ( RxStrobeReg == 2'b01 );
    
    always @(posedge Clk or negedge Reset)
    begin
        if(!Reset)
            begin
                RxStrobeReg <= 2'b00;
            end
        else
            begin
                RxStrobeReg <= { RxStrobeReg[0], RxSampleReady };
            end
    end

    reg  [2:0] RxState = 3'd0;
    reg  [7:0] RxData  = 8'b00000000;
    reg  [2:0] RxBitNo = 3'd0;
    
    assign RxDataOutput  = RxData;
    assign RxReady = (RxState == STATE_RX_FULL);
    assign RxError = (RxState == STATE_RX_ERROR);

    always @(posedge Clk or negedge Reset)
    begin
        if(!Reset)
            begin
                RxSamplerReset <= 1'b0;
                RxState <= STATE_RX_IDLE;
                RxData <= 8'b00000000;
                RxBitNo <= 3'd0;
            end
        else
            begin
                case(RxState)
                    STATE_RX_IDLE:
                        if(!RxWire) begin
                            RxSamplerReset <= 1'b1;
                            RxState <= STATE_RX_START;
                        end
                    STATE_RX_START:
                        if(RxStrobe)
                            RxState <= STATE_RX_DATA;
                    STATE_RX_DATA:
                        if(RxStrobe)
                            begin
                                if(RxBitNo == 3'd7)
                                    begin
                                        RxState <= STATE_RX_STOP;
                                    end
                                RxData <= {RxSample1, RxData[7:1]};
                                RxBitNo <= RxBitNo + 3'd1;
                            end
                    STATE_RX_STOP:
                        if(RxStrobe) begin
                            RxSamplerReset <= 1'b0;
                            if(RxSample1 == 1'b0)
                                begin
                                    RxState <= STATE_RX_ERROR;
                                end
                            else
                                begin
                                    RxState <= STATE_RX_FULL;
                                end
                        end
                    STATE_RX_FULL:
                        if(RxEnable)
                            begin
                                RxState <= STATE_RX_IDLE;
                            end
                        else if(!RxWire)
                            begin
                                RxState <= STATE_RX_ERROR;
                            end
                endcase
            end
    end
            
endmodule

`endif