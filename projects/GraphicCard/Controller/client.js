const request = require('request');

const callRemote = (commandName, args) => {
    const options = {
      uri: 'http://localhost:3000',
      method: 'GET'
    };
    
    if(commandName === 'get') {
        options.uri = `${options.uri}/get/${args.x}/${args.y}`;
    } else if(commandName === 'copy') {
        options.uri = `${options.uri}/copy/${args.x1}/${args.y1}/${args.x2}/${args.y2}/${args.w}/${args.h}`;
    } else if(commandName === 'rect') {
        options.uri = `${options.uri}/rect/${args.color}/${args.x1}/${args.y1}/${args.x2}/${args.y2}`;
    } else if(commandName === 'load') {
        options.uri = `${options.uri}/load/${args.reg}/${args.value}`;
    } else if(commandName === 'stream') {
        options.uri = `${options.uri}/stream`;
    } else if(commandName === 'clear') {
        options.uri = `${options.uri}/clear`;
    } else if(commandName === 'echo') {
        options.uri = `${options.uri}/echo/${args.data}`;
    } else if(commandName === 'paint') {
        options.uri = `${options.uri}/paint/${args.color}/${args.x}/${args.y}`;
    } else if(commandName.constructor === Array) {
        options.uri = `${options.uri}/execute`;
        options.method = 'POST';
        options.json = {
            commands: commandName
        };
    } else {
        options.uri = `${options.uri}/${commandName}`;
    }

    request(options, function (error, response, body) {
      console.log(JSON.parse(response.body));
    });
};

module.exports = {
    call: callRemote
};