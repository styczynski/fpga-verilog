`timescale 1ns / 1ps
`include "../../utils/test.v"
`include "MiniCalc2.v"
`include "../../components/SegmentLedHexEncoder/SegmentLedHexEncoder.v"

`define assertDigits(d1, d2, d3, d4) \
        `assert(Digit1, d1); \
        `assert(Digit2, d2); \
        `assert(Digit3, d3); \
        `assert(Digit4, d4);
       
`define assertDigitsUndefined(value) \
       `assert(DigitUndefined1, value); \
       `assert(DigitUndefined2, value); \
       `assert(DigitUndefined3, value); \
       `assert(DigitUndefined4, value);
       
`define assertDigitsValueRaw(value) \
       `assertDigits((value/1000)%10, (value/100)%10, (value/10)%10, (value)%10); \
       `assertDigitsUndefined(0);

`define assertDigitsValueHi(low, hi) \
        `assertDigitsValueRaw(low); \
        Btn[0] = 1; #2; \
        `assertDigitsValueRaw(hi); \
        Btn[0] = 0; #2;
        
`define assertDigitsValue(value) \
        `assertDigitsValueHi(value, 0);
       
`define do_push(value) \
        wait(Ready == 1); \
        Btn[1] = 1; Switch = value; \
        wait(Ready == 0); \
        wait(Ready == 1); \
        Btn[1] = 0; Switch = 0;
       
`define do_op(code) \
        wait(Ready == 1); \
        Btn[3] = 1; Switch = code; \
        wait(Ready == 0); \
        wait(Ready == 1); \
        Btn[3] = 0; Switch = 0;
        
`define do_add \
        `do_op(0);
        
`define do_sub \
        `do_op(1);
        
`define do_mul \
        `do_op(2);
 
`define do_div \
        `do_op(3); 

`define do_mod \
        `do_op(4);

`define do_pop \
        `do_op(5);     

`define do_copy \
        `do_op(6);
        
`define do_swap \
        `do_op(7);
        
/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Test for MiniCalc2 module
 *
 * MIT License
 */
