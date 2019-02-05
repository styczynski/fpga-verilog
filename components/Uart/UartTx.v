`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_UART_TX
`define LIB_STYCZYNSKI_UART_TX

`include "../../components/FreqDivider/FreqDivider.v"

module UartTx
#(
    parameter CLOCK_FREQUENCY  = 1_000_000,
    parameter BAUD_RATE  = 9600,
    parameter STATE_TX_IDLE  = 3'd0,
    parameter STATE_TX_START = 3'd1,
    parameter STATE_TX_DATA  = 3'd2,
    parameter STATE_TX_STOP0 = 3'd3,
    parameter STATE_TX_STOP1 = 3'd4
) (
    input wire Reset,
    input wire Clk,
    output wire TxWire,
    input wire [7:0] TxDataInput,
    input wire TxEnable,
    output wire TxReady
);

    
    // TX sampler
    reg TxSamplerReset = 1'b0;
    wire TxSamplerClockEnable;
    
    FreqDivider #(
        .FREQUENCY_IN(CLOCK_FREQUENCY),
        .FREQUENCY_OUT(CLOCK_FREQUENCY / ((CLOCK_FREQUENCY / (BAUD_RATE * 3) / 2) * 2) / 3),
        .PHASE(1'b0)
    ) tx_sampler_clk_div (
        .Reset(TxSamplerReset),
        .Clk(Clk),
        .ClkOutput(TxSamplerClockEnable)
    );

    // TX strobe generator
    reg [1:0] TxStrobeReg = 2'b00;
    wire TxStrobe = (TxStrobeReg == 2'b01);
    
    always @(posedge Clk or negedge Reset)
    begin
        if(!Reset)
            begin
                TxStrobeReg <= 2'b00;
            end
        else
            begin
                TxStrobeReg <= {TxStrobeReg[0], TxSamplerClockEnable};
            end
    end
               
    reg [2:0] TxState = 3'd0;
    reg [7:0] TxData  = 8'b00000000;
    reg [2:0] TxBitNo = 3'd0;
    reg TxBuf = 1'b1;
    
    always @(posedge Clk or negedge Reset)
    begin
        if(!Reset) begin
            TxSamplerReset <= 1'b0;
            TxState <= 3'd0;
            TxData <= 8'b00000000;
            TxBitNo <= 3'd0;
            TxBuf <= 1'b1;
        end else case(TxState)
            STATE_TX_IDLE:
                if(TxEnable)
                    begin
                        TxSamplerReset <= 1'b1;
                        TxState <= STATE_TX_START;
                        TxData <= TxDataInput;
                    end
            STATE_TX_START:
                if(TxStrobe)
                    begin
                        TxState <= STATE_TX_DATA;
                        TxBuf <= 1'b0;
                    end
            STATE_TX_DATA:
                if(TxStrobe)
                    begin
                        if(TxBitNo == 3'd7)
                            begin
                                TxState <= STATE_TX_STOP0;
                            end
                        TxData <= {1'b0, TxData[7:1]};
                        TxBitNo <= TxBitNo + 3'd1;
                        TxBuf <= TxData[0];
                    end
            STATE_TX_STOP0:
                if(TxStrobe)
                    begin
                        TxState <= STATE_TX_STOP1;
                        TxBuf <= 1'b1;
                    end
            STATE_TX_STOP1:
                if(TxStrobe)
                    begin
                        TxSamplerReset <= 1'b0;
                        TxState <= STATE_TX_IDLE;
                    end
        endcase
    end

    assign TxWire = TxBuf;
    assign TxReady = (TxState == STATE_TX_IDLE);

endmodule

`endif