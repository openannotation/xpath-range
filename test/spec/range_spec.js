import {assert} from 'assertive-chai'
import rangy from 'rangy'
rangy.shim()

import {normalizeBoundaries, splitBoundaries} from '../../src/range'
import {limit, serialize, deserialize} from '../../src/range'
import * as xpath from '../../src/xpath'

function createRange(i) {
  let data = testData[i]
  let startContainer = xpath.toNode(data[0], fixture.el)
  let startOffset    = data[1]
  let endContainer   = xpath.toNode(data[2], fixture.el)
  let endOffset      = data[3]
  let range = document.createRange()
  range.setStart(startContainer, startOffset)
  range.setEnd(endContainer, endOffset)
  return range
}

const testData = [
  ['/p/strong/text()', 13,  '/p/strong/text()', 27, "habitant morbi",                                     "Partial node contents."],
  ['/p/strong/text()', 0,   '/p/strong/text()', 37, "Pellentesque habitant morbi tristique",              "Full node contents, textNode refs."],
  ['/p/strong',        0,   '/p/strong',        1,  "Pellentesque habitant morbi tristique",              "Full node contents, elementNode refs."],
  ['/p/strong/text()', 22,  '/p/text()',        12, "morbi tristique senectus et",                        "Spanning 2 nodes."],
  ['/p/strong',        0,   '/p/text()',        12, "Pellentesque habitant morbi tristique senectus et",  "Spanning 2 nodes, elementNode start ref."],
  ['/p/text()',        165, '/p/em',            1,  "egestas semper. Aenean ultricies mi vitae est.",     "Spanning 2 nodes, elementNode end ref."],
  ['/h2/text()',       7,   '/ol/li/text()',    11, "Level 2\n  Lorem ipsum",                             "Spanning multiple nodes, textNode refs."],
  ['/p',        0,   '/p',        8,   "Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor sit amet, ante. Donec eu libero sit amet quam egestas semper. Aenean ultricies mi vitae est. Mauris placerat eleifend leo. Quisque sit amet est et sapien ullamcorper pharetra. Vestibulum erat wisi, condimentum sed, commodo vitae, ornare sit amet, wisi. Aenean fermentum, elit eget tincidunt condimentum, eros ipsum rutrum orci, sagittis tempus lacus enim ac dui. Donec non enim in turpis pulvinar facilisis. Ut felis.", "Spanning multiple nodes, elementNode refs."],
  ['/p[2]',     0,   '/p[2]',     1,   "Lorem sed do eiusmod tempor.",                      "Full node contents with empty node at end."],
  ["/div/text()[2]",0,"/div/text()[2]",28,"Lorem sed do eiusmod tempor.",                   "Text between br tags, textNode refs"],
  ["/div/text()[2]",0,"/div",     4,"Lorem sed do eiusmod tempor.",                         "Text between br tags, elementNode ref at end"],
  ["/div/text()[2]",0,"/div",     5,"Lorem sed do eiusmod tempor.",                         "Text between br tags, with <br/> at end"],
  ["/div/text()[2]",0,"/div",     6,"Lorem sed do eiusmod tempor.",                         "Text between br tags, with <br/><br/> at end"],
  ["/div/text()[2]",0,"/div",     7,"Lorem sed do eiusmod tempor.",                         "Text between br tags, with <br/><br/><br/> at end"],
  ["/div",      3,"/div/text()[2]",28,"Lorem sed do eiusmod tempor.",                       "Text between br tags, elementNode ref at start"],
  ["/div",      2,"/div/text()[2]",28,"Lorem sed do eiusmod tempor.",                       "Text between br tags, with <br/> at start"],
  ["/div",      1,"/div/text()[2]",28,"Lorem sed do eiusmod tempor.",                       "Text between br tags, with <br/><br/> at start"],
  ["/div[2]/text()[2]",0,"/div[2]/text()[2]",28,"Lorem sed do eiusmod tempor.",             "Text between br tags, textNode refs"],
  ["/div[2]/text()[2]",0,"/div[2]",4,"Lorem sed do eiusmod tempor.",                        "Text between br tags, elementNode ref at end"],
  ["/div[2]/text()[2]",0,"/div[2]",5,"Lorem sed do eiusmod tempor.",                        "Text between br tags, with <br/> at end"],
  ["/div[2]/text()[2]",0,"/div[2]",6,"Lorem sed do eiusmod tempor.",                        "Text between br tags, with <br/><p><br/></p> at end"],
  ["/div[2]/text()[2]",0,"/div[2]",7,"Lorem sed do eiusmod tempor.",                        "Text between br tags, with <br/><p><br/></p><br/> at end"],
  ["/div[2]",   3,"/div[2]/text()[2]",28,"Lorem sed do eiusmod tempor.",                    "Text between br tags, elementNode ref at start"],
  ["/div[2]",   2,"/div[2]/text()[2]",28,"Lorem sed do eiusmod tempor.",                    "Text between br tags, with <p><br/></p> at the start"],
  ["/div[2]",   1,"/div[2]/text()[2]",28,"Lorem sed do eiusmod tempor.",                    "Text between br tags, with <br/><p><br/></p> at the start"],
  ["/h2[2]",    0,"/p[4]", 0, "Header Level 2\n  Mauris lacinia ipsum nulla, id iaculis quam egestas quis.", "No text node at the end and offset 0"],
  ["/p[1]/strong[1]",       1,  "/p[1]/text()[1]", 9, " senectus",                          "Text with start at sibling boundary."],
  ["/p[1]/em[1]/text()[1]", 20, "/p[1]",           3, "vitae est.",                         "Text with end at sibling boundary."],
]