module TestMiniCalc
#(
    parameter STACK_TEST_MAX_SIZE = 512
);

    // Inputs
    `defClock(Clk, 2);
    reg [3:0] Btn;
    reg [7:0] Switch;
    reg IO_RXD;

    // Outputs
    wire [0:7] LED;
    wire [0:6] IO_LED1;
    wire [0:6] IO_LED2;
    wire [0:6] IO_LED3;
    wire [0:6] IO_LED4;
    wire IO_TXD;
    wire Ready;
    
    // LED to digits
    wire [3:0] Digit1;
    wire DigitUndefined1;
    wire [3:0] Digit2;
    wire DigitUndefined2;
    wire [3:0] Digit3;
    wire DigitUndefined3;
    wire [3:0] Digit4;
    wire DigitUndefined4;

    // Instantiate the Unit Under Test (UUT)
    MiniCalc2 uut (
        .Clk(Clk),
        .UartTxWire(IO_TXD),
        .UartRxWire(IO_RXD),
        .Switch(Switch),
        .BtnPushLow(Btn[1]),
        .BtnPushHi(Btn[2]),
        .BtnExecute(Btn[3]),
        .BtnOutputHi(Btn[0]),
        .LED(LED),
        .LEDDisp3(IO_LED1[0:6]),
        .LEDDisp2(IO_LED2[0:6]),
        .LEDDisp1(IO_LED3[0:6]),
        .LEDDisp0(IO_LED4[0:6]),
        .Ready(Ready)
    );
    
    SegmentLedHexEncoder encoder1 (
        .Segments(IO_LED1),
        .HexDigit(Digit1),
        .Undefined(DigitUndefined1)
    );
    
    SegmentLedHexEncoder encoder2 (
        .Segments(IO_LED2),
        .HexDigit(Digit2),
        .Undefined(DigitUndefined2)
    );
    
    SegmentLedHexEncoder encoder3 (
        .Segments(IO_LED3),
        .HexDigit(Digit3),
        .Undefined(DigitUndefined3)
    );
    
    SegmentLedHexEncoder encoder4 (
        .Segments(IO_LED4),
        .HexDigit(Digit4),
        .Undefined(DigitUndefined4)
    );
    
    integer k;
    `startTest("MiniCalc")
    
        // Initialize Inputs
        Clk = 0;
        Btn = 0;
        Switch = 0;
        IO_RXD = 0;
        #500;
       
        `describe("Initially stack is empty");
            `assertDigitsUndefined(1);
        
        `describe("Basic push/pop test");
            `do_push(0);
            `do_push(66);
            `do_push(8);
            `do_push(99);
            `do_push(5);
            `do_push(13);
            
            `do_pop; `assertDigitsValue(5);
            `do_pop; `assertDigitsValue(99);
            `do_pop; `assertDigitsValue(8);
            `do_pop; `assertDigitsValue(66);
            `do_pop; `assertDigitsValue(0);
            `do_pop; `assertDigitsUndefined(1);
        
        `describe("Initial stack pushes");
            `do_push(42);
            `do_push(120);
            `do_push(99);
            `do_push(100);
            `do_push(1);
        
        `describe("Check adding");
            `do_add; `assertDigitsValue(101);
            `do_add; `assertDigitsValue(200);
        
        `describe("Check substraction");
            /* Now stack should be equal to [ 42, 120, 200 ] */
            /* Perform more pushes */
            `do_push(11);
            `do_push(55);
            `do_push(5);
            
            /* Substract: 55 - 5 */
            `do_sub; `assertDigitsValue(50);
            `assert(LED[7], 0);
            `do_sub; `assertDigitsValue(50);
            `assert(LED[7], 1);
            
            /* Stack should be now equal to [ 42, 120, 200, 11, 50 ] */
            `do_pop; `assertDigitsValue(11);
        
        `describe("Check multiplication");
            /* Multiplicate elements */
            `do_mul;
            $display("here = %d %d %d %d", Digit1, Digit2, Digit3, Digit4);
            `assertDigitsValue(2200);
            /* Now we should have 120*200 = 264000 which is two 2-byte chunks: Bin< 0...0 0100, 0000 0111 0100 0000‬ > = ‭Dec< 4, 1856 >*/
            `do_mul; `assertDigitsValueHi(1856, 4);
            /* Now we got 42*264000 = 11088000 which is two 2-byte chunks: Dec< ‭10101001, 12416 > */
            `do_mul; `assertDigitsValueHi(2416, 169);
            
            /* Stack is empty */
            `do_pop; `assertDigitsUndefined(1);
        
        `describe("Check err flag on pop underflow");
            `do_push(7);
            `assert(LED[7], 0);
            `do_pop;
            `assert(LED[7], 0);
            `assertDigitsUndefined(1);
            `do_pop;
            `assert(LED[7], 1);
            `assertDigitsUndefined(1);
        
         `describe("Check err flag on add/div/mod/sub/mul/swap/copy underflow");
            
            `do_push(19);
            
            `assert(LED[7], 0);
            `do_add;
            `assert(LED[7], 1); `assertDigitsValue(19); `do_push(1); `do_pop;
            
            `assert(LED[7], 0);
            `do_div;
            `assert(LED[7], 1); `assertDigitsValue(19); `do_push(1); `do_pop;
            
            `assert(LED[7], 0);
            `do_mod;
            `assert(LED[7], 1); `assertDigitsValue(19); `do_push(1); `do_pop;
            
            `assert(LED[7], 0);
            `do_sub;
            `assert(LED[7], 1); `assertDigitsValue(19); `do_push(1); `do_pop;
            
            `assert(LED[7], 0);
            `do_mul;
            `assert(LED[7], 1); `assertDigitsValue(19); `do_push(1); `do_pop;
            
            `assert(LED[7], 0);
            `do_swap;
            `assert(LED[7], 1); `assertDigitsValue(19); `do_push(1); `do_pop;
            
            `do_pop;
        
        `describe("Check err flag on 1024 / 0");
            `do_push(1024); `do_push(0);
            `assert(LED[7], 0);
            `do_div;
            `assert(LED[7], 1);
            `do_pop; `do_pop;
            `assert(LED[7], 0);
            `assertDigitsUndefined(1);
        
        `describe("Check err flag on 0 / 0");
            `do_push(0); `do_push(0);
            `assert(LED[7], 0);
            `do_div;
            `assert(LED[7], 1);
            `do_pop; `do_pop;
            `assert(LED[7], 0);
            `assertDigitsUndefined(1);
        
        `describe("Check err flag on 12 mod 0");
            `do_push(12); `do_push(0);
            `assert(LED[7], 0);
            `do_mod;
            `assert(LED[7], 1);
            `do_pop; `do_pop;
            `assert(LED[7], 0);
            `assertDigitsUndefined(1);
        
        `describe("Check err flag on 0 mod 0");
            `do_push(0); `do_push(0);
            `assert(LED[7], 0);
            `do_mod;
            `assert(LED[7], 1);
            `do_pop; `do_pop;
            `assert(LED[7], 0);
            `assertDigitsUndefined(1);
        
        `describe("Check copy");
            `do_push(42); `assertDigitsValue(42);
            `do_copy; `assertDigitsValue(42);
            `do_pop; `assertDigitsValue(42);
            `do_pop; `assertDigitsUndefined(1);
        
        `describe("Check swap");
            `do_push(4);
            `do_push(5);
            `do_push(6);
            `do_push(7);
            
            `do_swap; `assertDigitsValue(6);     /*  [ 4, 5, 7, 6 ] <--  */
            `do_pop; `assertDigitsValue(7);      /*  [ 4, 5, 7 ]    <--  */
            `do_swap; `assertDigitsValue(5);     /*  [ 4, 7, 5 ]    <--  */
            `do_pop; `assertDigitsValue(7);      /*  [ 4, 7 ]       <--  */
            `do_swap; `assertDigitsValue(4);     /*  [ 7, 4 ]       <--  */
            `do_pop; `assertDigitsValue(7);      /*  [ 7 ]          <--  */
            `do_pop; `assertDigitsUndefined(1);  /*  [ ]            <--  */
        
        `describe("Check stack capacity");
        
            /* Push STACK_TEST_MAX_SIZE elements on the stack */
            `assertDigitsUndefined(1);
            k = 0;
            for (int i=0; i<STACK_TEST_MAX_SIZE-1; i=i+1) begin
                k = k + 1;
                if(k>=250)
                    begin
                        k = 0;  
                    end
                `do_push(k);
                `assertDigitsValue(k);
                `assert(LED[7], 0);
            end
            
            /* This will be the STACK_TEST_MAX_SIZE-th number on the stack we should get overflow error */
            `assert(LED[7], 0);
            `do_push(44);
            `assert(LED[7], 1);
            
            /* Take STACK_TEST_MAX_SIZE-1 elements from the stack */
            for (int i=0; i<STACK_TEST_MAX_SIZE-2; i=i+1) begin
                `do_pop;
                `assertDigitsUndefined(0);
                `assert(LED[7], 0);
            end
            
            /* Take last element */
            `do_pop;
            `assertDigitsUndefined(1);
            `assert(LED[7], 0);
            
    `endTest
      
endmodule

