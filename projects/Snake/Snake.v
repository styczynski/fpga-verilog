`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_SNAKE_V
`define LIB_STYCZYNSKI_SNAKE_V

`include "../../components/Bin2BCDConverter/Bin2BCDConverter_4.v"
`include "../../components/SegmentLedHexDecoder/SegmentLedHexDecoder.v"
`include "../../components/Uart/UartRx.v"
`include "../../components/Uart/UartTx.v"
`include "../../components/LUA/LUA.v"
`include "../../components/Ram/Ram.v"

`include "vga800x600.v"

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Snake
 * 
 *
 * MIT License
 */
module Snake #(
     parameter INPUT_BIT_WIDTH = 32
)
(
    input wire Clk,
    output reg [0:7] LED,
    output wire [0:6] LEDDisp3,
    output wire [0:6] LEDDisp2,
    output wire [0:6] LEDDisp1,
    output wire [0:6] LEDDisp0,
    input wire [7:0] Switch,
    input wire Rst,
    output wire VgaHSync,
    output wire VgaVSync,
    output wire VgaColorR,
    output wire VgaColorG,
    output wire VgaColorB,
    input wire UartRxWire,
    output wire UartTxWire
);


    
    always @(posedge Clk)
    begin
        
    end
    
endmodule


`endif