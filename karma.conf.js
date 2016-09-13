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
      },
      'SL_Edge': {
        base: 'SauceLabs',
        browserName: 'MicrosoftEdge',
      },
      'SL_Firefox': {
        base: 'SauceLabs',
        browserName: 'firefox',
      },
      'SL_Safari': {
        base: 'SauceLabs',
        browserName: 'safari',
      },
      'SL_IE_8': {
        base: 'SauceLabs',
        browserName: 'internet explorer',
        version: '8'
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
