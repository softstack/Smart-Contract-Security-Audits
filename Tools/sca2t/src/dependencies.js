"use strict";

const fs = require('fs')
const parser = require('solidity-parser-antlr')
const path = require('path')
const detectInstalled = require('detect-installed')
const { getInstalledPathSync } = require('get-installed-path')
const moment = require('moment')
//const graphviz = require('graphviz')
//const { linearize } = require('c3-linearization')

let definition = { "contracts": {}, "inheritances": new Array(), "uses": new Array(), "functions": {}, "modifiers": {}, "states": {} }

export function dependencies(files) {
  if (files.length === 0) {
    console.log('No files were specified for analysis in the arguments. Bailing...')
    return
  }

  try {
    for (let file of files) {
      let fileAbsPath = path.resolve(path.join(process.cwd(), file));
      
      // analyze file
      if (!analyze(fileAbsPath)) continue
    }

    // generate report
    const outputFileName = reportGenerate(definition)

    console.log(JSON.stringify(definition, null, 2))
    console.log()
    console.log("successfully generated!")
    console.log("open " + outputFileName + " in browser")
  } catch (e) {
    console.error(e)
    process.exit(1)
  }
}

function analyze(file) {
  let content
  let dependencies = {}
  try {
    content = fs.readFileSync(file).toString('utf-8')
  } catch (e) {
    if (e.code === 'EISDIR') {
      console.error(`Skipping directory ${file}`)
      return false
    } else throw e
  }

  const ast = parser.parse(content)
  let imports = new Map()

  // search all of the contracts on this file.
  parser.visit(ast, {
    ContractDefinition(node) {
      let contractName = node.name;
      if (!definition.contracts[contractName] || definition.contracts[contractName] === null) {
        definition.contracts[contractName] = { 'path': file.replace(/\\/g, '&#92;').replace(/:/g, '&#58;') };
      }
    }
  });

  parser.visit(ast, {
    ImportDirective(node) {
      let contractName = path.parse(node.path).name
      let absPath
      if (node.path.startsWith(".")) {
        let currentDir = path.resolve(path.parse(file).dir)
        absPath = path.resolve(path.join(currentDir, node.path))
      } else {
        let modulesInstalledPath = getModulesInstalledPath(node.path)
        absPath = path.resolve(path.join(modulesInstalledPath, node.path))
      }

      imports.set(contractName, absPath)
    },

    // parse contract
    ContractDefinition(node) {
      let contractName = node.name

      dependencies[contractName] = node.baseContracts.map(spec =>
        spec.baseName.namePath
      )

      for (let i = dependencies[contractName].length - 1; i >= 0; i--) {
        let dep = dependencies[contractName][i]
        if (!definition.contracts[dep]) {
          definition.contracts[dep] = null;
        }

        if (definition.inheritances.indexOf(contractName + "=>" + dep) === -1) {
          definition.inheritances.push(contractName + "=>" + dep)
          if (imports.has(dep)) {
            // recursive
            analyze(imports.get(dep))
          }
        }
      }

      // using list
      let using = [];

      // function list
      let funcDefs = [];

      // modifiers list
      let modifiers = [];

      // states list
      let states = [];

      // visit contract body
      parser.visit(node.subNodes, {
        // add using declaration
        UsingForDeclaration(node) {
          let libraryName = node.libraryName
          using.push(libraryName)
        },

        // add function definition
        FunctionDefinition(node) {
          let funcDef;
          let name;
          if (node.name === null) {
            name = '&quot;constructor&quot;';
          } else if (node.name === '') {
            name = '&quot;fallback&quot;';
          } else {
            name = node.name;
          }
          let visibility = node.visibility;
          let modifiers = node.modifiers;
          let stateMutability = node.stateMutability;
          let isConstructor = node.isConstructor;
          funcDef = { name, visibility, modifiers, stateMutability, isConstructor };
          funcDefs.push(funcDef);
        },

        // add modifier definition
        ModifierDefinition(node) {
          modifiers.push(node.name);
        },

        // add state definition
        StateVariableDeclaration(node) {
          //console.log(Object.getOwnPropertyNames(node));
          console.log(node);

          if(node.variables.length !== 1) {
            throw new Error('Lenght of State Variable is only 1, but ' + node.variables.length);
          }

          let variable = node.variables[0];
          let name = variable.name;
          let visibility = variable.visibility;
          let isConst = variable.isDeclaredConst;
          let typeName = variable.typeName.type;
          let type;
          switch(typeName) {
            case 'ElementaryTypeName':
              type = variable.typeName.name;
              break;
            case 'ArrayTypeName':
              type = 'array';
              break;
            case 'Mapping':
              type = 'mapping';
              break;
            case 'UserDefinedTypeName':
              type = variable.typeName.namePath;
              break;
            default:
              type = typeName;
          }

          states.push({name, type, visibility, isConst})
        },

        // add user defined type contract
        UserDefinedTypeName(node) {
          let name = node.namePath
          if (definition.contracts[name] || imports.has(name)) {
            using.push(name);
          }
        },

        // add member access for like 'ConvertLiv.convert'. In this case, this gets 'ConvertLiv'.
        // Or if it is like 'Token.(_address)', then this gets 'Token'.
        MemberAccess(node) {
          parser.visit(node, {
            Identifier(node) {
              let name = node.name;
              if (definition.contracts[name] || imports.has(name)) {
                using.push(name);
              }
            },
          })
          /*
          let name = node.expression.name;
          if (definition.contracts[name] || imports.has(name)) {
            using.push(name);
          }
          */
        },
      })

      // add functions to definition
      if (!definition.functions[contractName]) {
        definition.functions[contractName] = funcDefs;
      }

      // add modifiers to definition
      if (!definition.modifiers[contractName]) {
        definition.modifiers[contractName] = modifiers;
      }

      // add states to definition
      if (!definition.states[contractName]) {
        definition.states[contractName] = states;
      }

      for (let dep of using) {
        if (!definition.contracts[dep] ) {
          definition.contracts[dep] = null;
        }

        if (definition.uses.indexOf(contractName + "=>" + dep) === -1) {
          definition.uses.push(contractName + "=>" + dep)
          if (imports.has(dep)) {
            // recursive
            analyze(imports.get(dep))
          }
        }
      }
    }
  })
  return true
}

