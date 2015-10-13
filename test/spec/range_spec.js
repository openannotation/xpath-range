import {serialize, deserialize} from '../../src/range'
import * as xpath from '../../src/xpath'

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

    let seri = serialize(range, fixture.el)
    assert.equal(seri.start, "/p[1]/strong[1]")
    assert.equal(seri.startOffset, 13)
    assert.equal(seri.end, "/p[1]/strong[1]")
    assert.equal(seri.endOffset, 27)
  })
})
