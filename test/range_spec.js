import {fromRange, toRange} from '../src/range'

describe('toRange', () => {
  beforeEach(() => fixture.load('range.html'))
  afterEach(() => fixture.cleanup())

  it('should correctly select a whole TextNode', () => {
    let range = toRange('/p/strong', 0, '/p/strong', 37, fixture.el)
    assert.equal(range.toString(), 'Pellentesque habitant morbi tristique')
  })

  it('should correctly select part of a TextNode', () => {
    let range = toRange('/p/strong', 13, '/p/strong', 27, fixture.el)
    assert.equal(range.toString(), 'habitant morbi')
  })

  it('should correctly select a whole TextNode beneath a child', () => {
    let range = toRange('/p', 0, '/p', 37, fixture.el)
    assert.equal(range.toString(), 'Pellentesque habitant morbi tristique')
  })

  it('should correctly select part of a TextNode beneath a child', () => {
    let range = toRange('/p', 13, '/p', 27, fixture.el)
    assert.equal(range.toString(), 'habitant morbi')
  })

  it('should correctly select text across node boundaries', () => {
    let range = toRange('/div[2]/p[1]', 0, '/div[2]/p[2]', 0, fixture.el)
    assert.equal(range.toString(), 'Lorem sed do eiusmod tempor.')
  })

  it('should correctly select the end of a text node', () => {
    let range = toRange('/p/strong', 37, '/p/strong', 37, fixture.el)
    assert.equal(range.toString(), '')
  })

  it('should raise NotFoundError if the start node cannot be found', () => {
    let check = () => toRange('/q', 13, '/p/strong', 27, fixture.el)
    assert.throws(check, 'NotFoundError')
  })

  it('should raise NotFoundError if the end node cannot be found', () => {
    let check = () => toRange('/p/strong', 13, '/q', 27, fixture.el)
    assert.throws(check, 'NotFoundError')
  })

  it('should raise IndexSizeError if the start offset is too large', () => {
    let check = () => toRange('/p/strong', 47, '/p', 150, fixture.el)
    assert.throws(check, 'IndexSizeError')
  })

  it('should raise IndexSizeError if the end offset is too large', () => {
    let check = () => toRange('/p/strong', 13, '/p/strong', 100, fixture.el)
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
    assert.equal(seri.start, '/p[1]/strong[1]/text()[1]')
    assert.equal(seri.startOffset, 13)
    assert.equal(seri.end, '/p[1]/strong[1]/text()[1]')
    assert.equal(seri.endOffset, 27)
  })
})
