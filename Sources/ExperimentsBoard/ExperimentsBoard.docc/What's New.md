# What's New

Release notes for changes to this package, by version.

## Overview

This document tracks changes to each published version of ExperimentsBoard.

> Important: Until version 1.0, the ExperimentsBoard API is not stable and may change release to release. When it does, it will be noted below.

### ExperimentsBoard 0.1.2

The big change in this version is a full rework of the ``Experiments/Observable`` type.

The rework removes one use of `@unchecked Sendable` in the codebase, allowing the compiler to prove the safety of the code. This unlocks the ability for an ``Experiments/Observable`` to be bound to any isolation, not just the main actor. It now also has a shorter name (``Experiments/Observable``).

To support this change, you can now register a storage observer weakly. See the ``WeakExperimentsObserver`` type and the new ``Experiments/Storage/addObserver(_:)-ngjv`` method. Also, the observation callbacks in ``ExperimentsObserver`` are now `async`, allowing you to synchronize the callback to the actor of your choice. 

> Note: This release relaxes requirements, except that ``Experiments/Observable`` is now explicitly not `Sendable`. Since it was bound to the main actor prior to this release, this should not be a source-breaking change. All other new features are additive and fully source-compatible with 0.1.1.

> Note: Version 0.1.2.1 allows an actor to use the ``Experiments/Observable/init(_:at:)`` initializer to capture the appropriate isolation automatically. See ``Experiments/Observable`` for details.

### ExperimentsBoard 0.1.1

This version introduces the ``Experimentable`` property wrapper. You can use it instead of the static API of ``Experiments`` if replacing a variable works better for your use case, rather than working directly with the constant.

An example of use:

```swift
@Experimentable(MyExperiments.title)
var title = "Hello!"
```

This version also conforms ``Experiments`` to `Sendable`.

> Note: This version is source-compatible with 0.1.0.
