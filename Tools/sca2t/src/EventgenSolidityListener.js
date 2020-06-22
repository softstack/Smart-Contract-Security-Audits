'use strict';

const SolidityListener = require('./SolidityListener').SolidityListener;

class EventgenSolidityListener extends SolidityListener {

  constructor(token, parser) {
    super();
    this.token = token;
    this.parser = parser;
    this.functions = new Array();
    this.contracts = new Map();
    this.contractNames = new Array();
    this.currentContract;
  }

  enterContractDefinition(ctx) {
    if (ctx.contractPart()[0] === undefined) {
      //throw new Error("No contractpart.");
      return; // if empty, do nothing.
    }

    let name = ctx.identifier().getText();
    if (this.contractNames.indexOf((name) === -1)) {
      let bodyStart = ctx.contractPart()[0].start.start;
      let bodyEnd = ctx.contractPart()[ctx.contractPart().length - 1].stop.stop;
      let functions = [];
      this.contracts[name] = { bodyStart, bodyEnd, functions };
      this.contractNames.push(name);
      this.currentContract = name;
    }
  }

  enterFunctionDefinition(ctx) {
    // if pure function, do nothing.
    if (ctx.modifierList() !== null && ctx.modifierList().children !== null) {
      const modifierList = ctx.modifierList().children.map(child => child.getText());
      //if (modifierList.indexOf('pure') > -1 || modifierList.indexOf('view') > -1) return;
      if (modifierList.indexOf('pure') > -1 ) return;
    }

    // if no block, do nothing.
    if (ctx.block() === null) {
      return;
    }

    let name = ctx.identifier() === null ? 'fallbackfunction' : ctx.identifier().getText();
    let bodyStart = ctx.block().start.start;
    let bodyEnd = ctx.block().stop.stop;
    let isEmpty = false;
    if (ctx.block().getText().length === 2) {  // like "{}"
      isEmpty = true;
    }
    this.contracts[this.currentContract].functions.push({ name, bodyStart, bodyEnd, isEmpty });
  }

  enterConstructorDefinition(ctx) {
    // if no block, skip
    if (ctx.block() === null) {
      return;
    }

    let name = 'constructor';
    let bodyStart = ctx.block().start.start;
    let bodyEnd = ctx.block().stop.stop;
    let isEmpty = false;

    if (ctx.block().getText().length === 2) {  // like "{}"
      isEmpty = true;
    }

    this.contracts[this.currentContract].functions.push({ name, bodyStart, bodyEnd, isEmpty});
  }

  enterModifierDefinition(ctx) {
    let name = ctx.identifier().getText();
    let bodyStart = ctx.block().start.start;
    let bodyEnd = ctx.block().stop.stop;
    let isEmpty = false;
    if (ctx.block().getText().length === 2) {  // like "{}"
      isEmpty = true;
    }
    this.contracts[this.currentContract].functions.push({ name, bodyStart, bodyEnd, isEmpty });
  }
}

exports.EventgenSolidityListener = EventgenSolidityListener;