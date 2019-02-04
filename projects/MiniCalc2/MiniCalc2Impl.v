`include "../../components/Debouncer/Debouncer.v"
`include "../../components/Synchronizer/Synchronizer.v"
`include "MiniCalc2.v"

module MiniCalc2Impl
(
    input wire Clk,
    input wire [3:0] Btn,
    input wire [7:0] Switch,
    output wire [0:7] LED,
    output wire [0:6] IO_LED1,
    output wire [0:6] IO_LED2,
    output wire [0:6] IO_LED3,
    output wire [0:6] IO_LED4,
    input wire IO_RXD,
    output wire IO_TXD
);

    wire [3:0] BtnDebounced;
    wire [7:0] SwitchSync;
     
    genvar gi;
    generate
        for (gi=0; gi<=7; gi=gi+1) begin : genSynchronizer
            Synchronizer (
                .Clk(Clk),
                .Input(Switch[gi]),
                .Output(SwitchSync[gi])
            );
        end
    endgenerate
    
    generate
        for (gi=0; gi<=3; gi=gi+1) begin : genDebouncer
            Debouncer debounce0(
                .Clk(Clk),
                .Input(!Btn[gi]),
                .Output(BtnDebounced[gi])
            );
        end
    endgenerate
    
    MiniCalc2 miniCalc2 (
        .Clk(Clk),
        .UartTxWire(IO_TXD),
        .UartRxWire(IO_RXD),
        .Switch(SwitchSync),
        .BtnPushLow(BtnDebounced[1]),
        .BtnPushHi(BtnDebounced[2]),
        .BtnExecute(BtnDebounced[3]),
        .BtnOutputHi(!Btn[0]),
        .LED(LED),
        .LEDDisp3(IO_LED1[0:6]),
        .LEDDisp2(IO_LED2[0:6]),
        .LEDDisp1(IO_LED3[0:6]),
        .LEDDisp0(IO_LED4[0:6])
    );

endmodule