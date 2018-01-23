module.exports = function(config) {
  config.set({
    frameworks: ['mocha', 'chai', 'sinon', 'browserify' ],

    preprocessors: {
      '**/*.coffee': [ 'browserify' ]
    },

    reporters: [
      'spec'
    ],

    browserify: {
      ignoreMissing: true,
      transform: [ 'coffeeify' ],
      extensions: ['.coffee']
    },

    files: [
      'test/WeaverFile.test.coffee'
    ],

    exclude: [
      'test/WeaverRESTAPI.test.coffee'
    ],

    client: {
      captureConsole: false,
      mocha: {
        opts: 'test/mocha.opts'
      }
    },

    port: 9876,  // karma web server port
    colors: true,
    logLevel: config.INFO,
    browsers: ['ChromeHeadless'],
    autoWatch: false,
    singleRun: true,
    concurrency: Infinity
  })
}
