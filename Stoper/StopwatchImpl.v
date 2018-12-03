`include "MiniCalc.v"

module MiniCalcImpl
(
    input Clk,
    input [0:3] Btn,
    input [0:7] Switch,
    output wire [0:7] LED
);

    MiniCalc #(
        .INPUT_BIT_WIDTH(4)
    ) calc(
        .Clk(Clk),
        .Instruction(Btn),
        .InputA(Switch[4:7]),
        .InputB(Switch[0:3]),
        .OutputA(LED[4:7]),
        .OutputB(LED[0:3])
    );

endmodule
