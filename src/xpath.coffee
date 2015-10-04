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
toNode = (path, root = document) ->
  if not Util.isXML document.documentElement
    evaluateXPath path, root
  else
    # We're in an XML document, create a namespace resolver function to try
    # and resolve any namespaces in the current document.
    # https://developer.mozilla.org/en/DOM/document.createNSResolver
    customResolver = document.createNSResolver(
      if document.ownerDocument == null
        document.documentElement
      else
        document.ownerDocument.documentElement
    )
    node = evaluateXPath path, root, customResolver

    unless node
      # If the previous search failed to find a node then we must try to
      # provide a custom namespace resolver to take into account the default
      # namespace. We also prefix all node names with a custom xhtml namespace
      # eg. 'div' => 'xhtml:div'.
      path = (for segment in path.split '/'
        if segment and segment.indexOf(':') == -1
          segment.replace(/^([a-z]+)/, 'xhtml:$1')
        else segment
      ).join('/')

      # Find the default document namespace.
      namespace = document.lookupNamespaceURI null

      # Try and resolve the namespace, first seeing if it is an xhtml node
      # otherwise check the head attributes.
      customResolver  = (ns) ->
        if ns == 'xhtml' then namespace
        else document.documentElement.getAttribute('xmlns:' + ns)

      node = evaluateXPath path, root, customResolver
    node

module.exports =
  fromNode: fromNode
  toNode: toNode
