FIRST_ORDERED_NODE_TYPE = 9
HTML_NAMESPACE = 'http://www.w3.org/1999/xhtml'

# Public: Compute an XPath expression for the given node.
#
# root - The root context of the XPath.
#
# Returns String
fromNode = (node, root = document) ->
  path = '/'
  while node isnt root
    unless node?
      throw new Error("Given node is not a descendant of the root node.")
    path = "/#{nodeName(node)}[#{nodePosition(node)}]#{path}"
    node = node.parentNode
  return path.replace(/\/$/, '')


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
toNode = (path, root = document, resolver) ->
  # Make the path relative to the root, if not the document.
  if root isnt document and path[0] is '/' and path[1] isnt '/'
    path = '.' + path

  # Make a default resolver.
  if resolver is undefined
    documentElement = (root.ownerDocument or root).documentElement
    defaultNS = documentElement.lookupNamespaceURI(null) or HTML_NAMESPACE
    resolver = (prefix) ->
      ns = {'_default_': defaultNS}
      return ns[prefix] or documentElement.lookupNamespaceURI(prefix)

    # Add a default prefix to each path part.
    path = path.replace(/\/(?!\.)([^\/:]+)(?=\/|$)/g, '/_default_:$1')

  try
    r = document.evaluate(path, root, resolver, FIRST_ORDERED_NODE_TYPE, null)
    return r.singleNodeValue
  catch
    # Fallback approach in case of no document.evaluate() or another error.
    # This approach works for the simple expressions this module generates.
    steps = path.split("/")
    node = root
    while node?
      step = steps.shift()
      if step is undefined then break
      if step is '.' then continue
      [name, position] = step.split(/[\[\]]/)
      name = name.replace(/^_default_:/g, '')
      position = if position? then parseInt(position) else 1
      node = findChild(node, name, position)
    return node


# Get the XPath node name.
nodeName = (node) ->
  name = node.nodeName
  switch name
    when "#text" then name = "text()"
    when "#comment" then name = "comment()"
    when "#cdata-section" then name = "cdata-section()"
    else name = name.toLowerCase()


# Get the ordinal position of this node among its siblings of the same name.
nodePosition = (node) ->
  name = node.nodeName
  position = 1
  while node = node.previousSibling
    if node.nodeName is name
      position += 1
  return position


# Find the child of the given node by name and ordinal position.
findChild = (node, name, position) ->
  for node in node.childNodes
    if nodeName(node) is name and --position is 0
      return node
  return null


module.exports =
  fromNode: fromNode
  toNode: toNode
