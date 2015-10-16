import ancestors from 'ancestors'
import getDocument from 'get-document'
import matches from 'matches-selector'

import DOMException from './dom-exception'
import * as xpath from './xpath'

// Public interface.

export function toRange(root, startPath, startOffset, endPath, endOffset) {
  let document = getDocument(root)
  let range = document.createRange()

  let start = findBoundary(startPath, startOffset, 'start')
  let end = findBoundary(endPath, endOffset, 'end')

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
      container = next(container);
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


export function fromRange(range, root, ignoreSelector) {
  let sc = range.startContainer
  let so = range.startOffset
  let ec = range.endContainer
  let eo = range.endOffset

  let sc0 = null
  let ec0 = null
  let start = null
  let end = null

  let filterFn = (n) => n.nodeType === 1 && !matches(n, ignoreSelector)

  if ((sc0 = ancestors(sc, filterFn)[0])) {
    let prefix = document.createRange()
    prefix.setStart(sc0, 0)
    prefix.setEnd(sc, 0)
    so += prefix.toString().length
    start = xpath.fromNode(sc0, root)
  } else {
    start = xpath.fromNode(sc, root)
  }

  if ((ec0 = ancestors(sc, filterFn)[0])) {
    let prefix = document.createRange()
    prefix.setStart(ec0, 0)
    prefix.setEnd(ec, 0)
    eo += prefix.toString().length
    end = xpath.fromNode(ec0, root)
  } else {
    end = xpath.fromNode(ec, root)
  }

  return {
    start: start,
    end: end,
    startOffset: so,
    endOffset: eo,
  }
}


// Private helpers.

/* Return the next Node in a document order traversal.
 * This order is equivalent to a classic pre-order.
 */
function documentForward(node) {
  if (node.firstChild) return node.firstChild

  while (!node.nextSibling) {
    node = node.parentNode
    if (!node) return null
  }

  return node.nextSibling
}


/* Find the last leaf node. */
function lastLeaf(node) {
  while (node.hasChildNodes()) node = node.lastChild
  return node
}
