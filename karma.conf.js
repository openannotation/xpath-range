module.exports = function(config) {
  config.set({
    browsers: ['PhantomJS'],
    browserify: {debug: true, transform: ['babelify']},
    frameworks: ['browserify', 'fixture', 'mocha'],
    files: [
      'test/*.js',
      'test/fixtures/*.html'
    ],
    preprocessors: {
      'test/*.js': ['browserify'],
      'test/fixtures/*.html': ['html2js']
    },
    reporters: ['progress', 'coverage', 'saucelabs'],
    coverageReporter: {
      reporters: [
        {type: 'html', subdir: '.'},
        {type: 'json', subdir: '.'},
        {type: 'lcovonly', subdir: '.'},
        {type: 'text', subdir: '.'}
      ]
    },
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

  if (process.env.TRAVIS) config.set({
    browsers: [process.env.BROWSER]
  })
}
