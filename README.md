# xpath-range

[![Build Status](https://travis-ci.org/openannotation/xpath-range.svg?branch=master)](https://travis-ci.org/openannotation/xpath-range)

## Introduction

A (Browser) Range implementation / wrapper, with XPath creation features.

This module implements three Range objects: `BrowserRange`, `SerializedRange`, and `NormalizedRange`.

### BrowserRange

This serves to just provide a wrapper around the DOM Range object with two additional functions: `serialize()` returns an object fit for serialization, and `normalize()` returns a `NormalizedRange` instance after normalizing the range. (Normalization involves moving the start or end of the range based on some rules.)

### NormalizedRange

This object provides different properties than the DOM Range, but encapsulates the same concept. It also adds a few other methods.

The `serialize()` method is actually the serialization as described in `BrowserRange`. The `BrowserRange` `serialize()` method actually calls `normalize()` first to get a `NormalizedRange`. and then calls `serialize()` on that.

Most of serialization is a simple XPath builder with the added detail that a relative root can be passed in.

`NormalizedRange` objects also provide a function to get the text nodes they contain, to get the string of text contained by those text nodes, and to get a real DOM Range object.

It's worth noting that `NormalizedRange#text()` is probably the equivalent of the DOM Range `#toString()` method.

A `limit()` method provides the ability to reduce the range to only the nodes that fall inside the given container.

### SerializedRange

This serves as an OO wrapper around a serializable Range. It contains an XPath expression for each of the DOM Range object's start- and endContainer properties as well a the start and end offsets. Its `normalize()` method first attempts to resolve to XPath to find this range in the document and, having resolved the start- and endContainer nodes, returns a `NormalizedRange.`

## Usage

You can install `xpath-range` by executing `npm intall xpath-range`.
`xpath-range` is also [browserify](http://browserify.org/)-compatible, so you can simply `require()` it in your code.

Example code to create a serialized, xpath-based description of the region currectly selected by the user:

```
Range = require("xpath-range").Range;

doMagic = function() {
  range	= getSelection().getRangeAt(0);
  bRange = new Range.BrowserRange(range);
  sRange = bRange.serialize(document.body);
  console.log(sRange);
}
```

Run this through Browserify, and include the resulting JS bundle in an HTML document like this:

```
<html>
  <body>
    <script src="test-run.js"></script>
    <p>
      This is a test text.
    </p>
  </body>
</html>

```

After loading the page, and selecting something on the page, you can execute the `doMagic()` function (from the dev console), and you will see the xpath-based, serialized form of your selection. (Which will be pretty simple, given the example document, but hey, it's s start.)

## Development

If you want to contribute/fix something, you should fork this repository, add your contribution, and send a PR.
Don't forget to add/modify test cases to cover your change.

## Testing

You can run the command-line test suite by executing `npm test`, or you can launch the development environment using `npm start', and then point your browser to http://localhost:4000/test/runner.html

## Maintainers

Originally, this code has been part of the [Annotator project](http://annotatorjs.org/). It has been separated from [it's repository](https://github.com/openannotation/annotator).

Any discussion should happen on the [annotator-dev](https://lists.okfn.org/mailman/listinfo/annotator-dev) mailing list.
