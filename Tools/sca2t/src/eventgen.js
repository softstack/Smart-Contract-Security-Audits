'use strict';

// require section
const antlr4 = require('antlr4/index');
const SolidityLexer = require('./SolidityLexer').SolidityLexer;
const SolidityParser = require('./SolidityParser').SolidityParser;
const EventgenSolidityListener = require('./EventgenSolidityListener').EventgenSolidityListener;
const fs = require('fs');

export function eventgen(files) {
  let failures = [];
  let successes = [];
  files.forEach(file => {
    try {
      // generate event per file.
      if(processFile(file)) {
        console.log(`[SUCCESS]: ${file} `);
        successes.push(file);  
      }
    } catch (e) {
      console.log(`[FAIL]: ${file} `);
      console.error(e);
      failures.push(file);
    }
  });

  // show summary
  console.log();
  console.log('=== SUMMARY ===');
  console.log(`${successes.length} file(s) succeeded.`);
  console.log(`  ${successes.join('\n  ')}`);
  console.log()
  console.log(`${failures.length} file(s) failed.`);
  console.log(`  ${failures.join('\n  ')}`);
  console.log('===============');
}

function processFile(file) {
  // Read file
  let content;
  try {
    content = fs.readFileSync(file).toString('utf-8')
  } catch (e) {
    if (e.code === 'EISDIR') {
      console.error(`Skiping directory ${file}`)
      return false
    } else throw e
  }

  // variables which are relavant to antlr4
  const chars = new antlr4.InputStream(content);
  const lexer = new SolidityLexer(chars);
  const tokens = new antlr4.CommonTokenStream(lexer);
  const parser = new SolidityParser(tokens);
  const tree = parser.sourceUnit();
  let listener = new EventgenSolidityListener(tokens, parser);

  // tree walking of solidity 
  antlr4.tree.ParseTreeWalker.DEFAULT.walk(listener, tree);

  const indent = '  ';  // indent
  let modContent = content; // modified content
  let offset = 0; // this offset will be incremented every inserting event.

  // process each contract
  listener.contractNames.forEach( conName => {

    let contract = listener.contracts[conName];

    // add event definition
    const addedEventDef = `event SCA2T(string sca2tMsg);\n${indent}`;
    const conBodyStart = contract.bodyStart;
    modContent = modContent.slice(0, conBodyStart + offset) + addedEventDef + modContent.slice(conBodyStart + offset);
    offset += addedEventDef.length;

    // add event call per function
    contract.functions.forEach(func => {
      let addedEventCall = `\n${indent}${indent}emit SCA2T("[${conName}]: ${func.name} was called.");`;
      if (func.isEmpty) {
        addedEventCall += `\n${indent}`;
      }
      modContent = modContent.slice(0, func.bodyStart + offset + 1) + addedEventCall + modContent.slice(func.bodyStart + offset + 1);
      offset += addedEventCall.length;
    });
  });

  // replace original file with modContent
  fs.writeFileSync(file, modContent)

  return true;
};