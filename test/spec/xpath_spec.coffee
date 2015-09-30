h = require('helpers')
xpath = require('../../src/xpath')

describe 'xpath', ->
  fix = null

  beforeEach ->
    h.addFixture 'xpath'
    fix = h.fix()

  afterEach ->
    h.clearFixtures()

  describe '#fromNode', ->

    it "generates an XPath string for an element's position in the document", ->
      # FIXME: this is quite fragile. A change to dom.html may well break these tests and the
      #        resulting xpaths will need to be changed.

      pathToFixHTML = '/html[1]/body[1]/div[1]'

      pEl = fix.getElementsByTagName('p')[0]
      pPath = pathToFixHTML + '/p[1]'
      assert.equal(xpath.fromNode(pEl), pPath)

      spanEl = fix.getElementsByTagName('span')[0]
      spanPath = pathToFixHTML + '/ol[1]/li[2]/span[1]'
      assert.equal(xpath.fromNode(spanEl), spanPath)

      strongEl = fix.getElementsByTagName('strong')[0]
      strongPath = pathToFixHTML + '/p[2]/strong[1]'
      assert.equal(xpath.fromNode(strongEl), strongPath)

    it "takes an optional parameter determining the element from which XPaths should be calculated", ->
      ol = fix.getElementsByTagName('ol')[0]
      li = fix.getElementsByTagName('li')[0]
      assert.deepEqual(xpath.fromNode(li, ol), '/li[1]')

      span = fix.getElementsByTagName('span')[0]
      assert.deepEqual(xpath.fromNode(span, ol), '/li[2]/span[1]')

  describe "#toNode()", ->
    path = "/p[2]/strong"
    it "should parse a standard xpath string", ->
      node = xpath.toNode path, fix
      strong = document.getElementsByTagName('strong')[0]
      assert.equal(node, strong)

    xit "should parse an standard xpath string for an xml document", ->
      $.isXMLDoc = -> true
      node = xpath.toNode path, $fix[0]
      assert.equal(node, $('strong')[0])
