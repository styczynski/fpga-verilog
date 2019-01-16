`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_SYNCHRONIZER_V
`define LIB_STYCZYNSKI_SYNCHRONIZER_V

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Input synchronizer
 * 
 *
 * MIT License
 */
module Synchronizer
#(
  parameter NUM_STAGES = 2
) (
  output Output,
  input  Input,
  input  Clk
);
 
  reg [NUM_STAGES:1] SyncReg;
 
  always @(posedge Clk)
  begin
    SyncReg <= { SyncReg[NUM_STAGES-1:1], Input };
  end
 
  assign Output = SyncReg[NUM_STAGES];
 
endmodule

`endif