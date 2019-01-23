`include "../FreqDivider/FreqDivider.v"
`default_nettype none

module ClockDiv #(
        parameter FREQ_I  = 2,
        parameter FREQ_O  = 1,
        parameter PHASE   = 1'b0,
        parameter MAX_PPM = 1_000_000
    ) (
        input  wire reset,
        input  wire clk_i,
        output wire clk_o
    );

    // This calculation always rounds frequency up.
    localparam INIT = FREQ_I / FREQ_O / 2 - 1;
    localparam ACTUAL_FREQ_O = FREQ_I / ((INIT + 1) * 2);
    localparam PPM = 64'd1_000_000 * (ACTUAL_FREQ_O - FREQ_O) / FREQ_O;
    /*initial $display({"ClockDiv #(.FREQ_I(%d), .FREQ_O(%d),\n",
                      "           .INIT(%d), .ACTUAL_FREQ_O(%d), .PPM(%d))"},
                     FREQ_I, FREQ_O, INIT, ACTUAL_FREQ_O, PPM);*/
    generate
        if(INIT < 0)
            _ERROR_FREQ_TOO_HIGH_ error();
        if(PPM > MAX_PPM)
            _ERROR_FREQ_DEVIATION_TOO_HIGH_ error();
    endgenerate

    reg [$clog2(INIT):0] cnt = 0;
    reg                  clk = PHASE;
    always @(posedge clk_i or negedge reset)
        if(!reset) begin
            cnt <= 0;
            clk <= PHASE;
        end else begin
            if(cnt == 0) begin
                clk <= ~clk;
                cnt <= INIT;
            end else begin
                cnt <= cnt - 1;
            end
        end

    assign clk_o = clk;

endmodule

module UartRx__EXPERIMENTAL
#(
    parameter CLOCK_FREQUENCY  = 1_000_000,
    parameter BAUD_RATE  = 9600,
    parameter WAIT = 3'b000,
    parameter SNS1 = 3'b100,
    parameter SNS2 = 3'b101,
    parameter SNS3 = 3'b110,
    parameter SNSX = 3'b111,
    parameter READ = 3'b001,
    parameter DONE = 3'b010
)
(
  input wire Clk,
  input wire Reset,
  input wire RxWire,
  input wire RxEnable,
  output wire [7:0] RxDataOutput,
  output wire RxReady,
  output wire RxError
);

/* Count to 32 (8 bits x 4 samples )*/
reg       [4:0] count;
reg       [2:0] state;
reg       [2:0] state_nxt;

reg       [2:0] rx_shifter;
reg       [7:0] rx_byte_ff;
wire            rx_sample;

assign RxError = 0;

wire SamplerClk;

ClockDiv #(
    .FREQ_I(CLOCK_FREQUENCY),
    .FREQ_O(BAUD_RATE * 4),
    .PHASE(1'b1),
    .MAX_PPM(50_000)
) rx_sampler_clk_div (
    .reset(Reset),
    .clk_i(Clk),
    .clk_o(SamplerClk)
);

/* When sampling RX if we got 2 highs in a row our sample 
   is high! */
assign rx_sample = (rx_shifter[2] && rx_shifter[1]) || 
                   (rx_shifter[1] && rx_shifter[0]);

assign RxDataOutput = rx_byte_ff;
assign RxReady = state == DONE;

/* FSM Next State Derivation */
always @ (*)
begin
  case (state)
    WAIT: if (!RxWire)  /* As long was we are high stay waiting */
        state_nxt = SNS1;
      else          
        state_nxt = WAIT;
    SNS1: if (!RxWire)
        state_nxt = SNS2;
      else
        state_nxt = WAIT;
    SNS2: if (!RxWire)  /* If we get 4 lows in a row we got to read */
        state_nxt = SNSX;
      else
        state_nxt = WAIT;
    SNSX:
      state_nxt = READ;
    READ: if (count == 5'b11111) /* When read count is full, go back to wait */
        state_nxt = DONE;
      else
        state_nxt = READ;
    DONE:    state_nxt = WAIT;
    default: state_nxt = WAIT;
  endcase
end

/* Sense the start bit on posedge and negedge */
always @ (posedge SamplerClk or negedge Reset)
begin
   if (!Reset) 
    begin
      state <= WAIT;
      count <= 5'd0;
      rx_shifter <= 3'd0;
    end
   else
    begin
      state <= state_nxt;
      if (state == READ) begin
        rx_shifter <= {RxWire, rx_shifter[2:1]};
        count <= count + 1'b1;
      end
      else 
      begin
        rx_shifter <= 3'd0;
        count <= 5'd0;
      end
    end
end

/* If we are reading, stample the RX bits 
   every 3 samples shift it into RX byte */
always @ (posedge SamplerClk or negedge Reset)
begin
   if (!Reset) 
      rx_byte_ff <= 8'd0;
   else
     if ((state == READ) && count[1] && count[0])  /* When we are at count 3, sample the shift register */
       rx_byte_ff <= {rx_sample, rx_byte_ff[7:1]};
     else 
       rx_byte_ff <= rx_byte_ff;
end

endmodule

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
    
    /*FreqDivider #(
        .FREQUENCY_IN(CLOCK_FREQUENCY),
        .FREQUENCY_OUT(BAUD_RATE * 3),
        .INITIAL_CLOCK_PHASE(1'b1)
    ) rx_sampler_clk_div (
        .Reset(RxSamplerReset),
        .Clk(Clk),
        .ClkOutput(RxSamplerClockEnable)
    );*/
    
    ClockDiv #(
        .FREQ_I(CLOCK_FREQUENCY),
        .FREQ_O(BAUD_RATE * 3),
        .PHASE(1'b1),
        .MAX_PPM(50_000)
    ) rx_sampler_clk_div (
        .reset(RxSamplerReset),
        .clk_i(Clk),
        .clk_o(RxSamplerClockEnable)
    );

    reg [2:0] RxSample = 3'b000;
    wire RxSample1 = ( RxSample == 3'b111 || RxSample == 3'b110 || RxSample == 3'b101 || RxSample == 3'b011 );
    
    always @(posedge RxSamplerClockEnable or negedge RxSamplerReset)
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
    
    always @(posedge RxSamplerClockEnable or negedge RxSamplerReset)
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