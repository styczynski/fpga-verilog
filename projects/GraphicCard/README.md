# 3rd Assignment - Graphics card with hardware acceleration

## About

![photo of card in action](https://raw.githubusercontent.com/styczynski/fpga-verilog/master/projects/GraphicCard/static/cat_screenshot.jpg)

This project provides external very simple hardware-accelerated graphics card.
The PC-card communication is implemented via UART interface.

### Data format

All operations are 3-bytes long instructions:

```
  IIIICCCP | PPPPPPPP | PPPPPPPP
  ^  ^  ^                      ^
  23 20 17                     0
```

* `I` is the binary representation of instructions
* `C` is 3-bit wide payload called chunk 1 (it semantics depends on the exact instruction)
* `P` is 17-bit wide payload called chunk 2 (it semantics depends on the exact instruction)

After each instruction the card responds with exactly one byte that can be return value or if this is not explicitly mentioned - the `UART_OK_CODE`
value (equal to 42 - meaning sucessfull execution of the requested operation).

### Instruction set

| Instruction | Chunk 1 | Chunk 2 | UART Response | Description                                                                                                                                             |
|-------------|---------|---------|---------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| ECHO        | ---     | *Value* | OK            | Displays value *Value* on the LED display                                                                                                               |
| GET         | ---     | *Addr*  | 3-bit color   | Gets pixel color from address *Addr*                                                                                                                    |
| PUT         | *Color* | *Addr*  | OK            | Paints pixel on position *Addr* with color *Color*                                                                                                      |
| STREAM      | ---     | ---     | OK            | Switches the card into the *Streaming* mode                                                                                                             |
| CLEAR       | ---     | ---     | OK            | Clears the entire screen                                                                                                                                |
| STORE       | *Reg*   | *Value* | OK            | Stores *Value* inside internal register with index *Reg*                                                                                                |
| COPY        | ---     | ---     | OK            | Copies pixels from coordinates (*X*,*Y*)=(*RegA*, *RegB*) to (*X*,*Y*)=(*RegC*, *RegD*). Copying happens inside rectangle of dimensions *RegE* x *RegF* |
| FILL        | ---     | ---     | OK            | Fills rectangle with upper-left and bottom-right coordinates: (*RegA*, *RegB*), (*RegC*, *RegD*)                                                        |

### Color format

The chips uses 3-bit color pallete (8 colours in total).

### Internal registers

We are able to write to 6 internal 17-bit wide general purpose registers (via `STORE <Reg> <Value>` instruction).
These registers are used for execution of complex instructions like `FILL`, `COPY` etc.

| Register name | Addr (for *STORE* instruction) |
|---------------|--------------------------------|
| RegA          | 0                              |
| RegB          | 1                              |
| RegC          | 2                              |
| RegD          | 3                              |
| RegE          | 4                              |
| RegF          | 5                              |

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
  $ node paint 3 50 50
```

![Command execution screenshot](https://raw.githubusercontent.com/styczynski/fpga-verilog/master/projects/GraphicCard/static/command_screenshot.png)

The commands are places within the `commands/` directory (they are simple calls to the client-side helper code).

The server also renders `http://localhost:3000/` page that has very basic user interface to paint you custom drawings (the pixel paint requrests are sent to the chip)
and to upload any custom image (it will be converted to the 3-bit color palette).

## Hardware implementation

The entire chip was written in Verilog. The entrypoint is the `GraphicCardImpl.v` file.

It was tested on Xilinx Spartan-6 chip (code build using ISE suite).

## More pictures

**Example of custom image upload via http://localhost:3000/ page**

![Example of custom image upload](https://raw.githubusercontent.com/styczynski/fpga-verilog/master/projects/GraphicCard/static/any_image_screenshot.jpg)
