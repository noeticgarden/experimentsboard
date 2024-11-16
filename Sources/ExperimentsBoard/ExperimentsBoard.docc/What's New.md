# What's New

Release notes for changes to this package, by version.

## Overview

This document tracks changes to each published version of ExperimentsBoard.

> Important: Until version 1.0, the ExperimentsBoard API is not stable and may change release to release. When it does, it will be noted below.

### ExperimentsBoard 0.1.1

This version introduces the ``Experimentable`` property wrapper. You can use it instead of the static API of ``Experiments`` if replacing a variable works better for your use case, rather than working directly with the constant.

An example of use:

```swift
@Experimentable(MyExperiments.title)
var title = "Hello!"
```

This version also conforms ``Experiments`` to `Sendable`.

> Note: This version is source-compatible with 0.1.0.
