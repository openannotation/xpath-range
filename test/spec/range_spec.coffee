{NormalizedRange, SerializedRange} = require('../../src/range')
{normalizeBoundaries, splitBoundaries} = require('../../src/range')
xpath = require('../../src/xpath')

createRange = (i) ->
  data = testData[i]
  startContainer = xpath.toNode(data[0], fixture.el)
  startOffset    = data[1]
  endContainer   = xpath.toNode(data[2], fixture.el)
  endOffset      = data[3]

  range = document.createRange()
  range.setStart(startContainer, startOffset)
  range.setEnd(endContainer, endOffset)
  return range

testData = [
  [ '/p/strong/text()', 13,  '/p/strong/text()', 27, "habitant morbi",                                     "Partial node contents." ]
  [ '/p/strong/text()', 0,   '/p/strong/text()', 37, "Pellentesque habitant morbi tristique",              "Full node contents, textNode refs." ]
  [ '/p/strong',        0,   '/p/strong',        1,  "Pellentesque habitant morbi tristique",              "Full node contents, elementNode refs." ]
  [ '/p/strong/text()', 22,  '/p/text()',        12, "morbi tristique senectus et",                        "Spanning 2 nodes." ]
  [ '/p/strong',        0,   '/p/text()',        12, "Pellentesque habitant morbi tristique senectus et",  "Spanning 2 nodes, elementNode start ref." ]
  [ '/p/text()',        165, '/p/em',            1,  "egestas semper. Aenean ultricies mi vitae est.",     "Spanning 2 nodes, elementNode end ref." ]
  [ '/h2/text()',       7,   '/ol/li/text()',    11, "Level 2\n  Lorem ipsum",                             "Spanning multiple nodes, textNode refs." ]
  [ '/p',        0,   '/p',        8,   "Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor sit amet, ante. Donec eu libero sit amet quam egestas semper. Aenean ultricies mi vitae est. Mauris placerat eleifend leo. Quisque sit amet est et sapien ullamcorper pharetra. Vestibulum erat wisi, condimentum sed, commodo vitae, ornare sit amet, wisi. Aenean fermentum, elit eget tincidunt condimentum, eros ipsum rutrum orci, sagittis tempus lacus enim ac dui. Donec non enim in turpis pulvinar facilisis. Ut felis.", "Spanning multiple nodes, elementNode refs." ]
  [ '/p[2]',     0,   '/p[2]',     1,   "Lorem sed do eiusmod tempor.",                      "Full node contents with empty node at end."]
  [ "/div/text()[2]",0,"/div/text()[2]",28,"Lorem sed do eiusmod tempor.",                   "Text between br tags, textNode refs"]
  [ "/div/text()[2]",0,"/div",     4,"Lorem sed do eiusmod tempor.",                         "Text between br tags, elementNode ref at end"]
  [ "/div/text()[2]",0,"/div",     5,"Lorem sed do eiusmod tempor.",                         "Text between br tags, with <br/> at end"]
  [ "/div/text()[2]",0,"/div",     6,"Lorem sed do eiusmod tempor.",                         "Text between br tags, with <br/><br/> at end"]
  [ "/div/text()[2]",0,"/div",     7,"Lorem sed do eiusmod tempor.",                         "Text between br tags, with <br/><br/><br/> at end"]
  [ "/div",      3,"/div/text()[2]",28,"Lorem sed do eiusmod tempor.",                       "Text between br tags, elementNode ref at start"]
  [ "/div",      2,"/div/text()[2]",28,"Lorem sed do eiusmod tempor.",                       "Text between br tags, with <br/> at start"]
  [ "/div",      1,"/div/text()[2]",28,"Lorem sed do eiusmod tempor.",                       "Text between br tags, with <br/><br/> at start"]
  [ "/div[2]/text()[2]",0,"/div[2]/text()[2]",28,"Lorem sed do eiusmod tempor.",             "Text between br tags, textNode refs"]
  [ "/div[2]/text()[2]",0,"/div[2]",4,"Lorem sed do eiusmod tempor.",                        "Text between br tags, elementNode ref at end"]
  [ "/div[2]/text()[2]",0,"/div[2]",5,"Lorem sed do eiusmod tempor.",                        "Text between br tags, with <br/> at end"]
  [ "/div[2]/text()[2]",0,"/div[2]",6,"Lorem sed do eiusmod tempor.",                        "Text between br tags, with <br/><p><br/></p> at end"]
  [ "/div[2]/text()[2]",0,"/div[2]",7,"Lorem sed do eiusmod tempor.",                        "Text between br tags, with <br/><p><br/></p><br/> at end"]
  [ "/div[2]",   3,"/div[2]/text()[2]",28,"Lorem sed do eiusmod tempor.",                    "Text between br tags, elementNode ref at start"]
  [ "/div[2]",   2,"/div[2]/text()[2]",28,"Lorem sed do eiusmod tempor.",                    "Text between br tags, with <p><br/></p> at the start"]
  [ "/div[2]",   1,"/div[2]/text()[2]",28,"Lorem sed do eiusmod tempor.",                    "Text between br tags, with <br/><p><br/></p> at the start"],
  [ "/h2[2]",    0,"/p[4]", 0, "Header Level 2\n  Mauris lacinia ipsum nulla, id iaculis quam egestas quis.\n", "No text node at the end and offset 0"]
  [ "/p[1]/strong[1]",       1,  "/p[1]/text()[1]", 9, " senectus",                          "Text with start at sibling boundary."]
  [ "/p[1]/em[1]/text()[1]", 20, "/p[1]",           3, "vitae est.",                         "Text with end at sibling boundary."]
]

