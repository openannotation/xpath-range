import {fromRange, toRange} from '../../src/range'
import * as xpath from '../../src/xpath'

describe('toRange', () => {
  beforeEach(() => fixture.load('range.html'))
  afterEach(() => fixture.cleanup())

  it('should correctly select a whole TextNode', () => {
    let range = toRange(fixture.el, '/p/strong', 0, '/p/strong', 37)
    assert.equal(range.toString(), 'Pellentesque habitant morbi tristique')
  })

  it('should correctly select part of a TextNode', () => {
    let range = toRange(fixture.el, '/p/strong', 13, '/p/strong', 27)
    assert.equal(range.toString(), 'habitant morbi')
  })

  it('should raise NotFoundError if a node cannot be found', () => {
    let root = document.createElement('div')
    let check = () => toRange(root, '/p/strong', 13, '/p/strong', 27)
    assert.throws(check, 'NotFoundError')
  })

  it('should raise IndexSizeError if an offset is too large', () => {
    let check = () => toRange(fixture.el, '/p/strong', 13, '/p/strong', 100)
    assert.throws(check, 'IndexSizeError')
  })
})

describe('fromRange', () => {
  beforeEach(() => fixture.load('range.html'))
  afterEach(() => fixture.cleanup())

  it('fromRange() returns a serialized range', () => {
    let text = fixture.el.getElementsByTagName('strong')[0].firstChild
    let range = document.createRange()
    range.setStart(text, 13)
    range.setEnd(text, 27)

    let seri = fromRange(range, fixture.el)
    assert.equal(seri.start, '/p[1]/strong[1]')
    assert.equal(seri.startOffset, 13)
    assert.equal(seri.end, '/p[1]/strong[1]')
    assert.equal(seri.endOffset, 27)
  })
})
