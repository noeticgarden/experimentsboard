# Platform Support

Discover how to use this package across platforms, including Apple OSes, Linux, WebAssembly or Windows.

## Package Support

ExperimentsBoard should build on any platform that supports building Swift packages. Its capabilities depend on the platform, and the API surface depends on what support a specific platform can bring.

## SwiftUI

The editor UI in this package assumes the presence of an app using the [SwiftUI app life cycle](https://developer.apple.com/documentation/swiftui/migrating-to-the-swiftui-life-cycle).

The editor UI requires SwiftUI features from Fall 2023 or later. It is supported on macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, or later. The package builds and deploys on earlier versions, but the editor UI will require `if #available(…)` checks and may not be available.

## macOS

On macOS, the editor will be shown as a separate window as long as you have added a ``ExperimentsEditorScene`` to your app. Use the View > Show Experiments menu item to show the window.

If you don't want a separate window, apply the ``SwiftUICore/View/experimentsControlOverlay(hidden:)`` modifier to your view without adding the scene to your application. The overlay will show, and the editor view will be shown as a sheet in your window.

macOS supports hardware keyboard shortcuts. If you have added either of the above to your app, you can also press ^⇧X to show the panel. 

## iPadOS & visionOS

On iPadOS and visionOS, the editor will be shown in a separate window. On iPadOS, the window will open and appear in Split View or Stage Manager if they're enabled in Settings. Similar to macOS, if you don't want a separate window, use just the view modifier to present it as a sheet.

If multitasking is disabled in Settings in iPadOS, the experiments window will appear as a sheet.

iPadOS and visionOS support hardware keyboard shortcuts as well. If you have added either of the above to your app, you can also press ^⇧X on a connected keyboard to show the panel. This works on the keyboard you're using for Mac Virtual Display on visionOS as well.


## iOS, watchOS, and tvOS

On iOS, the experiments editor will appear as a sheet above your app, displayed from the view with the ``SwiftUICore/View/experimentsControlOverlay(hidden:)`` modifier applied.

If your app targets only these platforms, you can avoid adding the ``ExperimentsEditorScene`` declaration to your app. The modifier is sufficient.

The editor will attempt to display controls without covering most of your app. On watchOS, there is not enough screen real estate to do so, and the experiments panel shows in full screen on that platform. If you need to further customize how the experiments show, use the ``ExperimentsEditor``, ``SwiftUICore/EnvironmentValues/openExperimentsWindow`` action, or ``SwiftUICore/View/showsExperimentsSceneAutomatically()`` modifier to choose how and when the experiments editor is displayed.

## UIKit and AppKit

For an UIKit or AppKit application, you may need to manually show the editor UI in a panel, inspector or sheet. For example, you may use a NSHostingController or UIHostingViewController to wrap the SwiftUI ``ExperimentsEditor`` view and set it as the content view of a NSPanel, or as a sheet with `presentViewController:animated:`.

UIKit and AppKit are not aware of changes to the underlying store. To know when changes are about to occur, wrap your view update code with the [`withObservationTracking(_:onChange:)`](https://developer.apple.com/documentation/observation/withobservationtracking(_:onchange:)) function, and schedule a UI update in its change handler. Make sure to call the `value(…)` methods of ``Experiments`` only within observation tracking.

## Cross-Platform Usage

ExperimentsBoard builds on all platforms that support the Swift compiler, including Linux, WebAssembly and Windows. On those platforms, it has no dependencies other than the Swift runtime itself.

If SwiftUI is not available on your platform, the package will lack the API surface associated with the editor UI. The following symbols are available and fully functional even if SwiftUI is not:

- ``Experiments`` and all of its nested types. This includes:
    - ``Experiments/Storage``
    - ``Experiments/Storage/ExperimentDefinition``
    - ``Experiments/Observable``, where the Observation module is supported.
- Types that support this API surface, like ``AnyExperimentStorable``, ``AnyClosedIntegerRange`` and ``AnyClosedFloatingPointRange``.

If your UI toolkit supports tracking changes using the [Observation](https://developer.apple.com/documentation/observation) module, the static methods of the ``Experiments`` class will cause appropriate callbacks. You will need to build experiments editing UI yourself, or publish a package that provides it. See ``Experiments/Storage`` to get started.