describe "SerializedRange", ->
  range = null

  beforeEach ->
    fixture.load('range.html')
    range = new SerializedRange
      start: "/p/strong"
      startOffset: 13
      end: "/p/strong"
      endOffset: 27

  afterEach ->
    fixture.cleanup()

  describe "normalize", ->
    it "should return a normalized range", ->
      norm = range.normalize(fixture.el)
      assert.isTrue(norm instanceof NormalizedRange)
      assert.equal(norm.text(), "habitant morbi")

    it "should return a normalized range with 0 offsets", ->
      range.startOffset = 0
      norm = range.normalize(fixture.el)
      assert.isTrue(norm instanceof NormalizedRange)
      assert.equal(norm.text(), "Pellentesque habitant morbi")

    it "with the start property == first text node in the range", ->
      # Split the targeted text ("Pellentesque...tristique") into textnodes of
      # width 1.
      node = fixture.el.firstChild.firstChild.firstChild
      while node.data.length > 1
        node = node.splitText(1)

      norm = range.normalize(fixture.el)
      assert.equal(norm.start.data, 'h')

    it "with the end property == last text node (inclusive) of the range", ->
      # Split the targeted text ("Pellentesque...tristique") into textnodes of
      # width 1.
      node = fixture.el.firstChild.firstChild.firstChild
      while node.data.length > 1
        node = node.splitText(1)

      norm = range.normalize(fixture.el)
      assert.equal(norm.end.data, 'i')

    it "should raise NotFoundError if a node cannot be found", ->
      root = document.createElement('div')
      check = -> range.normalize(root)
      assert.throw(check, 'NotFoundError')

    it "should raise IndexSizeError if an offset is too large", ->
      range.endOffset = 1000
      check = -> range.normalize(fixture.el)
      assert.throw(check, 'IndexSizeError')

  it "serialize() returns a serialized range", ->
    seri = range.serialize(fixture.el)
    assert.equal(seri.start, "/p[1]/strong[1]")
    assert.equal(seri.startOffset, 13)
    assert.equal(seri.end, "/p[1]/strong[1]")
    assert.equal(seri.endOffset, 27)


describe "normalizing a Range", ->
  beforeEach ->
    fixture.load('range.html')

  afterEach ->
    fixture.cleanup()

  testNormalization = (i) ->
    ->
      range = createRange(i)
      splitBoundaries(range)
      normalizeBoundaries(range)
      assert.equal(range.toString(), testData[i][4], testData[i][5])

  for i in [0...testData.length]
    it "should parse test range #{i} (#{testData[i][5]})", testNormalization(i)

describe "NormalizedRange", ->
  range = null

  beforeEach ->
    fixture.load('range.html')
    range = createRange(7)
    splitBoundaries(range)
    normalizeBoundaries(range)

  afterEach ->
    fixture.cleanup()

  describe "limit", ->
    headText = null
    paraText = null
    paraText2 = null
    paraText3 = null
    para2Text = null
    para = null
    root = null

    beforeEach ->
      headText  = document.createTextNode("My Heading")
      paraText  = document.createTextNode("My paragraph")
      paraText2 = document.createTextNode(" conti")
      paraText3 = document.createTextNode("nues")
      para2Text = document.createTextNode("Another paragraph begins")

      head = document.createElement('h1')
      head.appendChild(headText)
      para = document.createElement('p')
      para.appendChild(paraText)
      span = document.createElement('span')
      span.appendChild(paraText2)
      span.appendChild(paraText3)
      para.appendChild(span)
      para2 = document.createElement('p')
      para2.appendChild(para2Text)

      root = document.createElement('div')
      root.appendChild(head)
      root.appendChild(para)
      root.appendChild(para2)

    it "should be a no-op if all nodes are within the bounding element.", ->
      range = new NormalizedRange({
        commonAncestor: para
        start: paraText
        end: paraText2
      })

      range = range.limit(para)
      assert.equal(range.commonAncestor, para)
      assert.equal(range.start, paraText)
      assert.equal(range.end, paraText2)

    it "should exclude any nodes to the left of the bounding element.", ->
      range = new NormalizedRange({
        commonAncestor: root
        start: headText
        end: paraText2
      })

      range = range.limit(para)
      assert.equal(range.commonAncestor, para)
      assert.equal(range.start, paraText)
      assert.equal(range.end, paraText2)

    it "should exclude any nodes to the right of the bounding element.", ->
      range = new NormalizedRange({
        commonAncestor: root
        start: paraText
        end: para2Text
      })

      range = range.limit(para)
      assert.equal(range.commonAncestor, para)
      assert.equal(range.start, paraText)
      assert.equal(range.end, paraText3)

    it "should exclude any nodes on either side of the bounding element.", ->
      range = new NormalizedRange({
        commonAncestor: root
        start: headText
        end: para2Text
      })

      range = range.limit(para)
      assert.equal(range.commonAncestor, para)
      assert.equal(range.start, paraText)
      assert.equal(range.end, paraText3)

    it "should return null if no nodes fall within the bounds", ->
      otherDiv = document.createElement('div')
      range = new NormalizedRange({
        commonAncestor: root
        start: headText
        end: paraText2
      })
      assert.equal(range.limit(otherDiv), null)
