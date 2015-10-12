# XPath Range [![Coverage Status](https://coveralls.io/repos/openannotation/xpath-range/badge.svg?branch=master&service=github)](https://coveralls.io/github/openannotation/xpath-range?branch=master)
[![Sauce Test Status](https://saucelabs.com/browser-matrix/xpath-range.svg)](https://saucelabs.com/u/xpath-range)

This module is for describing and resolving a DOM `Range` using XPath.

## Installation

Use `npm install xpath-range`.

## Usage

  TODO: The API is not finalized.

## Compatibility

This library should work with any browser implementing basic `Range` support.

### Internet Explorer version 8

- Basic support can be achieved with the [rangy][rangy] shim.
- There is no support for namespaces in X(HT)ML documents (issue #17).

## Community

Originally, this code was part of the
[Annotator project](http://annotatorjs.org/).

Any discussion should happen on the
[annotator-dev](https://lists.okfn.org/mailman/listinfo/annotator-dev) mailing
list.

## Development

To contribute, fork this repository and send a pull request with your changes,
including any necessary test and documentation updates.

## Testing

You can run the command-line test suite by executing `npm test`.

To run the test suite in a browser, install the karma test runner

    npm install -g karma-cli

and then run `karma start` and it will print directions for debugging.

[rangy] https://github.com/timdown/rangy
