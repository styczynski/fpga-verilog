`include "MiniCalc2.v"
`include "../Debouncer/Debouncer.v"

module MiniCalc2Impl
(
    input Clk,
    input [3:0] Btn,
    input [6:0] Switch,
    output wire [3:0] LED,
    output wire [0:6] IO_LED1,
	 output wire [0:6] IO_LED2,
	 output wire [0:6] IO_LED3,
	 output wire [0:6] IO_LED4,
	 input wire IO_RXD,
	 output wire IO_TXD
);

	 wire [3:0] BtnDebounced;
    wire BtnExtDebounced;
	 
    debounce debounce0(
	     .Clk(Clk),
		  .Input(!Btn[0]),
		  .Output(BtnDebounced[0])
	 ); 
	 
	 debounce debounce1(
	     .Clk(Clk),
		  .Input(!Btn[1]),
		  .Output(BtnDebounced[1])
	 );
	 
	 debounce debounce2(
	     .Clk(Clk),
		  .Input(!Btn[2]),
		  .Output(BtnDebounced[2])
	 );
	 
	 debounce debounce3(
	     .Clk(Clk),
		  .Input(!Btn[3]),
		  .Output(BtnDebounced[3])
	 );
	 
	 debounce debounceExtBtn(
	     .Clk(Clk),
		  .Input(Switch[6]),
		  .Output(BtnExtDebounced)
	 );

    MiniCalc2 miniCalc2 (
        .Clk(Clk),
		  .UartTxWire(IO_TXD),
		  .UartRxWire(IO_RXD),
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