`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_SIGN_DIVIDER_V
`define LIB_STYCZYNSKI_SIGN_DIVIDER_V

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Divider for integer division.
 * Integers are INPUT_BIT_WIDTH bits width.
 * The divider supports signed and unsigned inputs.
 *
 * If you want to use only unisgned mode please set input Sign to 0.
 * If you want to use signed mode please set input Sign to 1.
 * 
 *
 * MIT License
 */
module SignDivider
#(
    parameter INPUT_BIT_WIDTH = 8
)
(
    input Clk,
    input Sign,
    input [INPUT_BIT_WIDTH-1:0] Dividend,
    input [INPUT_BIT_WIDTH-1:0] Divider,
    output reg [INPUT_BIT_WIDTH-1:0] Quotient,
    output wire [INPUT_BIT_WIDTH-1:0] Remainder,
    output wire Ready
);

    reg [INPUT_BIT_WIDTH-1:0] QuotientBuf;
    reg [INPUT_BIT_WIDTH*2-1:0] DividendBuf;
    reg [INPUT_BIT_WIDTH*2-1:0] DividerBuf;
    reg [INPUT_BIT_WIDTH*2-1:0] Diff;
    reg [5:0] Bit; 
    reg OutputNegative;

    assign Ready = !Bit;
    assign Remainder = (!OutputNegative)?
      (DividendBuf[INPUT_BIT_WIDTH-1:0]):
      (~DividendBuf[INPUT_BIT_WIDTH-1:0] + 1'b1);


    initial Bit = 0;
    initial OutputNegative = 0;

    always @(posedge Clk)
        if(Ready)
            begin
                Bit = INPUT_BIT_WIDTH;
                Quotient = 0;
                QuotientBuf = 0;
                DividendBuf = (!Sign || !Dividend[INPUT_BIT_WIDTH-1])?
                    (
                        {{INPUT_BIT_WIDTH{1'd0}},Dividend}
                    ):( 
                        {{INPUT_BIT_WIDTH{1'd0}},~Dividend + 1'b1}
                    );
                DividerBuf = (!Sign || !Divider[INPUT_BIT_WIDTH-1])?
                    (
                        {1'b0,Divider,{(INPUT_BIT_WIDTH-1){1'd0}}}
                    ):( 
                        {1'b0,~Divider + 1'b1,{(INPUT_BIT_WIDTH-1){1'd0}}}
                    );

                OutputNegative = (
                        Sign &&
                        (
                            (Divider[INPUT_BIT_WIDTH-1] && !Dividend[INPUT_BIT_WIDTH-1]) 
                            || (!Divider[INPUT_BIT_WIDTH-1] && Dividend[INPUT_BIT_WIDTH-1])
                        )
                    );
        end 
        else if(Bit > 0)
            begin
                Diff = DividendBuf - DividerBuf;
                QuotientBuf = QuotientBuf << 1;

                if(!Diff[INPUT_BIT_WIDTH*2-1])
                    begin
                        DividendBuf = Diff;
                        QuotientBuf[0] = 1'd1;
                    end

                Quotient = (!OutputNegative)?
                    (QuotientBuf):
                    (~QuotientBuf + 1'b1);

                DividerBuf = DividerBuf >> 1;
                Bit = Bit - 1'b1;
        end
endmodule

`endif