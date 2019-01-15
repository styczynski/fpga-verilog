// Hello
const path = require('path');
const SerialPort = require('serialport');
const express = require('express');
const bodyParser = require('body-parser');
const blessed = require('blessed');
const contrib = require('blessed-contrib');
const XTerm   = require('blessed-xterm');

let stackData = [];
let readData = [];
let stackSize = 0;
let stackDataFormatted = [];
let stackUpdateTimer = null;
let stackFlags = 0;

let statScheduledCommandsCnt = 0;
let statExecutedCommandsCnt = 0;

const port = new SerialPort('COM10', {
    baudRate: 460800
});

port.on('data', function(data) {
    const inputArr = [...data];
    //logger.log('READ: '+inputArr.join(' ').toString());
    readData = readData.concat(inputArr);
});

const setStackCell = (index, value, handler) => {
    //logger.log('STUPD: '+index+', '+value);
    if(index < 0) {
        return;
    }
    
    while(stackData.length <= index) {
        stackData.push(0);
    }
    
    stackData[index] = value;
    
    if(stackUpdateTimer !== null) {
        clearTimeout(stackUpdateTimer);
        stackUpdateTimer = null;
    }
    stackDataFormatted = ({headers: ['Addr', 'Value'], data: stackData.filter((value, index) => true).map((value, index) => {
        return [ '#'+index, value ];
    })});
    if(handler) {
        handler(null);
    }
    stackUpdateTimer = setTimeout(() => {
        if(stackUpdateTimer !== null) {
            clearTimeout(stackUpdateTimer);
            stackUpdateTimer = null;
        }
        stackTable.setData(stackDataFormatted);
        stackTable.focus();
        setTimeout(() => {
            terminalWindow.focus()
        }, 0);
    }, 500);
};

const logger = {
    listeners: [],
    log: (message) => {
       logger.listeners.forEach(listener => listener((message || '').toString()));
    }
};

const thenHandler = (handler, thenCallback) => {
    return (err) => {
        if(err) {
            handler(err);
        } else {
            thenCallback(null);
        }
    };
};

const numToBytes = (number, bytesCount) => {
  let result = [];
  for(let i=0;i<bytesCount;++i) {
    result.push(number%256);
    number = (number - number%256) / 256;
  }
  return result.reverse();
};

const waitForBytesHandler = (port, bytesCount, handler, retryFn, dataHandler) => {
    return (err) => {
        if(err) {
            handler(err);
        } else {
            let bytesLeft = bytesCount;
            let result = [];
            let pollRead = (retryNo) => {
                if(bytesLeft <= 0) {
                    if(dataHandler) {
                        let chunkPow = 1;
                        let numberResult = 0;
                        result.reverse().forEach((chunk) => {
                            numberResult += chunkPow * chunk;
                            chunkPow *= 256;
                        });
                        dataHandler(numberResult);
                    }
                    return;
                }
                let data = readData.splice(readData.length-bytesLeft);
                if(data !== null) {
                    const partialResult = [...data];
                    bytesLeft -= partialResult.length;
                    result = result.concat(partialResult);
                }
                if(retryNo > 2) {
                    retryFn();
                    return;
                }
                setTimeout(() => pollRead(retryNo+1), 1);
            };
            setTimeout(() => pollRead(0), 0);
        }
    };
};

const sendDataWithRetry = (port, data, handler, setupTeardownFn, dataHandler) => {
    const fn = () => {
        if(setupTeardownFn) setupTeardownFn();
        reqSecNewResult += data.length;
        port.write(data, waitForBytesHandler(port, 4, handler, fn, (value) => {
            if(setupTeardownFn) setupTeardownFn();
            if(dataHandler) {
                dataHandler(value);
            } else {
                handler(null);
            }
        }));
    };
    fn();
};

const getFlagsDescrObj = (flags) => {
    return {
        stackEmpty:              !!((flags>>4)%2),
        errorUnderflow:          !!((flags>>3)%2),
        errorOverflow:           !!((flags>>0)%2),
        errorInvalidArgument:    !!((flags>>2)%2),
        errorInvalidInstruction: !!((flags>>1)%2),
    };
};

