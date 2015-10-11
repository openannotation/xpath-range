import DOMException from './dom-exception'

// https://developer.mozilla.org/en-US/docs/XPathResult
const FIRST_ORDERED_NODE_TYPE = 9
// Default namespace for XHTML documents
const HTML_NAMESPACE = 'http://www.w3.org/1999/xhtml'


/* Public: Compute an XPath expression for the given node.
 *
 * root - The root context of the XPath.
 *
 * Returns String
 */
export function fromNode(node, root = document) {
  let path = '/';
  while (node !== root) {
    if (!node) {
      let message = 'The supplied node is not contained by the root node.'
      let name = 'InvalidNodeTypeError'
      throw new DOMException(message, name)
    }
    path = `/${nodeName(node)}[${nodePosition(node)}]${path}`
    node = node.parentNode
  }
  return path.replace(/\/$/, '')
}


/* Public: Finds an Element Node using an XPath relative to the document root.
 *
 * If the document is served as application/xhtml+xml it will try and resolve
 * any namespaces within the XPath.
 *
 * path - An XPath String to query.
 *
 * Examples
 *
 *   node = toNode('/html/body/div/p[2]')
 *   if node
 *     # Do something with the node.
 *
 * Returns the Node if found otherwise null.
 */
export function toNode(path, root = document, resolver) {
  // Make the path relative to the root, if not the document.
  if (root !== document && path[0] === '/' && path[1] !== '/') {
    path = '.' + path
  }

  // Make a default resolver.
  if (resolver === undefined && document.lookupNamespaceURI) {
    let documentElement = (root.ownerDocument || root).documentElement
    let defaultNS = documentElement.lookupNamespaceURI(null) || HTML_NAMESPACE
    resolver = (prefix) => {
      let ns = {'_default_': defaultNS}
      return ns[prefix] || documentElement.lookupNamespaceURI(prefix)
    }

    // Add a default prefix to each path part.
    path = path.replace(/\/(?!\.)([^\/:\(]+)(?=\/|$)/g, '/_default_:$1')
  }

  try {
    let r = document.evaluate(path, root, resolver, FIRST_ORDERED_NODE_TYPE, null)
    return r.singleNodeValue
  } catch (e) {
    // Fallback approach in case of no document.evaluate() or another error.
    // This approach works for the simple expressions this module generates.
    path = path.replace(/_default_:/g, '')
    let steps = path.split("/")
    let node = root
    while (node) {
      let step = steps.shift()
      if (step === undefined) break
      if (step === '.') continue
      let [name, position] = step.split(/[\[\]]/)
      position = position ? parseInt(position) : 1
      node = findChild(node, name, position)
    }
    return node
  }
}


// Get the XPath node name.
function nodeName(node) {
  switch (node.nodeName) {
  case '#text': return 'text()'
  case '#comment': return 'comment()'
  case '#cdata-section': return 'cdata-section()'
  default: return node.nodeName.toLowerCase()
  }
}


// Get the ordinal position of this node among its siblings of the same name.
function nodePosition(node) {
  let name = node.nodeName
  let position = 1
  while ((node = node.previousSibling)) {
    if (node.nodeName === name) position += 1
  }
  return position
}


// Find the child of the given node by name and ordinal position.
function findChild(node, name, position) {
  for (node = node.firstChild ; node ; node = node.nextSibling) {
    if (nodeName(node) === name && --position === 0) return node
  }
  return null
}
