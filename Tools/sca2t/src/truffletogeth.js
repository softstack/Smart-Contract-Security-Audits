'use strict';

// require section
const fs = require('fs');

export function truffletogeth(varname, address, jsonfilepath) {
  // read json file which truffle generated.
  let content = fs.readFileSync(jsonfilepath).toString('utf-8');
  let json = JSON.parse(content);
  let output = 'var ' + varname + ' = eth.contract(' + JSON.stringify(json.abi) + ').at(' + address + ')';
  console.log(output);
}