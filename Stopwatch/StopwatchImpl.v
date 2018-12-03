`include "Stopwatch.v"

module StopwatchImpl
(
    input Clk,
    input [3:0] Btn,
    input [4:0] Switch,
    output wire [2:0] LED,
    output wire [3:30] IO_P2
);

    Stopwatch stopwatch (
        .Clk(Clk),
        .Reset(Btn[0]),
        .Stop(Btn[1]),
        .Up(Btn[2]),
        .Down(Btn[3]),
        .Speed(Switch),
        .ModeOutput(LED),
        .LEDDisp3(IO_P2[3:9]),
        .LEDDisp2(IO_P2[10:16]),
        .LEDDisp1(IO_P2[21:27]),
        .LEDDisp0(IO_P2[31:37])
    );

endmodule