const COMMANDS = {
    nop:  ({ port, handler })          => sendDataWithRetry(port, [ 17,  1, 1, 1, 1 ], handler),
    pop:  ({ port, handler })          => sendDataWithRetry(port, [ 2,   1, 1, 1, 1 ], handler),
    push: ({ port, handler, number })  => {
        sendDataWithRetry(port, [ 1, ...numToBytes(number, 4) ], handler);
    },
    get: ({ port, handler, addr })  => {
        sendDataWithRetry(port, [ 32, ...numToBytes(addr, 4) ], handler, () => { readData = []; }, (value) => {
                setStackCell(addr, value, (err) => {
                    readData = [];
                    handler(err);
                });
        });
    },
    len: ({ port, handler })  => {
        sendDataWithRetry(port, [ 34, 1, 1, 1, 1 ], handler, () => { readData = []; stackData = []; }, (value) => {
            if(value < 0 || value > 1024) {
                value = 0;
            }
            stackSize = value;
            handler(null);
        });
    },
    fla: ({ port, handler })  => {
        sendDataWithRetry(port, [ 36, 1, 1, 1, 1 ], handler, () => { readData = []; stackData = []; }, (value) => {
            stackFlags = value;
            handler(null);
        });
    },
    //dump: ({ port, handler })          => port.write([ 7,   1, 1, 1, 1, 17, 1, 1, 1, 1 ], handler),
    add:  ({ port, handler })          => sendDataWithRetry(port, [ 4,   1, 1, 1, 1 ], handler),
    sub:  ({ port, handler })          => sendDataWithRetry(port, [ 5,   1, 1, 1, 1 ], handler),
    mul:  ({ port, handler })          => sendDataWithRetry(port, [ 6,   1, 1, 1, 1 ], handler),
    div:  ({ port, handler })          => sendDataWithRetry(port, [ 8,   1, 1, 1, 1 ], handler),
    mod:  ({ port, handler })          => sendDataWithRetry(port, [ 10,  1, 1, 1, 1 ], handler),
    swap: ({ port, handler })          => sendDataWithRetry(port, [ 9,   1, 1, 1, 1 ], handler),
    copy: ({ port, handler })          => sendDataWithRetry(port, [ 3,   1, 1, 1, 1 ], handler),
    cls:  ({ port, handler })          => sendDataWithRetry(port, [ 128, 1, 1, 1, 1 ], handler),
    dump: ({ port, handler })          => {
        sendCommands(port, [{call: 'fla'}, {call: 'fla'}, {call: 'len'}, {call: 'len'}], () => {
            let commands = [];
            for(let i=0;i<stackSize;++i) {
                commands.push({
                    call: 'get',
                    addr: i
                });
                commands.push({
                    call: 'get',
                    addr: i
                });
            }
            sendCommands(port, commands, handler);
        });
    }
};

const defaultHandler = (err) => {
  if(err) {
    return logger.log('ERROR: '+err.message.toString());
  }
  logger.log('SEND');
};

const sendCommands = (port, commands, handler) => {
    
    statScheduledCommandsCnt += commands.length;
    
    handler = handler || defaultHandler;
    const sendCommandI = (index) => {
        if(index >= commands.length) {
            handler(null);
            return;
        }
        if(commands[index].wait !== null && typeof commands[index].wait !== 'undefined') {
            setTimeout(() => {
                COMMANDS[commands[index].call](Object.assign({}, commands[index], {
                    port,
                    handler: thenHandler(handler, () => {
                        statExecutedCommandsCnt += 1;
                        sendCommandI(index+1);
                    })
                }));
            }, commands[index].wait);
        } else {
            COMMANDS[commands[index].call](Object.assign({}, commands[index], {
                port,
                handler: thenHandler(handler, () => {
                    statExecutedCommandsCnt += 1;
                    sendCommandI(index+1);
                })
            }));
        }
    };
    sendCommandI(0);
};


const app = express();

app.use(express.json());

let reqSecNewResult = 0;
let reqSecData = [];
let stackSecData = [];

const executeCommand = (params, response) => {
   statScheduledCommandsCnt = 0;
   statExecutedCommandsCnt = 0;
   
   logger.log(JSON.stringify(params));
   let commands = [];
   if(params.constructor === Array) {
       commands = [ ...params, { call: 'dump' } ];
   } else {
       commands = [ params, { call: 'dump' } ];
   }
   sendCommands(port, commands, () => {
       response.send({
           stack: stackData,
           flags: getFlagsDescrObj(stackFlags)
       });
   });
   //response.send('OK');
   logger.log('COMMAND END');
};

app.post('/execute', function(req, res) {
   executeCommand((req.body || {}).commands || [], res);
});

app.get('/push/:number', function(req, res) {
   executeCommand({ call: 'push', number: parseInt(req.params.number) }, res);
});

app.get('/get/:addr', function(req, res) {
   executeCommand({ call: 'get', addr: parseInt(req.params.addr) }, res);
});

app.get('/pop', function(req, res) {
   executeCommand({ call: 'pop' }, res);
});

app.get('/add', function(req, res) {
   executeCommand({ call: 'add' }, res);
});

app.get('/sub', function(req, res) {
   executeCommand({ call: 'sub' }, res);
});

