ancestors = require('ancestors')
contains = require('node-contains')
insertAfter = require('insert-after')
matches = require('matches-selector')

DOMException = require('./dom-exception')
xpath = require('./xpath')

# https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeType
ELEMENT_NODE = 1
TEXT_NODE = 3


exports.splitBoundaries = splitBoundaries = (range) ->
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


# Public: Creates a wrapper around a range object obtained from a DOMSelection.
exports.BrowserRange = class BrowserRange

  # Public: Creates an instance of BrowserRange.
  #
  # object - A range object obtained via DOMSelection#getRangeAt().
  #
  # Examples
  #
  #   selection = window.getSelection()
  #   range = new BrowserRange(selection.getRangeAt(0))
  #
  # Returns an instance of BrowserRange.
  constructor: (obj) ->
    @commonAncestorContainer = obj.commonAncestorContainer
    @startContainer          = obj.startContainer
    @startOffset             = obj.startOffset
    @endContainer            = obj.endContainer
    @endOffset               = obj.endOffset


  setStart: (@startContainer, @startOffset) ->
    @commonAncestorContainer = commonAncestor(@startContainer, @endContainer)

  setEnd: (@endContainer, @endOffset) ->
    @commonAncestorContainer = commonAncestor(@startContainer, @endContainer)

  # Public: Normalize the start and end to TextNode boundaries.
  #
  # Returns an instance of NormalizedRange
  normalize: (root) ->
    splitBoundaries(this)

    # Initialize the result.
    commonAncestor = @commonAncestorContainer
    start = null
    end = null

    # Get (a copy of) the boundaries of the range.
    {startContainer, startOffset, endContainer, endOffset} = this

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

    # These above implies that a post-order traversal visits every Node in the
    # Range before visiting the end container. The first Node in the order is
    # the first leaf of the start container.
    from = firstLeaf(startContainer)

    # Similarly, a post-order traversal that reverses the child order visits
    # every Node in the Range before visiting the end container. The first
    # Node in the order is the last leaf of the start container.
    to = lastLeaf(endContainer)

    # Any TextNode in the traversal is valid unless excluded by the offset.
    checkNode = (node) ->
      if not isTextNode(node) then return false
      if node is startContainer and startOffset > 0 then return false
      if node is endContainer and endOffset == 0 then return false
      return true

    # Find the start and end TextNode nodes.
    start = findNode(from, to, checkNode, postFirst)
    end = findNode(to, from, checkNode, postLast)

    return new NormalizedRange({commonAncestor, start, end})

  # Public: Creates a range suitable for storage.
  #
  # root           - A root Element from which to anchor the serialisation.
  # ignoreSelector - A selector String of elements to ignore. For example
  #                  elements injected by the annotator.
  #
  # Returns an instance of SerializedRange.
  serialize: (root, ignoreSelector) ->
    this.normalize(root).serialize(root, ignoreSelector)

# Public: A normalised range is most commonly used throughout the annotator.
# its the result of a deserialised SerializedRange or a BrowserRange with
# out browser inconsistencies.
exports.NormalizedRange = class NormalizedRange

  # Public: Creates an instance of a NormalizedRange.
  #
  # This is usually created by calling the .normalize() method on one of the
  # other Range classes rather than manually.
  #
  # obj - An Object literal. Should have the following properties.
  #       commonAncestor: A Node that contains the start Node and end Node.
  #       start:          The first TextNode in the range.
  #       end             The last TextNode in the range.
  #
  # Returns an instance of NormalizedRange.
  constructor: (obj) ->
    @commonAncestor = obj.commonAncestor
    @start          = obj.start
    @end            = obj.end

  # Public: For API consistency.
  #
  # Returns itself.
  normalize: (root) ->
    this

  # Public: Limits the nodes within the NormalizedRange to those contained
  # withing the bounds parameter. It returns an updated range with all
  # properties updated. NOTE: Method returns null if all nodes fall outside
  # of the bounds.
  #
  # bounds - An Element to limit the range to.
  #
  # Returns updated self or null.
  limit: (bounds) ->
    if @commonAncestor == bounds or contains(bounds, @commonAncestor)
      return this

    if not contains(@commonAncestor, bounds)
      return null

    document = bounds.ownerDocument

    if not contains(bounds, @start)
      @start = findNode(firstLeaf(bounds), bounds, isTextNode, postFirst)

    if not contains(bounds, @end)
      @end = findNode(lastLeaf(bounds), bounds, isTextNode, postLast)

    return null unless @start and @end

    @commonAncestor = @start
    while not contains(@commonAncestor, @end)
      @commonAncestor = @commonAncestor.parentNode

    this

  # Convert this range into an object consisting of two pairs of (xpath,
  # character offset), which can be easily stored in a database.
  #
  # root - The root Element relative to which XPaths should be calculated
  # ignoreSelector - A selector String of elements to ignore. For example
  #                  elements injected by the annotator.
  #
  # Returns an instance of SerializedRange.
  serialize: (root, ignoreSelector) ->

    serialization = (node, isEnd) ->
      if ignoreSelector
        filterFn = (node) -> not matches(node, ignoreSelector)
        origParent = ancestors(node, filterFn)[0]
      else
        origParent = node.parentNode

      path = xpath.fromNode(origParent, root)
      textNodes = getTextNodes(origParent)

      # Calculate real offset as the combined length of all the
      # preceding textNode siblings. We include the length of the
      # node if it's the end node.
      nodes = textNodes.slice(0, textNodes.indexOf(node))
      offset = 0
      for n in nodes
        offset += n.nodeValue.length

      if isEnd then [path, offset + node.nodeValue.length] else [path, offset]

    start = serialization(@start)
    end   = serialization(@end, true)

    new SerializedRange({
      # XPath strings
      start: start[0]
      end: end[0]
      # Character offsets (integer)
      startOffset: start[1]
      endOffset: end[1]
    })

  # Public: Creates a concatenated String of the contents of all the text nodes
  # within the range.
  #
  # Returns a String.
  text: ->
    (for node in this.textNodes()
      node.nodeValue
    ).join ''

  # Public: Fetches only the text nodes within the range.
  #
  # Returns an Array of TextNode instances.
  textNodes: ->
    textNodes = getTextNodes(this.commonAncestor)
    [start, end] = [textNodes.indexOf(this.start), textNodes.indexOf(this.end)]
    # Return the textNodes that fall between the start and end indexes.
    return textNodes[start..end]

