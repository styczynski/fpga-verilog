`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI
`define LIB_STYCZYNSKI

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 *
 *
 * MIT License
 */

`include "ClaAdder/ClaAdder.v"
`include "ClaAdder/TestClaAdder.v"

`include "SignAddSub/SignAddSub.v"
`include "SignAddSub/TestSignAddSub.v"

`include "SignDivider/SignDivider.v"
`include "SignDivider/TestSignDivider.v"

`include "UnsignDivider/UnsignDivider.v"
`include "UnsignDivider/TestUnsignDivider.v"

`include "SimpleALU/SimpleALU.v"
`include "SimpleALU/TestSimpleALU.v"

`include "RegMux/RegMux.v"

`include "MiniCalc/MiniCalc.v"
`include "MiniCalc/MiniCalcImpl.v"
`include "MiniCalc/TestMiniCalc.v"

`include "UnsignDividerComb/UnsignDividerComb.v"
`include "UnsignDividerComb/TestUnsignDividerComb.v"

`include "UnsignAddSub/UnsignAddSub.v"
`include "UnsignAddSub/TestUnsignAddSub.v"

`include "MinMax/MinMax.v"
`include "MinMax/TestMinMax.v"

`endif