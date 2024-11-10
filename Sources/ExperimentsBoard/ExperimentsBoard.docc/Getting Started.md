# Getting Started

Learn to add experiments quickly to your project, and enable an appropriate UI for your use case.

## Overview

Once you add a dependency to the ExperimentsBoard library in your app, adding experiments to your app with the recommended API requires two steps:

1. Set up experiments by wrapping values in your code with calls to ``Experiments``. 

2. Enable an appropriate editing UI for your use case.

Both changes are minimally disruptive, and you should be able to interact with your experiments in minutes.

### Setting Up Experiments

Once you have set up a dependency on ExperimentsBoard, you should be able to import it in your code:

```swift
import ExperimentsBoard
```

> Note: Use File > Add Package Dependencies… in Xcode to set up the dependency.

Find the value that needs to be edited at runtime, and replace it with a call to the appropriate method in ``Experiments``. For example:

```swift
let windowTitle = "My Cool Window"

// … can be edited to:
let windowTitle = Experiments.value("My Cool Window", key: "Window Title")
```

The `key` parameter is used to label and group your experiments in the editor. You can use a string, as above, but you can also use your own value by conforming it to ``ExperimentKey``.

The advantage of using your own type is that experiments that use the same type of key will be grouped together. For example, these two experiments will be grouped together in the editor:

```swift
enum WindowSettings: ExperimentKey {
    case title
    case subtitle
}

let title = Experiments.value("Title", 
    key: WindowSettings.title)
let subtitle = Experiments.value("Subtitle", 
    key: WindowSettings.title)
```

You can set up experiments for the following types:

- Strings, using ``Experiments/value(_:key:)-swift.type.method``;
- Integers, using ``Experiments/value(_:key:in:)-mqgn``;
- Floating-point values, using ``Experiments/value(_:key:in:)-9of4y``. 

For numeric experiments, you need to provide a range of valid values. For example:

```swift
let width = Experiments.value(100,
    key: WindowSettings.width,
    in: 40...500)
```

Once you set up experiments, if you run your app, you should see no change in behavior. You can now enable the editor UI to begin experimenting with these values.

### Enable the Editor UI

There are two ways to show the editor UI: as a sheet in your application, or as a separate window. This guide will enable both, and the appropriate ones will be selected depending to the OS you build your application for.

To add the editor window, add the following two lines to the `body` of your `App`:

```swift
// Import this package:
import ExperimentsBoard
…

struct MyApp: App {
    …
    var body: some Scene {
        … // … your existing scenes are here…

        // Add this line:
        ExperimentsEditorScene()
    }
}
```

To add an onscreen control to display the sheet, also use the ``SwiftUICore/View/experimentsControlOverlay(hidden:)`` modifier on an existing view:

```swift
// Import this package:
import ExperimentsBoard
…

struct ContentView: View {
    …
    var body: some Scene {
        … // … your existing view code…
        // Add this modifier:
            .experimentsControlOverlay()
    }
}
```

This will show a floating button in the bottom right of your content view:

![A screenshot of the overlay button](ios-overlay.jpg)

> Note: The overlay assumes a large view, such as the one you use as the root view of your scene. If the view is smaller than the window, the overlay may appear in the center of your scene and overlap your content incorrectly. 
> 
> If this happens, you can change your layout, for example by using `.frame(maxWidth: .infinity, maxHeight: .infinity)`, to extend your view to fill the window, which will place the overlay farther away from your controls.

### Using the Editor

Once you have enabled the UI, you can open the Experiments panel in your app.

If visible, you can tap the control you added above to open the window or sheet. On platforms that support hardware keyboard shortcuts, you can also press ^⇧X to do the same.

The editor will appear as appropriate for your platform, and allow you to edit your experiments inline:

![The experiment editor on tvOS](tvos-editor.jpg)

> Note: On macOS, you can select View > Show Experiments from the menu bar. On iPadOS and visionOS, you can hold down the Command (⌘) key to show the menu, then select Show Experiments.
> 
> On macOS, the overlay control will not be visible if the command is available in the menu bar. Use the menu or the keyboard shortcut.

All Apple platforms support the editor, but you may want to check out the [platform support](doc:Platform-Support) document for information on how to fine-tune the UI presentation for each platform.
