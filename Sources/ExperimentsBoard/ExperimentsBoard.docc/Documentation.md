# ``ExperimentsBoard``

Quickly experiment with values without leaving your application.

The `ExperimentsBoard` module allows you to quickly add UI to turn any constant in your code into something you can tweak and experiment with at runtime. If you use SwiftUI, or another UI toolkit that integrates with the `Observation` module, adding a new experiment can be as easy as editing a single line of code.

You can use the static API of the ``Experiments`` type to quickly turn any constant into an experiment. For example, changing a SwiftUI view call like this:

```swift
Text("Hello, world!")
```

… to replace `world` with a call to ``Experiments/value(_:key:)-type.method``:

```swift
import ExperimentsBoard
…
Text("Hello, \(Experiments.value("world", key: "Place"))!")
```

will yield an editor similar to the following, [once you enable the editor UI](doc:Getting-Started) in your project.
You will be able to edit the value at runtime, and the change will be visible immediately: 

![A Hello World window with panel showing the 'world' string as editable on iOS, and then edited to 'universe'.](ios-intro.jpg)

This module provides UI to edit string and numeric constants that works on all Apple OSes. See <doc:Platform-Support> for more information.

![A Hello World window with panel showing the 'world' string as editable on macOS, and then edited to 'universe'.](macos-intro.jpg)

## Topics

### Quick Start

- <doc:Getting-Started>
- ``Experiments/value(_:key:)-swift.type.method``
- ``Experiments/value(_:key:in:)-mqgn``
- ``Experiments/value(_:key:in:)-9of4y``
- ``ExperimentKey``
- ``Experimentable``
- <doc:Platform-Support>

### Displaying the Editor UI

- ``ExperimentsEditorScene``
- ``SwiftUICore/View/experimentsControlOverlay(hidden:)``
- ``SwiftUICore/View/showsExperimentsSceneAutomatically()``
- ``ExperimentsEditor``
- ``SwiftUICore/EnvironmentValues/openExperimentsWindow``
- ``OpenExperimentsWindowAction``

### Custom Display & Storage

- ``Experiments``
- ``Experiments/Storage/Observable``
- ``Experiments/Storage``
- ``ExperimentsObserver``
- ``Experiments/Storage/ExperimentDefinition``
- ``ExperimentKind``
- ``Experiments/Storage/Raw-swift.struct``
- ``Experiments/Storage/Raw-swift.struct/State-swift.struct``
- ``AnyExperimentStorable``
- ``Swift/AnyHashable/init(_:)``
- ``AnyClosedIntegerRange``
- ``Swift/ClosedRange/init(_:)-8rsiz``
- ``AnyClosedFloatingPointRange``
- ``Swift/ClosedRange/init(_:)-51z07``
