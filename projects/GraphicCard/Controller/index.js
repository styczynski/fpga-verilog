/*


localhost:3000/paint/50/50
localhost:3000/stream
localhost:3000/load/1/44
localhost:3000/clear

*/
// Hello
const path = require('path');
const sharp = require('sharp');
const SerialPort = require('serialport');
const stream = require('stream');
const express = require('express');
const fileUpload = require('express-fileupload');
const bodyParser = require('body-parser');
const blessed = require('blessed');
const contrib = require('blessed-contrib');
const XTerm   = require('blessed-xterm');
const PNG = require('pngjs').PNG;

let stackData = [];
let readData = [];
let stackSize = 0;
let stackDataFormatted = [];
let stackUpdateTimer = null;
let stackFlags = 0;

let statScheduledCommandsCnt = 0;
let statExecutedCommandsCnt = 0;

const port = new SerialPort('COM16', {
    baudRate: 230400
});

port.on('data', function(data) {
    const inputArr = [...data];
    //logger.log('READ: '+inputArr.join(' ').toString());
    readData = readData.concat(inputArr);
});

let taskQueue = [];
let taskQueueBusy = false;
let runTask = (fn) => {
    taskQueue.push(() => {
        taskQueueBusy = true;
        fn();
        taskQueueBusy = false;
    });
};

setInterval(() => {
    if(!taskQueueBusy && taskQueue.length > 0) {
        taskQueue[0]();
        taskQueue = taskQueue.splice(1);
    }
}, 1);

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
                if(retryNo > 3) {
                    retryFn();
                    return;
                }
                setTimeout(() => pollRead(retryNo+1), 1);
            };
            //pollRead(0);
            setTimeout(() => pollRead(0), 0);
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
const loadRegHelper = (reg, value) => [ ...numToBytes((1048576*5) + (131072*reg) + (value), 3) ];

let lastRcvValue = null;

const COMMANDS = {
    copy: ({ port, handler, x1, y1, x2, y2, w, h }) => {
        sendDataWithRetry(port, loadRegHelper(0, x1), () => {
            sendDataWithRetry(port, loadRegHelper(1, y1), () => {
                sendDataWithRetry(port, loadRegHelper(2, x2), () => {
                    sendDataWithRetry(port, loadRegHelper(3, y2), () => {
                        sendDataWithRetry(port, loadRegHelper(4, w), () => {
                            sendDataWithRetry(port, loadRegHelper(5, h), () => {
                                sendDataWithRetry(port, numToBytes((1048576*7) + (131072*0), 3), handler);
                            });
                        });
                    });
                });
            });
        });
    },
    echo: ({ port, handler, data }) => {
        const d = [ ...numToBytes((1048576*1) + data, 3) ];
        //logger.log('SEND '+d.join(' '));
        sendDataWithRetry(port, d, handler);
    },
    load: ({ port, handler, reg, value }) => {
        sendDataWithRetry(port, loadRegHelper(reg, value), handler);
    },
    multipaint: ({ port, handler, points }) => {
        sendCommands(port, points.map((p) => {
            return {
                call: 'paint',
                ...p
            };
        }), handler);
    },
    rect: ({ port, handler, color, x1, y1, x2, y2 }) => {
        sendDataWithRetry(port, loadRegHelper(0, x1), () => {
            sendDataWithRetry(port, loadRegHelper(1, y1), () => {
                sendDataWithRetry(port, loadRegHelper(2, x2), () => {
                    sendDataWithRetry(port, loadRegHelper(3, y2), () => {
                        sendDataWithRetry(port, numToBytes((1048576*6) + (131072*color), 3), handler);
                    });
                });
            });
        });
    },
    stream: ({ port, handler, data }) => {
        sendDataWithRetry(port, [255, 255, 255, ...numToBytes((1048576*3), 3)], () => {
            let commands = [];
            if(!data) {
                for(let i=0;i<120000;++i) {
                    const x = parseInt(i%400);
                    const y = parseInt(i/400);
                    const col = (x%2==0 || y%2==0)?(4):(5);//(y == 100+parseInt(Math.sin(x/20)*50))?(3):(1);
                    ([
                        ...numToBytes((32*col), 1)
                    ]).forEach((i) => commands.push(i));
                }
            } else {
                data.forEach((col) => {
                    ([
                        ...numToBytes((32*col), 1)
                    ]).forEach((i) => commands.push(i));
                });
            }
            port.write(commands, handler);
        });
    },
    clear: ({ port, handler}) => {
        sendDataWithRetry(port, [ ...numToBytes((1048576*4) + (131072*0), 3) ], handler)
    },
    paint: ({ port, handler, color, x, y }) => {
        const d = paintPixelHelper(x, y, color);
        logger.log('SEND '+d.join(' '));
        sendDataWithRetry(port, d, handler)
    },
    get: ({ port, handler, x, y }) => {
        readData = [];
        sendDataWithRetry(port, [ ...numToBytes((1048576*8) + (131072*0) + (400*y+x), 3) ], handler, null, (value) => {
            sendDataWithRetry(port, [ ...numToBytes((1048576*8) + (131072*0) + (400*y+x), 3) ], handler, null, (value) => {
                
                value = parseInt(value);
                const R = parseInt(value/4)%2;
                const G = parseInt(value/2)%2;
                const B = parseInt(value)%2;
                logger.log('GET = '+value+': R='+R+', G='+G+', B='+B);
                
                lastRcvValue = `#${R?'ff':'00'}${G?'ff':'00'}${B?'ff':'00'}`;
                readData = [];
                handler();
            });
        });
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
  //logger.log('SEND');
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
app.use(express.static('app'));
app.use(fileUpload({
  limits: { fileSize: 50 * 1024 * 1024 },
}));

let reqSecNewResult = 0;
let reqSecData = [];
let stackSecData = [];

const executeCommand = (params, response) => {
   lastRcvValue = null;
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
       const retObj = { status: 'OK' };
       if(lastRcvValue !== null) {
           retObj.value = lastRcvValue;
       }
       response.send(retObj);
   });
   logger.log('COMMAND END');
};

