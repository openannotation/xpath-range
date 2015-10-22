var babelify = require('babelify').configure({loose: 'all'})
var isparta = require('isparta')
var istanbul = require('browserify-istanbul')({
  instrumenter: isparta,
  instrumenterConfig: {babel: {loose: 'all'}}
})

module.exports = function(config) {
  config.set({
    basePath: 'test',
    browsers: ['PhantomJS'],
    browserify: {debug: true, transform: [babelify]},
    frameworks: ['browserify', 'fixture', 'mocha'],
    files: [
      'adapter.js',
      'spec/fixtures/*.html',
      'spec/*.js'
    ],
    preprocessors: {
      '**/*.js': ['browserify'],
      '**/*.html': ['html2js']
    },
    reporters: ['progress', 'saucelabs'],
    sauceLabs: {testName: 'XPath Range test'},

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
    var sauceCredentials = require('./sauce.json')
    process.env.SAUCE_USERNAME = sauceCredentials.username
    process.env.SAUCE_ACCESS_KEY = sauceCredentials.accessKey
  } catch (e) {
    console.log('Note: run `git-crypt unlock` to use Sauce Labs credentials.')
  }

  if (process.env.npm_config_coverage) config.set({
    browserify: {debug: true, transform: [istanbul, babelify]},
    coverageReporter: {
      reporters: [
        {'type': 'lcov', 'dir': '../coverage'},
        {'type': 'text'}
      ]
    },
    reporters: ['progress', 'saucelabs', 'coverage', 'coveralls']
  })

  if (process.env.TRAVIS) config.set({
    browsers: [process.env.BROWSER]
  })
}
