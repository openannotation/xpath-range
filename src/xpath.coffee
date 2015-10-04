Util = require('./util')


evaluateXPath = (xp, root = document, nsResolver = null) ->
  try
    document.evaluate(
      '.' + xp,
      root,
      nsResolver,
      XPathResult.FIRST_ORDERED_NODE_TYPE,
      null
    ).singleNodeValue
  catch exception
    # There are cases when the evaluation fails, because the HTML documents
    # contains nodes with invalid names, for example tags with equal signs in
    # them, or something like that. In these cases, the XPath expressions will
    # have these abominations, too, and then they can not be evaluated. In these
    # cases, we get an XPathException, with error code 52. See
    # http://www.w3.org/TR/DOM-Level-3-XPath/xpath.html#XPathException This does
    # not necessarily make any sense, but this what we see happening.
    #
    # This is an 'evaluator' that should work for the simple expressions we
    # generate.
    steps = xp.substring(1).split("/")
    node = root
    for step in steps
      [name, idx] = step.split "["
      idx = if idx? then parseInt (idx?.split "]")[0] else 1
      node = findChild node, name.toLowerCase(), idx
    node

# Public: Compute an XPath expression for the given node.
#
# root - The root context of the XPath.
#
# Returns String
fromNode = (node, root = document) ->
  path = ''
  while node != root
    unless node?
      throw new Error("Given node is not a descendant of the root node.")
    path = '/' + nodeStep(node) + path
    node = node.parentNode
  return path

findChild = (node, type, index) ->
  unless node.hasChildNodes()
    throw new Error("XPath error: node has no children!")
  children = node.childNodes
  found = 0
  for child in children
    name = name(child)
    if name is type
      found += 1
      if found is index
        return child
  throw new Error("XPath error: wanted child not found.")

# Get the XPath node name.
nodeName = (node) ->
  name = node.nodeName.toLowerCase()
  switch name
    when "#text" then return "text()"
    when "#comment" then return "comment()"
    when "#cdata-section" then return "cdata-section()"
    else return name

# Get the position of this node among its siblings of the same name.
nodePosition = (node) ->
  position = 1
  name = node.nodeName
  while node = node.previousSibling
    if node.nodeName is name
      position += 1
  return position

# Make an XPath location step for the node by name and position.
nodeStep = (node) ->
  return "#{nodeName(node)}[#{nodePosition(node)}]"

# Public: Finds an Element Node using an XPath relative to the document root.
#
# If the document is served as application/xhtml+xml it will try and resolve
# any namespaces within the XPath.
#
# path - An XPath String to query.
#
# Examples
#
#   node = toNode('/html/body/div/p[2]')
#   if node
#     # Do something with the node.
#
# Returns the Node if found otherwise null.
toNode = (path, root = document, resolver = null) ->
  if document.lookupNamespaceURI(null)? and not resolver?
    documentElement = document.documentElement

    if document.ownerDocument?
      documentElement = document.ownerDocument.documentElement

    resolver = document.createNSResolver(documentElement)

  return evaluateXPath(path, root, resolver)

module.exports =
  fromNode: fromNode
  toNode: toNode
