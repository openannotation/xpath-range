import ancestors from 'ancestors'
import contains from 'node-contains'
import insertAfter from 'insert-after'
import matches from 'matches-selector'

import DOMException from './dom-exception'
import * as xpath from './xpath'

// https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeType
const TEXT_NODE = 3


// Public interface.

export function limit(range, bounds) {
  let {startContainer, startOffset, endContainer, endOffset} = range

  if (!contains(bounds, startContainer)) {
    startContainer = bounds
    startOffset = 0
  }

  if (!contains(bounds, endContainer)) {
    endContainer = bounds
    endOffset = bounds.length || bounds.childNodes.length
  }

  range.setStart(startContainer, startOffset)
  range.setEnd(endContainer, endOffset)
}


export function normalizeBoundaries(range) {
  let {startContainer, startOffset, endContainer, endOffset} = range

  // Move the start container to the last leaf before any sibling boundary,
  // guaranteeing that any children of the container are within the range.
  if (startContainer.childNodes.length && startOffset > 0) {
    startContainer = lastLeaf(startContainer.childNodes[startOffset-1])
    startOffset = startContainer.length || startContainer.childNodes.length
  }

  // Move the end container to the first leaf after any sibling boundary,
  // guaranteeing that any children of the container are within the range.
  if (endOffset < endContainer.childNodes.length) {
    endContainer = firstLeaf(endContainer.childNodes[endOffset])
    endOffset = 0
  }

  // Any TextNode in the traversal is valid unless excluded by the offset.
  function isTextNodeInRange(node) {
    if (!isTextNode(node)) return false
    if (node === startContainer && startOffset > 0) return false
    if (node === endContainer && endOffset == 0) return false
    return true
  }

  function findTextNode(from, to, next) {
    let node = from;
    while (node && !isTextNodeInRange(node)) node = next(node)
    return node
  }

  // Find the start and end TextNode.
  let first = firstLeaf(startContainer)
  let last = lastLeaf(endContainer)
  let start = findTextNode(first, last, documentForward)
  let end = findTextNode(last, first, documentReverse)

  // Update the Range.
  range.setStart(start, 0)
  range.setEnd(end, end.length)
}


export function splitBoundaries(range) {
  let {startContainer, startOffset, endContainer, endOffset} = range

  if (isTextNode(endContainer)) {
    if (0 < endOffset && endOffset < endContainer.length) {
      endContainer = splitText(endContainer, endOffset)
      range.setEnd(endContainer, 0)
    }
  }

  if (isTextNode(startContainer)) {
    if (0 < startOffset && startOffset < startContainer.length) {
      if (startContainer === endContainer) {
        startContainer = splitText(startContainer, startOffset)
        range.setEnd(startContainer, endOffset - startOffset)
      } else {
        startContainer = splitText(startContainer, startOffset)
      }
      range.setStart(startContainer, 0)
    }
  }
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
    while ((node = next(node)) && (node = findNode(node, isTextNode, next))) {
      if ((isEnd && node.length == offset) || (offset < node.length)) {
        return {container: node, offset: offset}
      } else {
        offset -= node.length
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
    let prev = (node) => node === first ? null : documentReverse(node)

    // Calculate real offset as the combined length of all the
    // preceding TextNode siblings, plus the node itself if it is the end.
    let offset = isEnd ? node.length: 0
    while ((node = prev(node)) && (node = findNode(node, isTextNode, prev))) {
      offset += node.length
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

/* Return the first Node in the tree that matches the predicate.
 * An optional third argument specifies a traversal and should be a function
 * that returns the successor of its argument. The default is document order.
 */
function findNode(node, fn, next=documentForward) {
  let result = false;
  while (node && !(result = fn(node))) node = next(node)
  return result ? node : undefined
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
