h = require('helpers')
$ = require('jquery')
Util = require('../../src/util')

describe 'Util.flatten()', ->
  it "flattens the contents of an Array", ->
    flattened = Util.flatten([[1,2], 'lorem ipsum', [{}]])
    assert.deepEqual(flattened, [1, 2, 'lorem ipsum', {}])

describe 'Util.getTextNodes()', ->
  $fix = null

  beforeEach ->
    h.addFixture 'textnodes'
    $fix = $(h.fix())

  afterEach -> h.clearFixtures()

  it "returns an element's textNode descendants", ->
    nodes = Util.getTextNodes($fix)
    text = (node.nodeValue for node in nodes)

    expectation = [ '\n  '
                  , 'lorem ipsum'
                  , '\n  '
                  , 'dolor sit'
                  , '\n'
                  , '\n'
                  , 'dolor sit '
                  , 'amet'
                  , '. humpty dumpty. etc.'
                  ]

    assert.deepEqual(text, expectation)

  it "returns an empty jQuery collection when called in undefined node", ->
    result = Util.getTextNodes($(undefined))
    assert.instanceOf(result, $)
    assert.lengthOf(result, 0)

  it "returns an element's TextNodes after Text.splitText() text has been called", ->
    # Build a very csutom fixture to replicate an issue in IE9 where calling
    # split text on an text node does not update the parents .childNodes value
    # which continues to return the unsplit text node.
    fixture = document.getElementById('fixtures') || $('body')[0]
    fixture.innerHTML = ''

    para = document.createElement('p')
    text = document.createTextNode('this is a paragraph of text')
    para.appendChild(text)
    fixture.appendChild(para)

    assert.lengthOf(para.childNodes, 1)
    first = text.splitText(14)

    # Some basic assertions on the split text.
    assert.equal(first.nodeValue, 'graph of text')
    assert.equal(text.nodeValue, 'this is a para')
    assert.equal(para.firstChild.nodeValue, 'this is a para')
    assert.equal(para.lastChild.nodeValue, 'graph of text')

    # JSDom will only correctly return .text() contents after checking the
    # length of the para.childNodes object. IE9 will only returnt the contents
    # of the first node.
    # assert.equal($(para).text(), 'this is a paragraph of text')

    # Both of the following tests fail in IE9 so we cannot rely on the
    # Text.childNodes property or jQuery.fn.contents() to retrieve the text
    # nodes.
    # assert.lengthOf(para.childNodes, 2)
    # assert.lengthOf($(para).contents(), 2)

    assert.lengthOf(Util.getTextNodes($(para)), 2)