describe("deserialize", () => {
  beforeEach(() => fixture.load('range.html'))
  afterEach(() => fixture.cleanup())

  it("should return a range", () => {
    let range = deserialize(fixture.el, '/p/strong', 13, '/p/strong', 27)
    assert.equal(range.toString(), "habitant morbi")
  })

  it("should return a range with 0 offsets", () => {
    let range = deserialize(fixture.el, '/p/strong', 0, '/p/strong', 27)
    assert.equal(range.toString(), "Pellentesque habitant morbi")
  })

  it("should return a range that starts and ends in a TextNode", () => {
    // Split the targeted text ("Pellentesque...tristique").
    let node = fixture.el.firstChild.firstChild.firstChild
    while (node.data.length > 1) node = node.splitText(1)

    let range = deserialize(fixture.el, '/p/strong', 13, '/p/strong', 27)
    assert.equal(range.startContainer.data, 'h')
    assert.equal(range.endContainer.data, 'i')
  })

  it("should raise NotFoundError if a node cannot be found", () => {
    let root = document.createElement('div')
    let check = () => deserialize(root, '/p/strong', 13, '/p/strong', 27)
    assert.throws(check, 'NotFoundError')
  })

  it("should raise IndexSizeError if an offset is too large", () => {
    let check = () => deserialize(fixture.el, '/p/strong', 13, '/p/strong', 100)
    assert.throws(check, 'IndexSizeError')
  })
})

describe("serialize", () => {
  beforeEach(() => fixture.load('range.html'))
  afterEach(() => fixture.cleanup())

  it("serialize() returns a serialized range", () => {
    let text = fixture.el.getElementsByTagName('strong')[0].firstChild
    let range = document.createRange()
    range.setStart(text, 13)
    range.setEnd(text, 27)
    splitBoundaries(range)
    normalizeBoundaries(range)
    let seri = serialize(range, fixture.el)
    assert.equal(seri.start, "/p[1]/strong[1]")
    assert.equal(seri.startOffset, 13)
    assert.equal(seri.end, "/p[1]/strong[1]")
    assert.equal(seri.endOffset, 27)
  })
})

describe("normalizing a Range", () => {
  beforeEach(() => fixture.load('range.html'))
  afterEach(() => fixture.cleanup())

  function testNormalization(i) {
    return () => {
      let range = createRange(i)
      splitBoundaries(range)
      normalizeBoundaries(range)
      assert.equal(range.toString(), testData[i][4], testData[i][5])
    }
  }

  for(let i in testData) {
    let test = testNormalization(i)
    it(`should parse test range ${i} (${testData[i][5]})`, test)
  }
})

describe("limit", () => {
  let head = null
  let headText = null
  let paraText = null
  let paraText2 = null
  let paraText3 = null
  let para2Text = null
  let para = null
  let para2 = null
  let span = null
  let root = null

  beforeEach(() => {
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
  })

  it("should be a no-op if all nodes are within the bounding element.", () => {
    let range = document.createRange()
    range.setStart(paraText, 0)
    range.setEnd(paraText2, paraText2.length)
    limit(range, para)
    assert.equal(range.commonAncestorContainer, para)
    assert.equal(range.startContainer, paraText)
    assert.equal(range.startOffset, 0)
    assert.equal(range.endContainer, paraText2)
    assert.equal(range.endOffset, paraText2.length)
  })

  it("should exclude any nodes to the left of the bounding element.", () => {
    let range = document.createRange()
    range.setStart(headText, 0)
    range.setEnd(paraText2, paraText2.length)
    limit(range, para)
    assert.equal(range.commonAncestorContainer, para)
    assert.equal(range.startContainer, para)
    assert.equal(range.startOffset, 0)
    assert.equal(range.endContainer, paraText2)
    assert.equal(range.endOffset, paraText2.length)
  })

  it("should exclude any nodes to the right of the bounding element.", () => {
    let range = document.createRange()
    range.setStart(paraText, paraText.length)
    range.setEnd(para2Text, para2Text.length)
    limit(range, para)
    assert.equal(range.commonAncestorContainer, para)
    assert.equal(range.startContainer, paraText)
    assert.equal(range.startOffset, paraText.length)
    assert.equal(range.endContainer, para)
    assert.equal(range.endOffset, para.childNodes.length)
  })

  it("should exclude any nodes on either side of the bounding element.", () => {
    let range = document.createRange()
    range.setStart(headText, 0)
    range.setEnd(para2Text, para2Text.length)
    limit(range, para)
    assert.equal(range.commonAncestorContainer, para)
    assert.equal(range.startContainer, para)
    assert.equal(range.startOffset, 0)
    assert.equal(range.endContainer, para)
    assert.equal(range.endOffset, para.childNodes.length)
  })

  it("should return null if no nodes fall within the bounds", () => {
    let otherDiv = document.createElement('div')
    let range = document.createRange()
    range.setStart(headText, 0)
    range.setEnd(paraText2, paraText2.length)
    assert.equal(limit(range, otherDiv), null)
  })
})
