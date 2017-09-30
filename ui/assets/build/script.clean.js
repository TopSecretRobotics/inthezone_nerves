var
  shell = require('shelljs'),
  path = require('path')

shell.rm('-rf', path.resolve(__dirname, '../../priv/static/*'))
shell.rm('-rf', path.resolve(__dirname, '../../priv/static/.*'))
console.log(' Cleaned build artifacts.\n')
