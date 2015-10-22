import * as xpath from 'simple-xpath-position'

import DOMException from './dom-exception'


/**
 * Convert a `Range` to a pair of XPath expressions and offsets.
 *
 * If the optional parameter `root` is supplied, the computed XPath expressions
 * will be relative to it.
 *
 * @param {Range} range The Range to convert.
 * @param {Node} [root] The root context for the XPath expressions.
 * @returns {{start, startOffset, end, endOffset}}
 */
export function fromRange(range, root) {
  let sc = range.startContainer
  let so = range.startOffset
  let ec = range.endContainer
  let eo = range.endOffset

  let start = xpath.fromNode(sc, root)
  let end = xpath.fromNode(ec, root)

  return {
    start: start,
    end: end,
    startOffset: so,
    endOffset: eo,
  }
}


/**
 * Construct a `Range` from the given XPath expressions and offsets.
 *
 * If the optional parameter `root` is supplied, the XPath expressions are
 * evaluated as relative to it.
 *
 * @param {string} startPath An XPath expression for the start container.
 * @param {Number} startOffset The textual offset within the start container.
 * @param {string} endPath An XPath expression for the end container.
 * @param {Number} endOffset The textual offset within the end container.
 * @param {Node} [root] The root context for the XPath expressions.
 * @returns Range
 */
export function toRange(startPath, startOffset, endPath, endOffset, root) {
  let start = findBoundary(startPath, startOffset, 'start')
  let end = findBoundary(endPath, endOffset, 'end')

  let range = document.createRange()
  range.setStart(start.container, start.offset)
  range.setEnd(end.container, end.offset)

  return range

  function findBoundary(path, offset, which) {
    let container = xpath.toNode(path, root)
    if (!container) throw notFound(container)

    let last = lastLeaf(container)
    let next = (node) => node === last ? null : documentForward(node)
    while (container) {
      let length = container.length || 0
      if (offset <= length) return {container, offset}
      offset -= length
      container = next(container)
    }
    throw indexSize(which)
  }

  function notFound(which) {
    let message = `The ${which} node was not found.`
    let name = 'NotFoundError'
    return new DOMException(message, name)
  }

  function indexSize(which) {
    let message = `There is no text at the requested ${which} offset.`
    let name = 'IndexSizeError'
    return new DOMException(message, name)
  }
}


// Return the next Node in a document order traversal.
function documentForward(node) {
  if (node.firstChild) return node.firstChild

  while (!node.nextSibling) {
    node = node.parentNode
    if (!node) return null
  }

  return node.nextSibling
}


// Find the last leaf node.
function lastLeaf(node) {
  while (node.hasChildNodes()) node = node.lastChild
  return node
}