app.get('/mul', function(req, res) {
   executeCommand({ call: 'mul' }, res);
});

app.get('/div', function(req, res) {
   executeCommand({ call: 'div' }, res);
});

app.get('/mod', function(req, res) {
   executeCommand({ call: 'mod' }, res);
});

app.get('/copy', function(req, res) {
   executeCommand({ call: 'copy' }, res);
});

app.get('/cls', function(req, res) {
   executeCommand({ call: 'cls' }, res);
});

app.get('/swap', function(req, res) {
   executeCommand({ call: 'swap' }, res);
});

app.get('/nop', function(req, res) {
   executeCommand({ call: 'nop' }, res);
});

setInterval(() => {
    
    if(reqSecData.length > 10) {
        reqSecData = reqSecData.splice(1);
    }
    reqSecData.push(reqSecNewResult);
    reqSecNewResult = 0;
    
    if(stackSecData.length > 10) {
        stackSecData = stackSecData.splice(1);
    }
    
    line.setData([
        {
            title: 'B/Sec',
            x: reqSecData.map((value, index) => `t-${reqSecData.length-index-1}`),
            y: reqSecData
        }
    ]);
    line.focus();
    setTimeout(() => {
        terminalWindow.focus()
    
            if(statScheduledCommandsCnt <= 0) {
                gauge.setPercent(100);
            } else {
                gauge.setPercent(Math.ceil(statExecutedCommandsCnt / statScheduledCommandsCnt * 100));
            }
            gauge.focus();
            setTimeout(() => {
                terminalWindow.focus()
            }, 0);
    }, 0);
    
    //['Req/Sec', 'Stack usage'], [reqSecData, stackSecData]
}, 1000);

app.listen(3000);


const screen = blessed.screen();
const grid = new contrib.grid({rows: 12, cols: 12, screen: screen});

const commandLog = grid.set(8, 6, 4, 6, contrib.log, {
  fg: 'green',
  selectedFg: 'green',
  label: 'Command Log'
});
logger.listeners.push((message) => commandLog.log(message));

const gauge = grid.set(2, 0, 2, 4, contrib.gauge, {
    label: 'Progress',
    stroke: 'green',
    fill: 'white'
});

const stackTable = grid.set(2, 9, 6, 4, contrib.table, {
   keys: true,
   fg: 'green',
   label: 'Stack contents',
   columnSpacing: 1,
   columnWidth: [24, 10, 10]
});
stackTable.setData({headers: ['Addr', 'Value'], data: []})

const line = grid.set(0, 0, 2, 12, contrib.line, {
   style: {
        line: "yellow",
        text: "green",
        baseline: "black"
   },
   xLabelPadding: 3,
   xPadding: 5,
   showLegend: true,
   wholeNumbersOnly: false,
   label: 'Title'
});

const terminalWindowOptions = Object.assign({}, {
    shell:         'cmd.exe',
    args:          [],
    env:           process.env,
    cwd:           path.resolve(process.cwd(), './commands'),
    cursorType:    "block",
    border:        "line",
    scrollback:    1000,
    style: {
        fg:        "default",
        bg:        "default",
        border:    { fg: "default" },
        focus:     { border: { fg: "green" } },
        scrolling: { border: { fg: "red" } }
    }
}, {
    left:    0,
    top:     Math.floor(screen.height/3),
    width:   Math.floor(screen.width / 2),
    height:  Math.floor(screen.height*2/3),
    label:   "Sample XTerm #1"
});

const terminalWindow = new XTerm(terminalWindowOptions);

let hint = "\r\nPress CTRL+q to stop sample program.\r\n" +
    "Press F1 or F2 to switch between terminals.\r\n\r\n";
terminalWindow.write(hint);
terminalWindow.focus();
terminalWindow.key("pagedown", () => {
    if (!terminalWindow.scrolling)
        terminalWindow.scroll(0)
    let n = Math.max(1, Math.floor(terminalWindow.height * 0.10))
    terminalWindow.scroll(+n)
    if (Math.ceil(terminalWindow.getScrollPerc()) === 100)
        terminalWindow.resetScroll()
});
terminalWindow.key("pageup", () => {
    if (!terminalWindow.scrolling)
        terminalWindow.scroll(0)
    let n = Math.max(1, Math.floor(terminalWindow.height * 0.10))
    terminalWindow.scroll(-n)
    if (Math.ceil(terminalWindow.getScrollPerc()) === 100)
        terminalWindow.resetScroll()
});

screen.append(terminalWindow);
screen.append(commandLog);
screen.append(stackTable);
screen.append(line);

screen.key(['escape', 'q', 'C-c'], function(ch, key) {
 return process.exit(0);
});

screen.render();

