$ = require('jquery')

Util = {}

# Public: DOM Node type identifiers. These are exposed on the Node global in
# most browsers, but (surprise, surprise) not in IE.
Util.NodeTypes =
  ELEMENT_NODE: 1
  ATTRIBUTE_NODE: 2
  TEXT_NODE: 3
  CDATA_SECTION_NODE: 4
  ENTITY_REFERENCE_NODE: 5
  ENTITY_NODE: 6
  PROCESSING_INSTRUCTION_NODE: 7
  COMMENT_NODE: 8
  DOCUMENT_NODE: 9
  DOCUMENT_TYPE_NODE: 10
  DOCUMENT_FRAGMENT_NODE: 11
  NOTATION_NODE: 12

# Public: determine the first text node in or after the given jQuery node.
Util.getFirstTextNodeNotBefore = (n) ->
  switch n.nodeType
    when Util.NodeTypes.TEXT_NODE
      return n # We have found our text node.
    when Util.NodeTypes.ELEMENT_NODE
      # This is an element, we need to dig in
      if n.firstChild? # Does it have children at all?
        result = Util.getFirstTextNodeNotBefore n.firstChild
        if result? then return result
    else
      # Not a text or an element node.
  # Could not find a text node in current node, go forward
  n = n.nextSibling
  if n?
    Util.getFirstTextNodeNotBefore n
  else
    null

# Public: determine the last text node inside or before the given node
Util.getLastTextNodeUpTo = (n) ->
  switch n.nodeType
    when Util.NodeTypes.TEXT_NODE
      return n # We have found our text node.
    when Util.NodeTypes.ELEMENT_NODE
      # This is an element, we need to dig in
      if n.lastChild? # Does it have children at all?
        result = Util.getLastTextNodeUpTo n.lastChild
        if result? then return result
    else
      # Not a text node, and not an element node.
  # Could not find a text node in current node, go backwards
  n = n.previousSibling
  if n?
    Util.getLastTextNodeUpTo n
  else
    null

# Public: Finds all text nodes within the elements in the current collection.
#
# Returns a new jQuery collection of text nodes.
Util.getTextNodes = (jq) ->
  getTextNodes = (node) ->
    if node and node.nodeType != Util.NodeTypes.TEXT_NODE
      nodes = []

      # If not a comment then traverse children collecting text nodes.
      # We traverse the child nodes manually rather than using the .childNodes
      # property because IE9 does not update the .childNodes property after
      # .splitText() is called on a child text node.
      if node.nodeType != Util.NodeTypes.COMMENT_NODE
        # Start at the last child and walk backwards through siblings.
        node = node.lastChild
        while node
          nodes.push getTextNodes(node)
          node = node.previousSibling

      # Finally reverse the array so that nodes are in the correct order.
      return nodes.reverse()
    else
      return node

  jq.map -> Util.flatten(getTextNodes(this))

Util.getGlobal = -> (-> this)()

# Public: decides whether node A is an ancestor of node B.
#
# This function purposefully ignores the native browser function for this,
# because it acts weird in PhantomJS.
# Issue: https://github.com/ariya/phantomjs/issues/11479
Util.contains = (parent, child) ->
  node = child
  while node?
    if node is parent then return true
    node = node.parentNode
  return false

# Public: Flatten a nested array structure
#
# Returns an array
Util.flatten = (array) ->
  flatten = (ary) ->
    flat = []

    for el in ary
      flat = flat.concat(if el and $.isArray(el) then flatten(el) else el)

    return flat

  flatten(array)


# Export Util object
module.exports = Util