# Public: A range suitable for storing in local storage or serializing to JSON.
exports.SerializedRange = class SerializedRange

  # Public: Creates a SerializedRange
  #
  # obj - The stored object. It should have the following properties.
  #       start:       An xpath to the Element containing the first TextNode
  #                    relative to the root Element.
  #       startOffset: The offset to the start of the selection from obj.start.
  #       end:         An xpath to the Element containing the last TextNode
  #                    relative to the root Element.
  #       startOffset: The offset to the end of the selection from obj.end.
  #
  # Returns an instance of SerializedRange
  constructor: (obj) ->
    @start       = obj.start
    @startOffset = obj.startOffset
    @end         = obj.end
    @endOffset   = obj.endOffset

  # Public: Creates a NormalizedRange.
  #
  # root - The root Element from which the XPaths were generated.
  #
  # Returns a NormalizedRange instance.
  normalize: (root) ->
    range = {}

    for p in ['start', 'end']
      node = xpath.toNode(this[p], root)

      if not node?
        message = 'Node was not found.'
        name = 'NotFoundError'
        throw new DOMException(message, name)

      # Unfortunately, we *can't* guarantee only one textNode per
      # elementNode, so we have to walk along the element's textNodes until
      # the combined length of the textNodes to that point exceeds or
      # matches the value of the offset.
      length = 0
      targetOffset = this[p + 'Offset']

      # Range excludes its endpoint because it describes the boundary position.
      # Target the string index of the last character inside the range.
      if p is 'end' then targetOffset -= 1

      for tn in getTextNodes(node)
        if (length + tn.nodeValue.length > targetOffset)
          range[p + 'Container'] = tn
          range[p + 'Offset'] = this[p + 'Offset'] - length
          break
        else
          length += tn.nodeValue.length

      # If we fall off the end of the for loop without having set
      # 'startOffset'/'endOffset', the element has shorter content than when
      # we annotated, so throw an error:
      if not range[p + 'Offset']?
        message = "There is no text at offset #{this[p + 'Offset']}."
        name = "IndexSizeError"
        throw new DOMException(message, name)

    range.commonAncestorContainer = commonAncestor(
      range.startContainer, range.endContainer)

    new BrowserRange(range).normalize(root)

  # Public: Creates a range suitable for storage.
  #
  # root           - A root Element from which to anchor the serialisation.
  # ignoreSelector - A selector String of elements to ignore. For example
  #                  elements injected by the annotator.
  #
  # Returns an instance of SerializedRange.
  serialize: (root, ignoreSelector) ->
    this.normalize(root).serialize(root, ignoreSelector)

  # Public: Returns the range as an Object literal.
  toObject: ->
    {
      start: @start
      startOffset: @startOffset
      end: @end
      endOffset: @endOffset
    }


# Split a TextNode at an offset, returning the successor.
# https://github.com/Raynos/DOM-shim/issues/11
splitText = (node, offset) ->
  tail = node.cloneNode(false)
  tail.deleteData(0, offset)
  node.deleteData(offset, node.length - offset)
  return insertAfter(tail, node)


# Get all the text Nodes within a Node.
getTextNodes = (root) ->
  text = []
  node = firstLeaf(root)
  while node = findNode(node, root, isTextNode, postFirst)
    text.push(node)
    if node is root then break
    node = postFirst(node)
  return text


# Predicate for checking if a node is a TextNode.
isTextNode = (node) ->
  return node.nodeType is TEXT_NODE


# Find the first Node in [start, end] (by step(node)) that passes the check.
findNode = (start, end, check, step) ->
  node = start
  node = step(node) while not (pass = check(node)) and node isnt end
  if pass then return node else return null


# Return the next Node in a first-to-last-child post-order traversal.
postFirst = (node) ->
  if node.nextSibling?
    return firstLeaf(node.nextSibling)
  return node.parentNode


# Return the next Node in a last-to-first-child post-order traversal.
postLast = (node) ->
  if node.previousSibling?
    return lastLeaf(node.previousSibling)
  return node.parentNode


# Find the first leaf node.
firstLeaf = (node) ->
  node = node.firstChild while node.hasChildNodes()
  return node


# Find the last leaf node.
lastLeaf = (node) ->
  node = node.lastChild while node.hasChildNodes()
  return node


# Find a common ancestor Node.
commonAncestor = (node, other) ->
  while node? and not contains(node, other)
    node = node.parentNode
  return node
