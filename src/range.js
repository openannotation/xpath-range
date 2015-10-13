import ancestors from 'ancestors'
import getDocument from 'get-document'
import matches from 'matches-selector'

import DOMException from './dom-exception'
import * as xpath from './xpath'

// https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeType
const TEXT_NODE = 3


// Public interface.

export function normalize(range) {
  let sc = range.startContainer
  let so = range.startOffset
  let ec = range.endContainer
  let eo = range.endOffset

  // Move the start container to the last leaf before any sibling boundary.
  if (sc.childNodes.length && so > 0) {
    sc = lastLeaf(sc.childNodes[so-1])
    so = sc.length || 0
  }

  // Move the end container to the first leaf after any sibling boundary.
  if (eo < ec.childNodes.length) {
    ec = firstLeaf(ec.childNodes[eo])
    eo = 0
  }

  // Move each container inward until it reaches a leaf Node.
  let start = firstLeaf(sc)
  let end = lastLeaf(ec)

  // Define a predicate to check if a Node is a leaf Node inside the Range.
  function isLeafNodeInRange (node) {
    if (node.childNodes.length) return false
    let length = node.length || 0
    if (node === sc && so === length) return false
    if (node === ec && eo === 0) return false
    return true
  }

  // Move the start container until it is included or collapses to the end.
  let next = (node) => node === end ? null : documentForward(node)
  while (!isLeafNodeInRange(start)) start = next(start)

  if (start === sc) {
    range.setStart(sc, so)
  } else if (start.nodeType === 3) {
    range.setStart(start, 0)
  } else {
    range.setStartBefore(start)
  }

  // Move the end container until it is included or collapses to the start.
  let prev = (node) => node === start ? null : documentReverse(node)
  while (end && !isLeafNodeInRange(end)) end = prev(end)

  if (end === ec) {
    range.setEnd(ec, eo)
  } else if (end.nodeType === 3) {
    range.setEnd(end, end.length)
  } else {
    range.setEndAfter(end)
  }
}


export function split(range) {
  let sc = range.startContainer
  let so = range.startOffset
  let ec = range.endContainer
  let eo = range.endOffset

  if (isTextNode(ec)) {
    if (0 < eo && eo < ec.length) {
      ec = splitText(ec, eo)
      eo = 0;
    }
  }

  if (isTextNode(sc)) {
    if (0 < so && so < sc.length) {
      if (sc === ec) {
        sc = splitText(sc, so)
        eo = eo - so
      } else {
        sc = splitText(sc, so)
      }
      so = 0
    }
  }

  range.setStart(sc, so)
  range.setEnd(ec, eo)
}


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

/* Insert a Node as the next sibling of a reference Node. */
function insertAfter(node, referenceNode) {
  let parent = referenceNode.parentNode
  let next = referenceNode.nextSibling
  return next ? parent.insertBefore(node, next) : parent.appendChild(node)
}


/* Split a TextNode at an offset, returning the successor.
 * https://github.com/Raynos/DOM-shim/issues/11
 */
function splitText(node, offset) {
  let tail = node.cloneNode(false)
  tail.deleteData(0, offset)
  node.deleteData(offset, node.length - offset)
  return insertAfter(tail, node)
}


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
