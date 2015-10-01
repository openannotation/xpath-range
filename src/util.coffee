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

# Public: determine if the element belongs to an XML document.
# Taken from jQuery
Util.isXML = (elem) ->
  documentElement = elem and (elem.ownerDocument or elem).documentElement
  return documentElement and documentElement.nodeName isnt 'HTML' or false

# Public: determine the first text node in or after the given node.
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

# Public: Find all text nodes within the given node.
#
# Returns an Array of the text nodes.
Util.getTextNodes = (node) ->
  document = node.ownerDocument
  walker = document.createTreeWalker(node, NodeFilter.SHOW_TEXT, null, false)
  nodes = (next while next = walker.nextNode())
  return nodes

# Public: decides whether node A is an ancestor of node B.
#
# Unfortunately Node.contains() is broken in some WebKit versions. Instead,
# use Node.compareDocumentPosition() and only fall back to Node.contains if
# it is not available.
Util.contains =
  if document.compareDocumentPosition?
    (a, b) -> a.compareDocumentPosition(b) &
      Node.DOCUMENT_POSITION_CONTAINED_BY
  else
    (a, b) -> a.contains(b)

# Export Util object
module.exports = Util
