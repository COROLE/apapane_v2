module.exports = {
  env: {
    es2022: true,
    node: true,
  },
  extends: ['eslint:recommended'],
  ignorePatterns: ['node_modules/**'],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'script',
  },
  rules: {
    'no-unused-vars': [
      'error',
      {
        argsIgnorePattern: '^_',
      },
    ],
  },
};
