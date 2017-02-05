#!/usr/bin/env node
const flags = process.env.FLAGS.split(' ').filter((v) => v != '');
// Munge the command line arguments to be what TSC expects.
process.argv =
    [process.argv[1], 'exec',
        //'--sourceMap',
        //'--module', 'amd',
        //'--allowJs',
        //'--moduleResolution', 'node',
        //'--traceResolution',
    ]
        .concat(flags)  // All the input files
        //.concat(['--outFile'])
        //.concat(process.argv.slice(2))
    ;

require('typescript/lib/tsc.js')
