const request = require('request');

const callRemote = (commandName, args) => {
    const options = {
      uri: 'http://localhost:3000',
      method: 'GET'
    };
    
    if(commandName === 'stream') {
        options.uri = `${options.uri}/stream`;
    } else if(commandName === 'clear') {
        options.uri = `${options.uri}/clear`;
    } else if(commandName === 'echo') {
        options.uri = `${options.uri}/echo/${args.data}`;
    } else if(commandName === 'paint') {
        options.uri = `${options.uri}/paint/${args.x}/${args.y}`;
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