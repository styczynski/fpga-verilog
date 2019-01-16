`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_RAM_V
`define LIB_STYCZYNSKI_RAM_V

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Synchronious single-port RAM
 * 
 *
 * MIT License
 */
module RAM #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
) (
    input wire Clk,
    input wire [ADDR_WIDTH-1:0] Addr,
    input wire Write,
    input wire [DATA_WIDTH-1:0] Input,
    output reg [DATA_WIDTH-1:0] Output
);

    reg [DATA_WIDTH-1:0] Memory [0:(1<<ADDR_WIDTH)-1]; 
    
    always @(posedge Clk)
    begin
        if(Write)
            begin
                Memory[Addr] <= Input;
            end
        else
            begin
                Output <= Memory[Addr];
            end     
    end
endmodule

`endif