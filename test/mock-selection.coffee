xpath = require('../src/xpath')
Util = require('../src/util')

module.exports = class MockSelection
  rangeCount: 0
  isCollapsed: false

  constructor: (fixElem, data) ->

    @root = fixElem
    @rootXPath = xpath.fromNode(fixElem)

    @startContainer = this.resolvePath(data[0])
    @startOffset    = data[1]
    @endContainer   = this.resolvePath(data[2])
    @endOffset      = data[3]
    @expectation    = data[4]
    @description    = data[5]

    @commonAncestor = @startContainer
    while not Util.contains(@commonAncestor, @endContainer)
      @commonAncestor = @commonAncestor.parentNode
    @commonAncestorXPath = xpath.fromNode(@commonAncestor)

    @ranges = []
    this.addRange({
      startContainer: @startContainer
      startOffset: @startOffset
      endContainer: @endContainer
      endOffset: @endOffset
      commonAncestorContainer: @commonAncestor
    })

  getRangeAt: (i) ->
    @ranges[i]

  removeAllRanges: ->
    @ranges = []
    @rangeCount = 0

  addRange: (r) ->
    @ranges.push(r)
    @rangeCount += 1

  resolvePath: (path) ->
    if typeof path is "number"
      Util.getTextNodes(@root)[path]
    else if typeof path is "string"
      this.resolveXPath(@rootXPath + path)

  resolveXPath: (xpath) ->
    document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue
