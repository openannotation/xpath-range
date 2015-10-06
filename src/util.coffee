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


# Public: decides whether node A is an ancestor of node B.
Util.contains = (a, b) ->
  if a is b then return true
  # Node.contains() is sometimes broken so prefer compareDocumentPosition.
  if document.compareDocumentPosition?
    return a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_CONTAINED_BY
  else
    return a.contains(b)

# Export Util object
module.exports = Util
