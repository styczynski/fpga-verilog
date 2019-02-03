const defaultHandler = (logger) => ((err) => {
  if(err) {
    return logger('ERROR: '+err.message.toString());
  }
});

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

class UartServer {
  
  constructor(options) {
    options = Object.assign({
        port: 'COM16',
        baudRate: 230400
    }, options);
    
    this.port =  new SerialPort(options.port, { baudRate: options.baudRate });
    this.readData = [];
    this.taskQueue = [];
    this.taskQueueBusy = false;
    this.logger = () => {};
    this.commands = {};
    this.statScheduledCommandsCnt = 0;
    this.statExecutedCommandsCnt = 0;
    this.app = null;
    
    this.runTask = this.runTask.bind(this);
    this.executeNextTask = this.executeNextTask.bind(this);
    this.setLogger = this.setLogger.bind(this);
    this.addCommands = this.addCommands.bind(this);
    this.sendCommands = this.sendCommands.bind(this);
    this.executeCommand = this.executeCommand.bind(this);
    this.run = this.run.bind(this);
    
    this.taskExecutorInterval = setInterval(this.executeNextTask, 1);
    
    this.port.on('data', function(data) {
        const inputArr = [...data];
        this.readData = this.readData.concat(inputArr);
    });
  }  
  
  run(initializer) {
      this.app = express();
      this.app.use(express.json());
      this.app.use(express.static('app'));
      
      this.app.post('/execute', (req, res) => {
           runTask(() => {
               this.logger('EXECUTE len():='+(((req.body || {}).commands || []).length));
               this.executeCommand((req.body || {}).commands || [], res);
          });
      });
      
      Object.keys(this.commands).forEach((key) => {
          const com = this.commands[key];
          const args = com.args;
          const argsString = (args.length == 0)?(''):('/:'+args.map((arg) => {
             return (!arg || typeof arg === 'string' || !arg.name)?(arg):(arg.name);
          }).join('/:'));
          this.app.get(`/${key}${argsString}`, (req, res) => {
             runTask(() => {
                 const callObj = { call: key };
                 args.forEach((arg) => {
                     if(!arg || typeof arg === 'string' || !arg.parse) {
                         callObj[arg] = req.params[arg];
                     } else {
                         callObj[
                     }
                 });
                 executeCommand({ call: 'load', reg: parseInt(req.params.reg), value: parseInt(req.params.value) }, res);
             });
          });
      });
      
      if(initializer) {
          initializer(this.app);
      }
  }
  
  runTask(fn) {
      this.taskQueue.push(() => {
          this.taskQueueBusy = true;
          fn();
          this.taskQueueBusy = false;
      });
  }
   
  executeNextTask() {
    if(!this.taskQueueBusy && this.taskQueue.length > 0) {
      this.taskQueue[0]();
      this.taskQueue = this.taskQueue.splice(1);
    }
  }
  
  setLogger(logger) {
      this.logger = logger;
  }
  
  addCommands(commands) {
      this.commands = Object.assign({}, this.commands, commands);
  }
  
  sendCommands(commands, handler) {
        this.statScheduledCommandsCnt += commands.length;
        
        handler = handler || defaultHandler(this.logger);
        const sendCommandI = (index) => {
            if(index >= commands.length) {
                handler(null);
                return;
            }
            if(commands[index] && commands[index].constructor === Array) {
                
                sendDataWithRetry(this.port, commands[index], thenHandler(handler, () => {
                    this.statExecutedCommandsCnt += 1;
                    sendCommandI(index+1);
                }));
                
            } else if(commands[index].wait !== null && typeof commands[index].wait !== 'undefined') {
                setTimeout(() => {
                    this.commands[commands[index].call].fn(Object.assign({}, commands[index], {
                        this.port,
                        handler: thenHandler(handler, () => {
                            this.statExecutedCommandsCnt += 1;
                            sendCommandI(index+1);
                        })
                    }));
                }, commands[index].wait);
            } else {
                this.commands[commands[index].call].fn(Object.assign({}, commands[index], {
                    this.port,
                    handler: thenHandler(handler, () => {
                        this.statExecutedCommandsCnt += 1;
                        sendCommandI(index+1);
                    })
                }));
            }
        };
        sendCommandI(0);
    }
    
    executeCommand(params, response) {
       this.statScheduledCommandsCnt = 0;
       this.statExecutedCommandsCnt = 0;
       
       this.logger(JSON.stringify(params));
       let commands = [];
       if(params.constructor === Array) {
           commands = [ ...params ];
       } else {
           commands = [ params ];
       }
       this.sendCommands(port, commands, () => {
           response.send({status: "OK"});
       });
       this.logger('COMMAND END');
    }
    
    
  
};


let statScheduledCommandsCnt = 0;
let statExecutedCommandsCnt = 0;


const app = express();

app.use(express.json());
app.use(express.static('app'));
app.use(fileUpload({
  limits: { fileSize: 50 * 1024 * 1024 },
}));


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

