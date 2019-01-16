`include "../FreqDivider/FreqDivider.v"

module UART
#(
    parameter CLOCK_FREQUENCY  = 1_000_000,
    parameter BAUD_RATE  = 9600
) (
    input           Reset,
    input           Clk,
    input           RxWire,
    output [7:0]    RxDataOutput,
    output          RxReady,
    input           RxEnable,
    output          RxError,
    output          TxWire,
    input  [7:0]    TxDataInput,
    input           TxEnable,
    output          TxReady
);

    // RX oversampler
    reg RxSamplerReset = 1'b0;
    wire RxSamplerClockEnable;
    
    FreqDivider #(
        .FREQUENCY_IN(CLOCK_FREQUENCY),
        .FREQUENCY_OUT(BAUD_RATE * 3),
        .INITIAL_CLOCK_PHASE(1'b1)
    ) rx_sampler_clk_div (
        .Reset(RxSamplerReset),
        .Clk(Clk),
        .ClkOutput(RxSamplerClockEnable)
    );

    reg [2:0] RxSample = 3'b000;
    wire RxSample1 = ( RxSample == 3'b111 || RxSample == 3'b110 || RxSample == 3'b101 || RxSample == 3'b011 );
    
    always @(posedge Clk or negedge RxSamplerReset)
        if(RxSamplerClockEnable)
            begin
                if(!RxSamplerReset)
                    begin
                        RxSample <= 3'b000;
                    end
                else
                    begin
                        RxSample <= {RxSample[1:0], RxWire};
                    end
            end
                
    (* fsm_encoding="one-hot" *)
    reg [1:0] RxSampleNo = 2'd2;
    wire RxSampleReady = ( RxSampleNo == 2'd2 );
    
    always @(posedge Clk or negedge RxSamplerReset)
        if(RxSamplerClockEnable)
            begin
                if(!RxSamplerReset)
                    begin
                        RxSampleNo <= 2'd2;
                    end
                else
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
        if(!Reset)
            RxStrobeReg <= 2'b00;
        else
            RxStrobeReg <= { RxStrobeReg[0], RxSampleReady };

    // RX state machine
    localparam RX_IDLE  = 3'd0,
               RX_START = 3'd1,
               RxData  = 3'd2,
               RX_STOP  = 3'd3,
               RX_FULL  = 3'd4,
               RX_ERROR = 3'd5;
    reg  [2:0] RxState = 3'd0;
    reg  [7:0] RxData  = 8'b00000000;
    reg  [2:0] RxBitNo = 3'd0;
    
    always @(posedge Clk or negedge Reset)
        if(!Reset) begin
            RxSamplerReset <= 1'b0;
            RxState <= RX_IDLE;
            RxData <= 8'b00000000;
            RxBitNo <= 3'd0;
        end else case(RxState)
            RX_IDLE:
                if(!RxWire) begin
                    RxSamplerReset <= 1'b1;
                    RxState <= RX_START;
                end
            RX_START:
                if(rx_strobe)
                    RxState <= RxData;
            RxData:
                if(rx_strobe)
                    begin
                        if(RxBitNo == 3'd7)
                            begin
                                RxState <= RX_STOP;
                            end
                        RxData <= {RxSample1, RxData[7:1]};
                        RxBitNo <= RxBitNo + 3'd1;
                    end
            RX_STOP:
                if(rx_strobe) begin
                    RxSamplerReset <= 1'b0;
                    if(RxSample1 == 1'b0)
                        begin
                            RxState <= RX_ERROR;
                        end
                    else
                        begin
                            RxState <= RX_FULL;
                        end
                end
            RX_FULL:
                if(RxEnable)
                    begin
                        RxState <= RX_IDLE;
                    end
                else if(!RxWire)
                    begin
                        RxState <= RX_ERROR;
                    end
        endcase

    assign RxDataOutput  = RxData;
    assign RxReady = (RxState == RX_FULL);
    assign RxError = (RxState == RX_ERROR);

    // TX sampler
    reg TxSamplerReset = 1'b0;
    wire TxSamplerClockEnable;
    FreqDivider #(
        .FREQUENCY_IN(CLOCK_FREQUENCY),
        .FREQUENCY_OUT(CLOCK_FREQUENCY / ((CLOCK_FREQUENCY / (BAUD_RATE * 3) / 2) * 2) / 3),
        .INITIAL_CLOCK_PHASE(1'b0)
    ) TxSamplerClockEnable_div (
        .Reset(TxSamplerReset),
        .Clk(Clk),
        .ClkOutput(TxSamplerClockEnable)
    );

    // TX strobe generator
    reg [1:0] TxStrobeReg = 2'b00;
    wire TxStrobe = (TxStrobeReg == 2'b01);
    
    always @(posedge Clk or negedge Reset)
        if(!Reset)
            begin
                TxStrobeReg <= 2'b00;
            end
        else
            begin
                TxStrobeReg <= {TxStrobeReg[0], TxSamplerClockEnable};
            end
                
    // TX state machine
    localparam TX_IDLE  = 3'd0,
               TX_START = 3'd1,
               TxData  = 3'd2,
               TX_STOP0 = 3'd3,
               TX_STOP1 = 3'd4;
               
    reg [2:0] TxState = 3'd0;
    reg [7:0] TxData  = 8'b00000000;
    reg [2:0] TxBitNo = 3'd0;
    reg TxBuf   = 1'b1;
    
    always @(posedge Clk or negedge Reset)
        if(!Reset) begin
            TxSamplerReset <= 1'b0;
            TxState <= 3'd0;
            TxData <= 8'b00000000;
            TxBitNo <= 3'd0;
            TxBuf <= 1'b1;
        end else case(TxState)
            TX_IDLE:
                if(TxEnable)
                    begin
                        TxSamplerReset <= 1'b1;
                        TxState <= TX_START;
                        TxData <= TxDataInput;
                    end
            TX_START:
                if(TxStrobe)
                    begin
                        TxState <= TxData;
                        TxBuf <= 1'b0;
                    end
            TxData:
                if(TxStrobe)
                    begin
                        if(TxBitNo == 3'd7)
                            begin
                                TxState <= TX_STOP0;
                            end
                        TxData <= {1'b0, TxData[7:1]};
                        TxBitNo <= TxBitNo + 3'd1;
                        TxBuf <= TxData[0];
                    end
            TX_STOP0:
                if(TxStrobe)
                    begin
                        TxState <= TX_STOP1;
                        TxBuf <= 1'b1;
                    end
            TX_STOP1:
                if(TxStrobe)
                    begin
                        TxSamplerReset <= 1'b0;
                        TxState <= TX_IDLE;
                    end
        endcase

    assign TxWire = TxBuf;
    assign TxReady = (TxState == TX_IDLE);

endmodule