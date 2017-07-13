const yargs = require('yargs');

module.exports = yargs
  .usage('Usage: videotape [args]', {
    target: {
      description: 'The name of the target process',
      alias: 't',
    },
    verbose: {
      description: 'Print all debug output from the app',
      boolean: true,
      alias: 'v',
    },
    http: {
      description: 'Whether to stop automatically or not',
      boolean: true,
      alias: 'h',
    },
    autorun: {
      description: 'Capture only one segment automatically and exit aftewards',
      boolean: true,
      alias: 'a',
    },
  })
  // .command(
  //   'record',
  //   'Observe the target process for frames changing and recording that'
  // )
  .example(
    'videotape --target Simulator',
    'Records first meaningful 100 frames on 60fps (1.6 seconds) of iossimulator or stop it automatically after the first pause'
  )
  .epilog('for more information visit https://16ms.github.io/videotape').argv;
