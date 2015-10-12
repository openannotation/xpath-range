var babelify = require('babelify');
var isparta = require('isparta');
var istanbul = require('browserify-istanbul')({
  ignore: ['**/node_modules/**', '**/test/**'],
  instrumenter: isparta
});

module.exports = function(config) {
  config.set({
    basePath: 'test',
    browsers: ['PhantomJS'],
    frameworks: ['browserify', 'fixture', 'mocha'],
    files: [
      'spec/fixtures/*.html',
      'spec/*.js'
    ],
    preprocessors: {
      '**/*.js': ['browserify'],
      '**/*.html': ['html2js']
    },
    reporters: ['progress', 'coverage'],
    coverageReporter: {
      reporters: [
        {type: 'lcov'},
        {type: 'text'}
      ]
    },
    browserify: {
      debug: true,
      transform: [istanbul, babelify]
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
