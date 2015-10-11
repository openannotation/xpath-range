import ancestors from 'ancestors'
import contains from 'dom-contains'
import matches from 'matches-selector'

import DOMException from './dom-exception'
import * as xpath from './xpath'

// https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeType
const TEXT_NODE = 3


// Public interface.

export function limit(range, bounds) {
  let sc = range.startContainer
  let so = range.startOffset
  let ec = range.endContainer
  let eo = range.endOffset

  if (!contains(bounds, sc)) {
    sc = bounds
    so = 0
  }

  if (!contains(bounds, ec)) {
    ec = bounds
    eo = bounds.length || bounds.childNodes.length
  }

  range.setStart(sc, so)
  range.setEnd(ec, eo)
}


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
  let document = root.ownerDocument
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
  function serialization(node, isEnd) {
    var origParent = node.parentNode

    if (ignoreSelector) {
      let filterFn = (node) => !matches(node, ignoreSelector)
      origParent = ancestors(node, filterFn)[0]
    }

    let path = xpath.fromNode(origParent, root)
    let first = firstLeaf(origParent)
    let next = (node) => node === first ? null : documentReverse(node)

    // Calculate real offset as the combined length of all the
    // preceding TextNode siblings, plus the node itself if it is the end.
    let offset = isEnd ? node.length: 0
    while ((node = next(node))) {
      if (isTextNode(node)) offset += node.length
    }

    return [path, offset]
  }

  let start = serialization(range.startContainer)
  let end   = serialization(range.endContainer, true)

  return {
    // XPath strings
    start: start[0],
    end: end[0],
    // Character offsets (integer)
    startOffset: start[1],
    endOffset: end[1],
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
