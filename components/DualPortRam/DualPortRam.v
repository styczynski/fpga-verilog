`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_DUAL_PORT_RAM_V
`define LIB_STYCZYNSKI_DUAL_PORT_RAM_V

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Synchronious dual-port RAM
 * 
 *
 * MIT License
 */
module DualPortRam #(
    parameter DATA_WIDTH = 72,
    parameter ADDR_WIDTH = 10
) (
    input wire Clk,
    input wire WriteA,
    input wire [ADDR_WIDTH-1:0] AddrA,
    input wire [DATA_WIDTH-1:0] InputA,
    output reg [DATA_WIDTH-1:0] OutputA,
    input wire WriteB,
    input wire [ADDR_WIDTH-1:0] AddrB,
    input wire [DATA_WIDTH-1:0] InputB,
    output reg [DATA_WIDTH-1:0] OutputB
);
 
reg [DATA_WIDTH-1:0] Memory [0:(1<<ADDR_WIDTH)-1];
 
// Port A
always @(posedge Clk) begin
    OutputA <= Memory[AddrA];
    if(WriteA) begin
        OutputA <= InputA;
        Memory[AddrA] <= InputA;
    end
end
 
// Port B
always @(posedge Clk) begin
    OutputB <= Memory[AddrB];
    if(WriteB)
        begin
            OutputB <= InputB;
            Memory[AddrB] <= InputB;
        end
end
 
endmodule

`endif