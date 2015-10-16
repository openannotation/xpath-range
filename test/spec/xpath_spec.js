import * as xpath from '../../src/xpath'

describe('xpath', test_toNode);
describe('xpath without document.evaluate', () => {
  let evaluate = document.evaluate
  before(() => document.evaluate = undefined)
  after(() => document.evaluate = evaluate)
  test_toNode()
})

test_fromNode()


function test_fromNode() {
  beforeEach(() => fixture.load('xpath.html'))
  afterEach(() => fixture.cleanup())

  describe('#fromNode', () => {
    it("generates an XPath expression for an element in the document", () => {
      let pathToFixHTML = '/html[1]/body[1]/div[1]'

      let pEl = fixture.el.getElementsByTagName('p')[0]
      let pPath = pathToFixHTML + '/p[1]'
      assert.equal(xpath.fromNode(pEl), pPath)

      let spanEl = fixture.el.getElementsByTagName('span')[0]
      let spanPath = pathToFixHTML + '/ol[1]/li[2]/span[1]'
      assert.equal(xpath.fromNode(spanEl), spanPath)

      let strongEl = fixture.el.getElementsByTagName('strong')[0]
      let strongPath = pathToFixHTML + '/p[2]/strong[1]'
      assert.equal(xpath.fromNode(strongEl), strongPath)
    })

    it("takes an optional root parameter for a relative path root", () => {
      let ol = fixture.el.getElementsByTagName('ol')[0]
      let li = fixture.el.getElementsByTagName('li')[0]
      assert.deepEqual(xpath.fromNode(li, ol), '/li[1]')

      let span = fixture.el.getElementsByTagName('span')[0]
      assert.deepEqual(xpath.fromNode(span, ol), '/li[2]/span[1]')
    })

    it('raises InvalidNodeTypeError if root does not contain node ', () => {
      let node = document.createElement('div')
      let check = () => xpath.fromNode(node, fixture.el)
      assert.throws(check, 'InvalidNodeTypeError')
    })
  })
}



function test_toNode() {
  let path = "/p[2]/strong"

  beforeEach(() => fixture.load('xpath.html'))
  afterEach(() => fixture.cleanup())

  it("should parse a standard xpath string", () => {
    let node = xpath.toNode(path, fixture.el)
    let strong = document.getElementsByTagName('strong')[0]
    assert.strictEqual(node, strong)
  })
}
