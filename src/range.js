import ancestors from 'ancestors'
import getDocument from 'get-document'
import matches from 'matches-selector'

import DOMException from './dom-exception'
import * as xpath from './xpath'

// https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeType
const TEXT_NODE = 3


// Public interface.

export function deserialize(root, startPath, startOffset, endPath, endOffset) {
  let document = getDocument(root)
  let range = document.createRange()

  function findBoundary(path, offset, isEnd) {
    let node = xpath.toNode(path, root)

    if (!node) {
      let message = 'Node was not found.'
      let name = 'NotFoundError'
      throw new DOMException(message, name)
    }

    // Unfortunately, we *can't* guarantee only one TextNode per Element, so
    // process each TextNode until their combined length exceeds or matches the
    // value of the offset.
    let last = lastLeaf(node)
    let next = (node) => node === last ? null : documentForward(node)
    while ((node = next(node))) {
      if (isTextNode(node)) {
        if ((isEnd && node.length == offset) || (offset < node.length)) {
          return {container: node, offset: offset}
        } else {
          offset -= node.length
        }
      }
    }

    // Throw an error because the offset is too large.
    let message = "There is no text at the requested offset."
    let name = "IndexSizeError"
    throw new DOMException(message, name)
  }

  let start = findBoundary(startPath, startOffset, false)
  let end = findBoundary(endPath, endOffset, true)

  range.setStart(start.container, start.offset)
  range.setEnd(end.container, end.offset)

  return range
}


export function serialize(range, root, ignoreSelector) {
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

/* Predicate for checking if a node is a TextNode. */
function isTextNode(node) {
  return node.nodeType === TEXT_NODE
}


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


/* Return the next Node in a reverse document order traversal.
 * This order is equivalent to pre-order with the child order reversed.
 */
function documentReverse(node) {
  if (node.lastChild) return node.lastChild

  while (!node.previousSibling) {
    node = node.parentNode
    if (!node) return null
  }

  return node.previousSibling
}


/* Find the first leaf node. */
function firstLeaf(node) {
  while (node.hasChildNodes()) node = node.firstChild
  return node
}


/* Find the last leaf node. */
function lastLeaf(node) {
  while (node.hasChildNodes()) node = node.lastChild
  return node
}
