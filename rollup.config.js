import includePaths from 'rollup-plugin-includepaths';


const BUNDLE = process.env.BUNDLE === 'true'
const ESM = process.env.ESM === 'true'

const fileDest = `blacklight${ESM ? '.esm' : ''}`
const external = []
const globals = {}

let includePathOptions = {
  include: {},
  paths: ['app/javascript'],
  external: [],
  extensions: ['.js']
};

const rollupConfig = {
  input: 'app/javascript/blacklight-frontend/index.js',
  output: {
    file: `app/assets/javascripts/blacklight/${fileDest}.js`,
    format: ESM ? 'es' : 'umd',
    globals,
    generatedCode: { preset: 'es2015' },
    name: ESM ? undefined : 'Blacklight'
  },
  external,
  plugins: [includePaths(includePathOptions)]
}

export default rollupConfig
