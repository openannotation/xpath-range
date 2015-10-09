ancestors = require('ancestors')
contains = require('node-contains')
insertAfter = require('insert-after')
matches = require('matches-selector')

DOMException = require('./dom-exception')
xpath = require('./xpath')

# https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeType
TEXT_NODE = 3


# Public interface.

limit = (range, bounds) ->
  {startContainer, startOffset, endContainer, endOffset} = range

  if not contains(bounds, startContainer)
    startContainer = bounds
    startOffset = 0

  if not contains(bounds, endContainer)
    endContainer = bounds
    endOffset = bounds.length or bounds.childNodes.length

  range.setStart(startContainer, startOffset)
  range.setEnd(endContainer, endOffset)


normalizeBoundaries = (range) ->
  {startContainer, startOffset, endContainer, endOffset} = range

  # Move the start container to the last leaf before any sibling boundary,
  # guaranteeing that any children of the container are within the range.
  if startContainer.childNodes.length and startOffset > 0
    startContainer = lastLeaf(startContainer.childNodes[startOffset-1])
    startOffset = startContainer.length or startContainer.childNodes.length

  # Move the end container to the first leaf after any sibling boundary,
  # guaranteeing that any children of the container are within the range.
  if endOffset < endContainer.childNodes.length
    endContainer = firstLeaf(endContainer.childNodes[endOffset])
    endOffset = 0

  # Any TextNode in the traversal is valid unless excluded by the offset.
  isTextNodeInRange = (node) ->
    if not isTextNode(node) then return false
    if node is startContainer and startOffset > 0 then return false
    if node is endContainer and endOffset == 0 then return false
    return true

  # Find the start TextNode.
  # The guarantees above provide that a document order traversal visits every
  # Node in the Range before visiting the last leaf of the end container.
  node = startContainer
  next = (node) -> node isnt last and documentForward(node) or null
  last = lastLeaf(endContainer)
  node = next(node) while node? and not isTextNodeInRange(node)
  start = node

  # Find the end TextNode.
  # Similarly, a reverse document order traversal visits every Node in the
  # Range before visiting the first leaf of the start container.
  node = endContainer
  next = (node) -> node isnt last and documentReverse(node) or null
  last = firstLeaf(startContainer)
  node = next(node) while node? and not isTextNodeInRange(node)
  end = node

  range.setStart(start, 0)
  range.setEnd(end, end.length)


splitBoundaries = (range) ->
  {startContainer, startOffset, endContainer, endOffset} = range

  if isTextNode(endContainer)
    if 0 < endOffset < endContainer.length
      endContainer = splitText(endContainer, endOffset)
      range.setEnd(endContainer, 0)

  if isTextNode(startContainer)
    if 0 < startOffset < startContainer.length
      if startContainer is endContainer
        startContainer = splitText(startContainer, startOffset)
        range.setEnd(startContainer, endOffset - startOffset)
      else
        startContainer = splitText(startContainer, startOffset)
      range.setStart(startContainer, 0)


deserialize = (root, startPath, startOffset, endPath, endOffset) ->
  document = root.ownerDocument
  range = document.createRange()

  findBoundary = (path, offset, isEnd) ->
    node = xpath.toNode(path, root)

    if not node?
      message = 'Node was not found.'
      name = 'NotFoundError'
      throw new DOMException(message, name)

    # Unfortunately, we *can't* guarantee only one TextNode per Element, so
    # process each TextNode until their combined length exceeds or matches the
    # value of the offset.
    for tn in filterNode(node, isTextNode)
      if (isEnd and tn.length == offset) or (offset < tn.length)
        return {container: tn, offset: offset}
      else
        offset -= tn.length

    # Throw an error because the offset is too large.
    message = "There is no text at the requested offset."
    name = "IndexSizeError"
    throw new DOMException(message, name)

  start = findBoundary(startPath, startOffset, false)
  end = findBoundary(endPath, endOffset, true)

  range.setStart(start.container, start.offset)
  range.setEnd(end.container, end.offset)

  return range


serialize = (range, root, ignoreSelector) ->

  serialization = (node, isEnd) ->
    if ignoreSelector
      filterFn = (node) -> not matches(node, ignoreSelector)
      origParent = ancestors(node, filterFn)[0]
    else
      origParent = node.parentNode

    path = xpath.fromNode(origParent, root)
    textNodes = filterNode(origParent, isTextNode)

    # Calculate real offset as the combined length of all the
    # preceding TextNode siblings, plus the node itself if it is the end.
    index = textNodes.indexOf(node)
    if isEnd then index++

    offset = 0
    for node in textNodes.slice(0, index)
      offset += node.length

    return [path, offset]

  start = serialization(range.startContainer)
  end   = serialization(range.endContainer, true)

  return {
    # XPath strings
    start: start[0]
    end: end[0]
    # Character offsets (integer)
    startOffset: start[1]
    endOffset: end[1]
  }


# Export the above interface.
module.exports = {
  normalizeBoundaries
  splitBoundaries
  limit
  serialize
  deserialize
}


# Private helpers.

# Return the first Node in the tree that matches the predicate.
# An optional third argument specifies a traversal and should be a function
# that returns the successor of its argument. The default is document order.
findNode = (node, fn, next = documentForward) ->
  node = next(node) while node? and not result = fn(node)
  return (if result then node else undefined)


# Return an Array of each Node in the tree for which the predicate is true.
# An optional third argument specifies a traversal and should be a function
# that returns the successor of its argument. The default is document order.
filterNode = (node, fn, next = documentForward) ->
  collect = (acc, n) -> if fn(n) then acc.concat([n]) else acc
  return reduceNode(node, collect, [], next)


reduceNode = (node, fn, initialValue = undefined, next = documentForward) ->
  acc = initialValue
  last = lastLeaf(node)
  if arguments.length is 2
    if node is last then return node
    acc = node
    node = documentForward(node)
  else
    acc = fn(acc, node)

  while node = documentForward(node)
    acc = fn(acc, node)
    if node is last then break

  return acc


# Split a TextNode at an offset, returning the successor.
# https://github.com/Raynos/DOM-shim/issues/11
splitText = (node, offset) ->
  tail = node.cloneNode(false)
  tail.deleteData(0, offset)
  node.deleteData(offset, node.length - offset)
  return insertAfter(tail, node)


# Predicate for checking if a node is a TextNode.
isTextNode = (node) ->
  return node.nodeType is TEXT_NODE


# Return the next Node in a document order traversal.
# This order is equivalent to a classic pre-order.
documentForward = (node) ->
  if node.firstChild?
    return node.firstChild

  while not node.nextSibling?
    node = node.parentNode
    if node is null then return null

  return node.nextSibling


# Return the next Node in a reverse document order traversal.
# This order is equivalent to pre-order with the child order reversed.
documentReverse = (node) ->
  if node.lastChild?
    return node.lastChild

  while not node.previousSibling?
    node = node.parentNode
    if node is null then return null

  return node.previousSibling


# Find the first leaf node.
firstLeaf = (node) ->
  node = node.firstChild while node.hasChildNodes()
  return node


# Find the last leaf node.
lastLeaf = (node) ->
  node = node.lastChild while node.hasChildNodes()
  return node
