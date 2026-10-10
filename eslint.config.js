import stylistic from '@stylistic/eslint-plugin'

export default [
  {
    files: ['eslint.config.js', 'rollup.config.js', 'app/javascript/blacklight-frontend/**/*.js'],
    plugins: { '@stylistic': stylistic },
    rules: {
      'no-var': 'error',
      'prefer-const': 'error',
      '@stylistic/indent': ['error', 2],
      '@stylistic/quotes': ['error', 'single', { avoidEscape: true }],
      '@stylistic/semi': ['error', 'never'],
      '@stylistic/no-multiple-empty-lines': ['error', { max: 1 }],
      '@stylistic/space-infix-ops': 'error'
    }
  }
]
