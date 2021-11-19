'use strict'

const path = require('path')

const BUNDLE = process.env.BUNDLE === 'true'
const ESM = process.env.ESM === 'true'

const fileDest = `blacklight${ESM ? '.esm' : ''}`
const external = ['typeahead.js/dist/bloodhound.js']
const globals = {
  'typeahead.js/dist/bloodhound.js': 'Bloodhound'
}

const rollupConfig = {
  input: path.resolve(__dirname, `app/javascript/blacklight/index.js`),
  output: {
    file: path.resolve(__dirname, `app/assets/javascripts/blacklight/${fileDest}.js`),
    format: ESM ? 'esm' : 'umd',
    globals,
    generatedCode: 'es2015'
  },
  external
}

if (!ESM) {
  rollupConfig.output.name = 'Blacklight'
}

module.exports = rollupConfig
