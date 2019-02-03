# 2nd Assignment - Simple push-button stopwatch

## About

This is implementation of a simple stopwatch.

## Operation

The stopwatch should display current value (integer in range 0-9999) on LEDs.
After startup the stoper should display 0 and be stopped.

The buttons have the following functions:

* `Btn[3]` - Resets the stopwatch to its initial state
* `Btn[2]` - Stops the stopwatch
* `Btn[1]` - Switches the stopwatch to couting towards positive infinity
* `Btn[0]` - Swithces the stopwatch to counting towards negative infinity

When the stopwatch is running the swithces `Switch[4:0]` selects the counting speed level.
The stopwatch should increment/decrement its counter with speed beeing equal to `CLOCK_SIGNAL_FREQUENCY / ( 2 ** Switch[4:0] )`.

The switch `Switch[7]` selects the source of the clock signal:

* If it's on then stopwatch should use internal oscillator (Spartan-6 100MHz clock)
* If it's off then stopwatch should use external clock signal exposed on pin `Switch[6]`

If the stopwatch is counting towards positive infinity and it's current value is 9999 then it should stop.
Analog situation must occur when 0 is achieved during decremental counting.

The LEDs should display the following diagnostic information:

* `Led[0]` is on - stopwatch counts towards negative infinity
* `Led[1]` is on - stopwatch counts towards postiive infinity
* `Led[2]` is on - the stopwatch achieved its maximal value (0 or 9999) and then stopped. Pressing any button should clear this state.


## Hardware implementation

The entire chip was written in Verilog. The entrypoint is the `MiniCalcImpl.v` file.

It was tested on Xilinx Spartan-6 chip (code build using ISE suite).
