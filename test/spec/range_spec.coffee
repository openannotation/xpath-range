MockSelection = require('../mock-selection')
Range = require('../../src/range')

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

      it "should raise NotFoundError if a node cannot be found", ->
        root = document.createElement('div')
        check = -> r.normalize(root)
        assert.throw(check, 'NotFoundError')

      it "should raise IndexSizeError if an offset is too large", ->
        range.endOffset = 1000
        check = -> range.normalize(fixture.el)
        assert.throw(check, 'IndexSizeError')

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

    describe 'textNodes', ->

      beforeEach ->
        fixture.load('textnodes.html')

      afterEach ->
        fixture.cleanup()

      it "returns an element's textNode descendants", ->
        range = new Range.BrowserRange({
          commonAncestorContainer: fixture.el
          startContainer: fixture.el
          startOffset: 0
          endContainer: fixture.el
          endOffset: fixture.el.childNodes.length
        })

        normedRange = range.normalize(fixture.el)
        nodes = normedRange.textNodes()
        text = (node.nodeValue for node in nodes)

        expectation = [ '\n  '
                      , 'lorem ipsum'
                      , '\n  '
                      , 'dolor sit'
                      , '\n'
                      , 'dolor sit '
                      , 'amet'
                      , '. humpty dumpty. etc.'
                      ]

        assert.deepEqual(text, expectation)

      it "returns an element's TextNodes after Text.splitText() text has been called", ->
        # Build a very csutom fixture to replicate an issue in IE9 where calling
        # split text on an text node does not update the parents .childNodes value
        # which continues to return the unsplit text node.
        fixture.cleanup()

        para = document.createElement('p')
        text = document.createTextNode('this is a paragraph of text')
        para.appendChild(text)
        fixture.el.appendChild(para)

        assert.lengthOf(para.childNodes, 1)
        first = text.splitText(14)

        # Some basic assertions on the split text.
        assert.equal(first.nodeValue, 'graph of text')
        assert.equal(text.nodeValue, 'this is a para')
        assert.equal(para.firstChild.nodeValue, 'this is a para')
        assert.equal(para.lastChild.nodeValue, 'graph of text')

        # Both of the following tests fail in IE9 so we cannot rely on the
        # Text.childNodes property or jQuery.fn.contents() to retrieve the text
        # nodes.
        # assert.lengthOf(para.childNodes, 2)
        # assert.lengthOf($(para).contents(), 2)

        range = new Range.BrowserRange({
          commonAncestorContainer: para,
          startContainer: para,
          startOffset: 0,
          endContainer: para,
          endOffset: para.childNodes.length
        })
        normedRange = range.normalize(para)
        textNodes = normedRange.textNodes()
        assert.lengthOf(textNodes, 2)
