// Karma configuration
// Generated on Tue Sep 29 2015 18:21:14 GMT-0700 (PDT)

module.exports = function(config) {
  config.set({

    // base path that will be used to resolve all patterns (eg. files, exclude)
    basePath: 'test',


    // frameworks to use
    // available frameworks: https://npmjs.org/browse/keyword/karma-adapter
    frameworks: ['browserify', 'fixture', 'chai', 'mocha'],


    // list of files / patterns to load in the browser
    files: [
      'spec/fixtures/*.html',
      'spec/*.js'
    ],


    // list of files to exclude
    exclude: [
    ],


    // preprocess matching files before serving them to the browser
    // available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {
      '**/*.js': ['browserify'],
      '**/*.html': ['html2js']
    },


    // test results reporter to use
    // possible values: 'dots', 'progress'
    // available reporters: https://npmjs.org/browse/keyword/karma-reporter
    reporters: ['progress'],


    // web server port
    port: 9876,


    // enable / disable colors in the output (reporters and logs)
    colors: true,


    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,


    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,


    // start these browsers
    // available browser launchers: https://npmjs.org/browse/keyword/karma-launcher
    browsers: ['PhantomJS'],


    // Continuous Integration mode
    // if true, Karma captures browsers, runs the tests and exits
    singleRun: false,


    // Browserify configuration
    browserify: {
      debug: true,
      transform: [
        ['babelify', {loose: 'all'}]
      ]
    },

    // Custom browser configurations for Sauce Labs.
    customLaunchers: {
      'SL_Chrome': {
        base: 'SauceLabs',
        browserName: 'chrome',
        version: '41'
      },
      'SL_Firefox': {
        base: 'SauceLabs',
        browserName: 'firefox',
        version: '36'
      },
      'SL_Safari': {
        base: 'SauceLabs',
        browserName: 'safari',
        platform: 'OS X 10.10',
        version: '8'
      },
      'SL_IE_8': {
        base: 'SauceLabs',
        browserName: 'internet explorer',
        platform: 'Windows 7',
        version: '8'
      },
      'SL_IE_9': {
        base: 'SauceLabs',
        browserName: 'internet explorer',
        platform: 'Windows 7',
        version: '9'
      },
      'SL_IE_10': {
        base: 'SauceLabs',
        browserName: 'internet explorer',
        platform: 'Windows 8',
        version: '10'
      },
      'SL_IE_11': {
        base: 'SauceLabs',
        browserName: 'internet explorer',
        platform: 'Windows 8.1',
        version: '11'
      }
    }
  })

  try {
    var sauceCredentials = require('./sauce.json');
    process.env.SAUCE_USERNAME = sauceCredentials.username;
    process.env.SAUCE_ACCESS_KEY = sauceCredentials.accessKey;
  } catch (e) {
    console.log('Note: run `git-crypt unlock` to use Sauce Labs credentials.');
  }

  if (process.env.SAUCE_USERNAME) {
    config.browserNoActivityTimeout = 30 * 1000;
    config.sauceLabs = {
      testName: 'XPath Range test',
    };
  }

  if (process.env.TRAVIS) {
    config.browsers = [process.env.BROWSER];
    config.reporters = ['dots', 'saucelabs'];
    config.singleRun = true;
  }
}
