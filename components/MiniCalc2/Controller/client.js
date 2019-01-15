const request = require('request');

const callRemote = (commandName, args) => {
    const options = {
      uri: 'http://localhost:3000',
      method: 'GET'
    };
    
    if(commandName === 'push') {
        options.uri = `${options.uri}/push/${args.number}`;
    } else if(commandName === 'get') {
        options.uri = `${options.uri}/get/${args.addr}`;
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