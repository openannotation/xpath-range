import getDocument from 'get-document'
import seek from 'dom-seek'
import * as xpath from 'simple-xpath-position'

const SHOW_TEXT = 4


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
  let document = getDocument(root)

  let sc = xpath.toNode(startPath, root)
  if (sc === null) throw notFound('start')

  let si = document.createNodeIterator(sc, SHOW_TEXT)
  let so = startOffset - seek(si, startOffset)

  sc = si.referenceNode
  if (!si.pointerBeforeReferenceNode) {
    if (so > 0) throw indexSize('start')
    so += sc.length
  }

  let ec = xpath.toNode(endPath, root)
  if (ec === null) throw notFound('end')

  let ei = document.createNodeIterator(ec, SHOW_TEXT)
  let eo = endOffset - seek(ei, endOffset)

  ec = ei.referenceNode
  if (!ei.pointerBeforeReferenceNode) {
    if (eo > 0) throw indexSize('end')
    eo += ec.length
  }

  let range = document.createRange()
  range.setStart(sc, so)
  range.setEnd(ec, eo)

  return range

  function notFound(which) {
    let error = new Error(`The ${which} node was not found.`)
    error.name = 'NotFoundError'
    return error
  }

  function indexSize(which) {
    let error = new Error(`There is no text at the requested ${which} offset.`)
    error.name = 'IndexSizeError'
    return error
  }
}
