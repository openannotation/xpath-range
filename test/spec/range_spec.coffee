MockSelection = require('../mock-selection')

Range = require('../../src/range')
Util = require('../../src/util')

testData = [
  [ 0,           13,  0,           27,  "habitant morbi",                                    "Partial node contents." ]
  [ 0,           0,   0,           37,  "Pellentesque habitant morbi tristique",             "Full node contents, textNode refs." ]
  [ '/p/strong', 0,   '/p/strong', 1,   "Pellentesque habitant morbi tristique",             "Full node contents, elementNode refs." ]
  [ 0,           22,  1,           12,  "morbi tristique senectus et",                       "Spanning 2 nodes." ]
  [ '/p/strong', 0,   1,           12,  "Pellentesque habitant morbi tristique senectus et", "Spanning 2 nodes, elementNode start ref." ]
  [ 1,           165, '/p/em',     1,   "egestas semper. Aenean ultricies mi vitae est.",    "Spanning 2 nodes, elementNode end ref." ]
  [ 8,           7,   10,          11,  "Level 2\n  Lorem ipsum",                            "Spanning multiple nodes, textNode refs." ]
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
]

describe 'Range', ->
  r = null
  mockSelection = null

  beforeEach ->
    fixture.load('range.html')
    mockSelection = (ii) -> new MockSelection(fixture.el, testData[ii])

  afterEach ->
    fixture.cleanup()

  describe "SerializedRange", ->
    beforeEach ->
      r = new Range.SerializedRange
        start: "/p/strong"
        startOffset: 13
        end: "/p/strong"
        endOffset: 27

    describe "normalize", ->
      it "should return a normalized range", ->
        norm = r.normalize(fixture.el)
        assert.isTrue(norm instanceof Range.NormalizedRange)
        assert.equal(norm.text(), "habitant morbi")

      it "should return a normalized range with 0 offsets", ->
        r.startOffset = 0
        norm = r.normalize(fixture.el)
        assert.isTrue(norm instanceof Range.NormalizedRange)
        assert.equal(norm.text(), "Pellentesque habitant morbi")

      it "with the start property == first text node in the range", ->
        # Split the targeted text ("Pellentesque...tristique") into textnodes of
        # width 1.
        node = fixture.el.firstChild.firstChild.firstChild
        while node.data.length > 1
          node = node.splitText(1)

        norm = r.normalize(fixture.el)
        assert.equal(norm.start.data, 'h')

      it "with the end property == last text node (inclusive) of the range", ->
        # Split the targeted text ("Pellentesque...tristique") into textnodes of
        # width 1.
        node = fixture.el.firstChild.firstChild.firstChild
        while node.data.length > 1
          node = node.splitText(1)

        norm = r.normalize(fixture.el)
        assert.equal(norm.end.data, 'i')

      it "should raise Range.RangeError if it cannot normalize the range", ->
        root = document.createElement('div')
        check = -> r.normalize(root)
        assert.throw(check, Range.RangeError)

    it "serialize() returns a serialized range", ->
      seri = r.serialize(fixture.el)
      assert.equal(seri.start, "/p[1]/strong[1]")
      assert.equal(seri.startOffset, 13)
      assert.equal(seri.end, "/p[1]/strong[1]")
      assert.equal(seri.endOffset, 27)
      assert.isTrue(seri instanceof Range.SerializedRange)

    it "toObject() returns a simple object", ->
      obj = r.toObject()
      assert.equal(obj.start, "/p/strong")
      assert.equal(obj.startOffset, 13)
      assert.equal(obj.end, "/p/strong")
      assert.equal(obj.endOffset, 27)
      assert.equal(JSON.stringify(obj), '{"start":"/p/strong","startOffset":13,"end":"/p/strong","endOffset":27}')

  describe "BrowserRange", ->
    beforeEach ->
      sel = mockSelection(0)
      r = new Range.BrowserRange(sel.getRangeAt(0))

    it "normalize() returns a normalized range", ->
      norm = r.normalize()
      assert.instanceOf(norm, Range.NormalizedRange)

    testBrowserRange = (i) ->
      ->
        sel   = mockSelection(i)
        range = new Range.BrowserRange(sel.getRangeAt(0))
        norm  = range.normalize(fixture.el)
        assert.equal(norm.text(), sel.expectation)

    for i in [0...testData.length]
      it "should parse test range #{i} (#{testData[i][5]})", testBrowserRange(i)

  describe "NormalizedRange", ->
    sel = null

    beforeEach ->
      sel = mockSelection(7)
      browserRange = new Range.BrowserRange(sel.getRangeAt(0))
      r = browserRange.normalize()

    it "textNodes() returns an array of textNodes", ->
      textNodes = r.textNodes()

      assert.isArray(textNodes)
      assert.lengthOf(textNodes, sel.endOffset)

      # Should contain the contents of the first <strong> element.
      assert.equal(textNodes[0].nodeValue, 'Pellentesque habitant morbi tristique')

    it "text() returns the textual contents of the range", ->
      assert.equal(r.text(), sel.expectation)

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
        range = new Range.NormalizedRange({
          commonAncestor: para
          start: paraText
          end: paraText2
        })

        range = range.limit(para)
        assert.equal(range.commonAncestor, para)
        assert.equal(range.start, paraText)
        assert.equal(range.end, paraText2)

      it "should exclude any nodes to the left of the bounding element.", ->
        range = new Range.NormalizedRange({
          commonAncestor: root
          start: headText
          end: paraText2
        })

        range = range.limit(para)
        assert.equal(range.commonAncestor, para)
        assert.equal(range.start, paraText)
        assert.equal(range.end, paraText2)

      it "should exclude any nodes to the right of the bounding element.", ->
        range = new Range.NormalizedRange({
          commonAncestor: root
          start: paraText
          end: para2Text
        })

        range = range.limit(para)
        assert.equal(range.commonAncestor, para)
        assert.equal(range.start, paraText)
        assert.equal(range.end, paraText3)

      it "should exclude any nodes on either side of the bounding element.", ->
        range = new Range.NormalizedRange({
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
        range = new Range.NormalizedRange({
          commonAncestor: root
          start: headText
          end: paraText2
        })
        assert.equal(range.limit(otherDiv), null)
