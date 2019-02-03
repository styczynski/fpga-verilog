# 1st Assignment - Simple push-button calculator

## About

This is implementation of 4-bit push-button calculator.

## Operation

The calculator has the following data inputs:

* `Switch[7:4]` - Input A (unsigned)
* `Switch[3:0]` - Input B (unsigned)

You specify the operation to execute by pressing the input buttons:

* `Btn[0]` is pressed - The calculator shows `a+b` on `LED[7:4]` and `a-b` on `LED[3:0]`
* `Btn[1]` is pressed - The calculator shows `min(a, b)` on `LED[7:4]` and `max(a, b)` on `LED[3:0]`
* `Btn[2]` is pressed - The calculator shows 8-bit result of multiplication `a * b` on `LED[7:0]`
* `Btn[3]` is pressed - The calculator shows `a / b` on `LED[7:4]` and `a % b` on `LED[3:0]` (in case when `b==0` the result can be anything)
* No button is pressed - The LEDs are disabled
* Two or more buttons are pressed - The LEDs state is not specified

As the part of the assignemnt there was requirement to write own combinational module for integer division.

## Hardware implementation

The entire chip was written in Verilog. The entrypoint is the `MiniCalcImpl.v` file.

It was tested on Xilinx Spartan-6 chip (code build using ISE suite).
