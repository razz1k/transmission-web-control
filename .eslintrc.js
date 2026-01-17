module.exports = {
  env: {
    browser: true,
    es6: true
  },
  extends: [
    'eslint:recommended'
  ],
  globals: {
    '$': 'readonly',
    'jQuery': 'readonly',
    'system': 'readonly',
    'transmission': 'readonly',
    'Base64': 'readonly',
    'console': 'readonly'
  },
  parserOptions: {
    ecmaVersion: 5,
    sourceType: 'script'
  },
  rules: {
    'no-unused-vars': ['warn', { 
      'argsIgnorePattern': '^_',
      'varsIgnorePattern': '^_'
    }],
    'no-console': 'off',
    'no-undef': 'warn',
    'semi': ['error', 'always'],
    'quotes': ['error', 'single', { 'avoidEscape': true }]
  },
  ignorePatterns: [
    '**/min/**',
    '**/jquery/**',
    '**/easyui/**',
    '**/plugins/**',
    '**/other/**',
    '**/*.min.js'
  ]
};