function getModulesInstalledPath(solidityPathStr) { // solidityPathStr is like "openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol"
  let [moduleName] = solidityPathStr.split('/', 1)
  let modulesPath = ''

  // check module locally
  if (detectInstalled.sync(moduleName, { local: true })) {
    let localPath = getInstalledPathSync(moduleName, { local: true })
    modulesPath = localPath.replace(moduleName, "")
    // check module globally
  } else if (detectInstalled.sync(moduleName)) {
    const globalPath = getInstalledPathSync(moduleName)
    modulesPath = globalPath.replace(moduleName, "")
  } else {
    throw new Error(`${moduleName} module is not installed`)
  }

  return modulesPath // eg: "/mytruffle_project/node_modules/"
}

function reportGenerate(definition) {
  // remove CR, LE, and space from definition
  const outputJSON = JSON.stringify(definition).replace(/\r|\n|\s/g, '')

  // load jspulub and jquery
  const jsplumbDefaultsCss = fs.readFileSync(__dirname + '/../node_modules/jsplumb/css/jsplumbtoolkit-defaults.css').toString()
  const jsPlumbJs = fs.readFileSync(__dirname + '/../node_modules/jsplumb/dist/js/jsplumb.min.js').toString()
  const jquery = fs.readFileSync(__dirname + '/../node_modules/jquery/dist/jquery.min.js').toString()

  // load template html
  const template = fs.readFileSync(__dirname + '/../resources/template.html').toString()

  // generate file name.
  const m = moment()
  const timestamp = m.format('YYYYMMDDHHmmss')
  const outputFileName = 'dependencies_' + timestamp + '.html'

  // generate report
  let output = template.replace(/{{definition}}/g, outputJSON)
  output = output.replace(/{{jsplumbtoolkit-defaults.css}}/g, jsplumbDefaultsCss)
  output = output.replace(/{{jsplumb.min.js}}/g, jsPlumbJs)
  output = output.replace(/{{jquery.min.js}}/g, jquery)
  fs.writeFileSync(process.cwd() + path.sep + outputFileName, output)

  return outputFileName
}