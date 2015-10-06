xpath = require('../../src/xpath')

describe 'xpath', ->

  beforeEach ->
    fixture.load('xpath.html')

  afterEach ->
    fixture.cleanup()

  describe '#fromNode', ->

    it "generates an XPath string for an element's position in the document", ->
      # FIXME: this is quite fragile. A change to dom.html may well break these tests and the
      #        resulting xpaths will need to be changed.

      pathToFixHTML = '/html[1]/body[1]/div[1]'

      pEl = fixture.el.getElementsByTagName('p')[0]
      pPath = pathToFixHTML + '/p[1]'
      assert.equal(xpath.fromNode(pEl), pPath)

      spanEl = fixture.el.getElementsByTagName('span')[0]
      spanPath = pathToFixHTML + '/ol[1]/li[2]/span[1]'
      assert.equal(xpath.fromNode(spanEl), spanPath)

      strongEl = fixture.el.getElementsByTagName('strong')[0]
      strongPath = pathToFixHTML + '/p[2]/strong[1]'
      assert.equal(xpath.fromNode(strongEl), strongPath)

    it "takes an optional parameter determining the element from which XPaths should be calculated", ->
      ol = fixture.el.getElementsByTagName('ol')[0]
      li = fixture.el.getElementsByTagName('li')[0]
      assert.deepEqual(xpath.fromNode(li, ol), '/li[1]')

      span = fixture.el.getElementsByTagName('span')[0]
      assert.deepEqual(xpath.fromNode(span, ol), '/li[2]/span[1]')

    it 'should raise InvalidNodeTypeError if root does not contain node', ->
      node = document.createElement('div')
      check = -> xpath.fromNode(node, fixture.el)
      assert.throw(check, 'InvalidNodeTypeError')

  describe "#toNode()", ->
    path = "/p[2]/strong"
    it "should parse a standard xpath string", ->
      node = xpath.toNode path, fixture.el
      strong = document.getElementsByTagName('strong')[0]
      assert.strictEqual(node, strong)
