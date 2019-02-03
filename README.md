# fpga-verilog

## About

This is collection of my projects that was made as a part of Warsaw University FPGA course.
* The `components` directory contains universal Verilog harware components
* The `projects` directory contains top-level modules and codes for projects

## Projects layout

* [MiniCalc](https://github.com/styczynski/fpga-verilog/tree/master/projects/MiniCalc) - very simple 4-bit push-button calculator
* [MiniCalc2](https://github.com/styczynski/fpga-verilog/tree/master/projects/MiniCalc2) - simple (RPN)[https://en.wikipedia.org/wiki/Reverse_Polish_notation] stack-based calculator supporting UART and push-buttons actions (with node.js express server to remotely control chip via UART from PC)
* [Stopwatch](https://github.com/styczynski/fpga-verilog/tree/master/projects/Stopwatch) - basic stopwatch chip controlled via push-buttons (custom clock divider)
* [GraphicCard](https://github.com/styczynski/fpga-verilog/tree/master/projects/GraphicCard) - VGA graphics card controlled via UART interface (with node.js express server to remotely draw pictures or render photos on the screen via help of PC)

## Behavioral testing

You can run test suites using [iverilog](https://github.com/steveicarus/iverilog).
Only requirement is that `iverilog` executable is available from your path.

Just run the follwoing command from your terminal:
```bash
 $ ./test.sh
```