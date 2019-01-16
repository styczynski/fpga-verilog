`include "../../components/Debouncer/Debouncer.v"
`include "Stopwatch.v"

module StopwatchImpl
(
    input Clk,
    input [3:0] Btn,
    input [6:0] Switch,
    output wire [3:0] LED,
    output wire [0:6] IO_LED1,
    output wire [0:6] IO_LED2,
    output wire [0:6] IO_LED3,
    output wire [0:6] IO_LED4
);

    wire [3:0] BtnDebounced;
    wire BtnExtDebounced;
     
    Debouncer debounce0(
        .Clk(Clk),
        .Input(!Btn[0]),
        .Output(BtnDebounced[0])
    );
     
    Debouncer debounce1(
        .Clk(Clk),
        .Input(!Btn[1]),
        .Output(BtnDebounced[1])
    );
     
    Debouncer debounce2(
        .Clk(Clk),
        .Input(!Btn[2]),
        .Output(BtnDebounced[2])
    );
     
    Debouncer debounce3(
        .Clk(Clk),
        .Input(!Btn[3]),
        .Output(BtnDebounced[3])
    );
     
    Debouncer debounceExtBtn(
        .Clk(Clk),
        .Input(Switch[6]),
        .Output(BtnExtDebounced)
    );

    Stopwatch stopwatch (
        .Clk(Clk),
        .Clk2(BtnExtDebounced),
        .ClkSel(Switch[5]),
        .Reset(BtnDebounced[0]),
        .Stop(BtnDebounced[1]),
        .Up(BtnDebounced[2]),
        .Down(BtnDebounced[3]),
        .Speed(Switch[4:0]),
        .ModeOutput0(LED[0]),
        .ModeOutput1(LED[1]),
        .ModeOutput2(LED[2]),
        .ClkOutput(LED[3]),
        .LEDDisp3(IO_LED1[0:6]),
        .LEDDisp2(IO_LED2[0:6]),
        .LEDDisp1(IO_LED3[0:6]),
        .LEDDisp0(IO_LED4[0:6])
    );

endmodule