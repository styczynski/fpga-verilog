/*


localhost:3000/paint/50/50
localhost:3000/stream

*/
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
    baudRate: 576000
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
                if(retryNo > 5) {
                    retryFn();
                    return;
                }
                setTimeout(() => pollRead(retryNo+1), 0);
            };
            pollRead(0);
            //setTimeout(() => pollRead(0), 0);
        }
    };
};

const sendDataWithRetry = (port, data, handler, setupTeardownFn, dataHandler) => {
    const fn = () => {
        if(setupTeardownFn) setupTeardownFn();
        reqSecNewResult += data.length;
        port.write(data, waitForBytesHandler(port, 1, handler, fn, (value) => {
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

//const paintPixelHelper = (x, y, col) => [ 2, col, ...numToBytes(400*y+x, 3) ];
//131072*
const paintPixelHelper = (x, y, col) => [ ...numToBytes((1048576*2) + (131072*col) + (400*y+x), 3) ];

const COMMANDS = {
    echo: ({ port, handler, data }) => {
        const d = [ ...numToBytes((1048576*1) + data, 3) ];
        logger.log('SEND '+d.join(' '));
        sendDataWithRetry(port, d, handler);
    },
    stream: ({ port, handler }) => {
        port.write([255, 255, 255, ...numToBytes((1048576*3), 3)], () => {
            let commands = [[...numToBytes((1048576*3), 3)]];
            for(let i=0;i<120000-1;++i) {
                const x = parseInt(i%400);
                const y = parseInt(i/400);
                const col = (y == 100+parseInt(Math.sin(x/20)*50))?(1):(0);
                commands.push([
                    ...numToBytes((32*col), 1)
                ]);
            }
            commands.map((i) => port.write(i, handler));
        });
    },
    clear: ({ port, handler}) => {
        sendDataWithRetry(port, [ ...numToBytes((1048576*4) + (131072*0), 3) ], handler)
    },
    paint: ({ port, handler, x, y }) => {
        //const d = [ 2, 255, ...numToBytes(y*400+x, 3) ];
        const d = paintPixelHelper(x, y, 3);
        logger.log('SEND '+d.join(' '));
        sendDataWithRetry(port, d, handler)
    },
    xpaint: ({ port, handler, x, y }) => {
        let commands = [];
        /*for(let tt=0;tt<300;++tt) {
            commands.push([
                2, 3, ...numToBytes(400*tt+100, 3),
                2, 3, ...numToBytes(400*tt+200, 3),
                2, 3, ...numToBytes(400*tt+300, 3)
            ]);
        }*/
        
        for(let x=150;x<=250;++x) {
            for(let y=50;y<=150;++y) {
                commands.push(paintPixelHelper(x, y, 3));
            }
        }
        sendCommands(port, commands, handler);
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
        if(commands[index] && commands[index].constructor === Array) {
            
            sendDataWithRetry(port, commands[index], thenHandler(handler, () => {
                statExecutedCommandsCnt += 1;
                sendCommandI(index+1);
            }));
            
            /*
            setTimeout(() => {
                port.write(commands[index], thenHandler(handler, () => {
                    statExecutedCommandsCnt += 1;
                    sendCommandI(index+1);
                }));
            }, 0);
            */
        } else if(commands[index].wait !== null && typeof commands[index].wait !== 'undefined') {
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
       commands = [ ...params ];
   } else {
       commands = [ params ];
   }
   sendCommands(port, commands, () => {
       response.send({status: "OK"});
   });
   logger.log('COMMAND END');
};

app.post('/execute', function(req, res) {
   executeCommand((req.body || {}).commands || [], res);
});

app.get('/clear', function(req, res) {
   executeCommand({ call: 'clear' }, res);
});

app.get('/stream', function(req, res) {
   executeCommand({ call: 'stream' }, res);
});

app.get('/echo/:data', function(req, res) {
   executeCommand({ call: 'echo', data: parseInt(req.params.data) }, res);
});

app.get('/paint/:x/:y', function(req, res) {
   executeCommand({ call: 'paint', x: parseInt(req.params.x), y: parseInt(req.params.y) }, res);
});

app.get('/xpaint', function(req, res) {
   executeCommand({ call: 'xpaint', x: 0, y: 0 }, res);
});

/*setInterval(() => {
    
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
}, 1000);*/

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

