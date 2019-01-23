`include "../../components/Debouncer/Debouncer.v"
`include "../../components/Synchronizer/Synchronizer.v"
`include "GraphicCard.v"

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
    output wire VGA_HSYNC,
    output wire VGA_VSYNC,
    output wire VGA_R,
    output wire VGA_G,
    output wire VGA_B,
    input wire IO_RXD,
    output wire IO_TXD
);

	 
    GraphicCard card (
        .Clk(Clk),
        .LED(LED),
        .LEDDisp3(IO_LED1[0:6]),
        .LEDDisp2(IO_LED2[0:6]),
        .LEDDisp1(IO_LED3[0:6]),
        .LEDDisp0(IO_LED4[0:6]),
        .Switch(Switch),
        .Rst(0),
        .VgaHSync(VGA_HSYNC),
        .VgaVSync(VGA_VSYNC),
        .VgaColorR(VGA_R),
        .VgaColorG(VGA_G),
        .VgaColorB(VGA_B),
        .UartRxWire(IO_RXD),
        .UartTxWire(IO_TXD)
    );

endmodule