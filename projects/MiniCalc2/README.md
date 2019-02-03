# 3rd Assignment - UART controlled calculator

## About

This module is a simple calculator performing operations using [RPN]()
on 512-bit stack consiting of 32-bit signed numbers.

### Task specification

After reset the stack must be empty. At each moment of time the calculator is supposed to display the stack-top number on the 8-segment LED display.
If the stack is empty the LEDs should display `----`.

On the normal LEDs (i.e. `LED[6:0]`) the calculator should dsiplay how many are there numbers on the stack (mod 128).

In the case of any error the executed operation should be ignored and the error flag should be raised.
The error flag should be cleared after each successfull operation.

The error flag should be available on the `LED[7]` pin.
The errors that should be detected:

* The stack overflow
* Popping number from empty stack (stack underflow)
* Division by 0

### Push-button functions

| Button | Action                                                                                                                                                                           |
|--------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Btn[0] | If the button `Btn[0]` is pressed is should display upper 16 bits of the top of the stack and lower 16 bits in the other case.                                                   |
| Btn[1] | The calculator should put the 8-bit number selected via `Switch[7:0]` extended with zeros on the left side                                                                       |
| Btn[2] | The calculator should take a number from top of the stack, shift it by 8 bits to the left, set the lower 8 bits to the value selected by `Switch[7:0]` then put it on the stack. |
| Btn[3] | The calculator should perform operation selected by `Switch[2:0]` (described below)                                                                                              |

Pressing `Btn[3]` and `Btn[0]` simultaniously should reset the entire chip to the initial state.

## UART instruction protocol

There exist availability to control the calculator via UART interface.

All operations are 5-bytes long instructions:

```
  IIIIIIII | NNNNNNNN | NNNNNNNN | NNNNNNNN | NNNNNNNN
```

* `I` is the binary representation of instructions
* `N` is the instruction payload (it semantics depends on the exact instruction)

### UART instruction set

| Instruction         | Input       | UART Response                | Input stack size | Output stack size | Modifies flags | Description                                                                                                                                                                                                                                     |
|---------------------|-------------|------------------------------|------------------|-------------------|----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| NOP                 | ---         | 0                            | N                | N                 | Yes            | Does nothing                                                                                                                                                                                                                                    |
| CLS                 | ---         | 0                            | N                | 0                 | Yes            | Clears entire stack                                                                                                                                                                                                                             |
| ADDROT              | *LowerBits* | 0                            | N>0              | N                 | Yes            | Pops the topmost stack value, shifts it 8 bits to the left then swaps the lower 8 bits with lowest 8 bits of *OutputA*, then puts the result back on the stack.                                                                                 |
| PUSH                | *Number*    | *Number*                     | N                | N+1               | Yes            | Pushes the given number to the stack                                                                                                                                                                                                            |
| POP                 | ---         | Popped number                | N>0              | N-1               | Yes            | Pops the topmost number from the stack                                                                                                                                                                                                          |
| COPY                | ---         | Stack topmost number         | N>0              | N+1               | Yes            | Copies the topmost stack element                                                                                                                                                                                                                |
| SWAP                | ---         | Stack second topmost element | N>1              | N                 | Yes            | Swaps the two topmost numbers                                                                                                                                                                                                                   |
| GET                 | *Addr*      | *Stack[Addr]*                | N                | N                 | No             | Gets any number from stack. *Addr* == *StackSize* gets the topmost element, 0 is address for the bottom one. If the given address do not exist then zero is returned.                                                                           |
| LEN                 | ---         | *StackSize*                  | N                | N                 | No             | Gets the current size of the stack                                                                                                                                                                                                              |
| FLA                 | ---         | *Flags*                      | N                | N                 | No             | Gets the 8-bit flags description                                                                                                                                                                                                                |
| ADD/SUB/MUL/MOD/DIV | ---         | 0                            | N                | N-1               | Yes            | Performs +/-/*/mod/div operations on the two topmost numbers on the stack and push back the result on the stack                                                                                                                                 |
| ECHO                | *Value*     | *Value*                      | N                | 0                 | Yes            | Clears the stack and overrides the LED output that shows *Value* even though the stack is empty (this state is temporary and will be reversed after execution of any instruction that modifies the stack content) - used for debugging purposes |

The `FLA` instruction returns flag description in the following format:
```
  EUAIX000
  ^      ^
  8      0
```

Where:

 * `E` - is the bit signalling stack is empty
 * `U` - is the bit signalling there was stack underflow error
 * `A` - bit signalling there was an instruction argument error (e.g. division by zero)
 * `I` - bit signalling the last instruction was not recognized
 * `X` - bit signalling stack overflow error

## Usage of PC controller

The project provides *Controller* directory where the code for node.js Express server with UART port controller resides.
You can firstly install all dependencies:
```bash
 $ cd ./Controller && npm install
```

Then running the server itself:
```bash
 $ node index.js
```

The server provides REPL GUI (ascii) interface.
It receives all HTTP requests and then constructs correct UART commands invocations and sends them to card, then transfers the resuls back to the client.

Helper client-side code in located in `client.js`, the server itself resides in `index.js`.

You can invoke any command from the terminal typing:
```
  $ node push 14
```

Each command execution returns current stack state with diagostic information (i.e. error flags and stack size).

The commands are places within the `commands/` directory (they are simple calls to the client-side helper code).

## Hardware implementation

The entire chip was written in Verilog. The entrypoint is the `GraphicCardImpl.v` file.

It was tested on Xilinx Spartan-6 chip (code build using ISE suite).

## More pictures