app.post('/execute', function(req, res) {
   runTask(() => {
       logger.log('EXECUTE len():='+(((req.body || {}).commands || []).length));
       executeCommand((req.body || {}).commands || [], res);
   });
});

app.post('/upload', function(req, res) {
  console.log(req.files.foo);
  
  let response = [];
  
  const resizerStream = sharp()
    .resize(400, 300)
    .png();
  
  // Initiate the source
  const bufferStream = new stream.PassThrough();
  bufferStream.end(req.files.foo.data);
  bufferStream
    .pipe(resizerStream)
    .pipe(new PNG({
      filterType: 4
    }))
    .on('parsed', function() {
        let sumr = 0;
        let sumg = 0;
        let sumb = 0;
        let samplesCount = 0;
        
        for(let y=0; y<this.height; y++) {
            for(let x=0; x<this.width; x++) {
                let idx = (this.width * y + x) << 2;
                
                sumr += this.data[idx]/255;
                sumg += this.data[idx+1]/255;
                sumb += this.data[idx+2]/255;
                ++samplesCount;
            }
        }
        
        let avgr = sumr/samplesCount*255;
        let avgg = sumg/samplesCount*255;
        let avgb = sumb/samplesCount*255;
        
        
        for(let y = 0; y < this.height; y++) {
            for(let x = 0; x < this.width; x++) {
                let idx = (this.width * y + x) << 2;
 
                const r = this.data[idx] >= avgr;
                const g = this.data[idx+1] >= avgg;
                const b = this.data[idx+2] >= avgb;
                
                response.push(r*4+g*2+b);
            }
        }
 
        //res.send({ data: response });
        runTask(() => {
            executeCommand({ call: 'stream', data: response }, res);
       });
    });
});

app.get('/clear', function(req, res) {
   runTask(() => {
       executeCommand({ call: 'clear' }, res);
   });
});

app.get('/stream', function(req, res) {
   runTask(() => {
       executeCommand({ call: 'stream' }, res);
   });
});

app.get('/copy/:x1/:y1/:x2/:y2/:w/:h', function(req, res) {
   runTask(() => {
       executeCommand({
          call: 'copy',
          x1: parseInt(req.params.x1),
          y1: parseInt(req.params.y1),
          x2: parseInt(req.params.x2),
          y2: parseInt(req.params.y2),
          w: parseInt(req.params.w),
          h: parseInt(req.params.h)
       }, res);
   });
});

app.get('/rect/:color/:x1/:y1/:x2/:y2', function(req, res) {
   runTask(() => {
       executeCommand({
          call: 'rect',
          color: parseInt(req.params.color),
          x1: parseInt(req.params.x1),
          y1: parseInt(req.params.y1),
          x2: parseInt(req.params.x2),
          y2: parseInt(req.params.y2)
       }, res);
   });
});

app.get('/load/:reg/:value', function(req, res) {
   runTask(() => {
       executeCommand({ call: 'load', reg: parseInt(req.params.reg), value: parseInt(req.params.value) }, res);
   });
});

app.get('/echo/:data', function(req, res) {
   runTask(() => {
        executeCommand({ call: 'echo', data: parseInt(req.params.data) }, res);
   });
});

app.get('/get/:x/:y', function(req, res) {
   runTask(() => {
       executeCommand({
           call: 'get',
           x: parseInt(req.params.x),
           y: parseInt(req.params.y)
       }, res);
   });
});

app.get('/paint/:color/:x/:y', function(req, res) {
   runTask(() => {
       executeCommand({
           call: 'paint',
           x: parseInt(req.params.x),
           y: parseInt(req.params.y),
           color: parseInt(req.params.color)
       }, res);
   });
});

app.get('/xpaint', function(req, res) {
   runTask(() => {
       executeCommand({ call: 'xpaint', x: 0, y: 0 }, res);
   });
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

