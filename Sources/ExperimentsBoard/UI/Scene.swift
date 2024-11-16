
#if canImport(SwiftUI) && !EXPERIMENT_BOARD_DO_NOT_USE_SWIFTUI
import SwiftUI

/**
 A scene that allows you to access and edit experiments at runtime.
 
 Add this scene to your application to show an experiments editor as a separate window. See <doc:Getting-Started> to see this in action.
 
 Once added to your SwiftUI `App`, on macOS, iOS, iPadOS and visionOS, you can invoke this window by pressing ^⇧X on a connected hardware keyboard or by choosing the command this scene adds to the app's menu.
 
 > Note: You can disable adding the menu command by using the [`commandsRemoved()`](https://developer.apple.com/documentation/swiftui/scene/commandsremoved()) modifier on this scene in your `App`. This will also disable the keyboard shortcut.
 
 Not all platforms support multiple windows. Use the ``SwiftUICore/View/experimentsControlOverlay(hidden:)`` modifier in your app for those platforms. If multiple windows aren't supported, the control displayed by that modifier will open the editor view as a sheet or overlay on top of the current window instead.
 
 For more information on how to access the window, see <doc:Platform-Support>.
 
 > Currently, this scene only supports editing the default `Experiments.Storage`, which is what the static API uses. If you need to edit experiments in your own storage instance, embed or present an ``ExperimentsEditor`` view that you initialize appropriately.
 
 */
@MainActor
@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
public struct ExperimentsEditorScene: Scene {
    static let utilityPanelID = "name.millenomi.ExperimentsBoardUI.scene.utilityPanel"
    static let windowGroupID  = "name.millenomi.ExperimentsBoardUI.scene.windowGroup"
    
    static func disabledID() -> String {
        "name.millenomi.ExperimentsBoardUI.scene.disabled.\(UUID())"
    }
    
    static var fallbackWindowGroupIsEnabled: Bool {
#if os(macOS)
        if #available(macOS 15, *) {
            return false
        } else {
            return true
        }
#elseif os(visionOS)
        if #available(visionOS 2, *) {
            return false
        } else {
            return true
        }
#else
        return true
#endif
    }
    
    static var isAvailable = false
    
    let store: Experiments.Storage
    public init() {
        self.store = .default // TODO: Multiple board scenes for multiple storages.
        Self.isAvailable = true
    }
    
    public var body: some Scene {
#if os(macOS) && compiler(>=6) // Require the macOS 15 SDK.
        if #available(macOS 15, *) {
            UtilityWindow("Experiments", id: Self.utilityPanelID) {
                ExperimentsEditor(store: store)
                    .onAppear {
                        ExperimentsSceneTracking.shared.countOfShowingScenes += 1
                    }
                    .onDisappear {
                        ExperimentsSceneTracking.shared.countOfShowingScenes -= 1
                    }
            }
            .keyboardShortcut("x", modifiers: [.control, .shift])
        }
#endif
        
#if os(visionOS) && compiler(>=6) // Require the visionOS 2 SDK.
        if #available(visionOS 2, *) {
            ExperimentsBoardWindowScene(id: Self.windowGroupID, store: store, isEnabled: true)
                .defaultWindowPlacement { content, context in
                    .init(.utilityPanel)
                }
        }
#endif

        ExperimentsBoardWindowScene(
            id: Self.fallbackWindowGroupIsEnabled ? Self.windowGroupID : Self.disabledID(),
            store: store,
            isEnabled: Self.fallbackWindowGroupIsEnabled
        )
    }
}

// -----

@Observable
@MainActor
@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
final class ExperimentsSceneTracking {
    static let shared = ExperimentsSceneTracking()
    
    var countOfShowingScenes = 0
    
    var isShowing: Bool {
        countOfShowingScenes > 0
    }
}

@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
struct ExperimentsBoardWindowScene: Scene {
    let id: String
    let store: Experiments.Storage
    let isEnabled: Bool
    
    var body: some Scene {
        WindowGroup(id: id) {
            if isEnabled {
                NavigationStack {
                    ExperimentsEditor(store: store)
                        .navigationTitle("Experiments")
                        .toolbarTitleDisplayMode(.inline)
                }
                .onAppear {
                    ExperimentsSceneTracking.shared.countOfShowingScenes += 1
                }
                .onDisappear {
                    ExperimentsSceneTracking.shared.countOfShowingScenes -= 1
                }
            } else {
                EmptyView()
            }
        }
#if !os(tvOS) && !os(watchOS)
        .defaultSize(width: 525, height: 750)
        .commands {
            if isEnabled {
                ExperimentsSceneCommands()
            }
        }
#endif
    }
}

/**
 An action that allows you to open an experiments editor window, if possible.
 
 You do not construct instances of this type. Instead, obtain one from your view's [`Environment`](https://developer.apple.com/documentation/swiftui/environment),
 like so:
 
 ```swift
 @Environment(\.openExperimentsWindow) var openExperimentsWindow
 ```
 
 Invoke this as a function to open the experiments window, if possible:
 
 ```swift
 openExperimentsWindow()
 ```
 
 In order for this action to open a window, ensure you added an ``ExperimentsEditorScene`` to your `App`.
 
 You can invoke this action even on a platform that doesn't support multiple windows, or when you haven't added ``ExperimentsEditorScene`` to your `App`. In that case, it does nothing. Use the ``isAvailable`` property to check whether invoking this action may display a window. For example:
 
 ```swift
 // Only display the button if we can open the window:
 if openExperimentsWindow.isAvailable {
     Button("Open Window") ( … }
 }
 ```
 
 This action only opens separate windows. To manually present the editor UI on a platform that can't open a second window, present an ``ExperimentsEditor`` view instead.
 */
@MainActor
@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
public struct OpenExperimentsWindowAction {
#if !(os(tvOS) || os(watchOS))
    let openWindow: OpenWindowAction
    let supportsMultipleWindows: Bool
#endif
    
    /// Opens the experiments window, if possible.
    public func callAsFunction() {
#if os(tvOS) || os(watchOS)
        return
#else
        guard isAvailable else {
            return
        }
        
#if os(macOS)
        if #available(macOS 15, *) {
            openWindow(id: ExperimentsEditorScene.utilityPanelID)
            return
        }
#endif
        
        openWindow(id: ExperimentsEditorScene.windowGroupID)
#endif
    }
    
    /// If `true`, invoking this action as a functon may succeed. It is `false` otherwise.
    public var isAvailable: Bool {
#if os(tvOS) || os(watchOS)
        false
#else
        supportsMultipleWindows && !ExperimentsSceneTracking.shared.isShowing && ExperimentsEditorScene.isAvailable
#endif
    }
}

extension EnvironmentValues {
    /**
     An action to open the experiments editor window, if possible.
     
     Invoke this action as a function to attempt to open the experiments window if it's not visible. For example, to provide your own open-window button:
     
     ```swift
     struct MyView {
         …
         @Environment(\.openExperimentsWindow)
         var openExperimentsWindow
 
         var body: some View {
             …
             Button("Open Experiments Window") {
                 openExperimentsWindow()
             }
         }
     }
     ```
     
     In order for this action to work, you will need to add a ``ExperimentsEditorScene`` to your `App`. Invoking this will attempt not to open duplicate windows.
     For more, see ``OpenExperimentsWindowAction``.
     */
    @MainActor
    @available(macOS 14, *)
    @available(iOS 17, *)
    @available(tvOS 17, *)
    @available(watchOS 10, *)
    @available(visionOS 1, *)
    public var openExperimentsWindow: OpenExperimentsWindowAction {
#if os(tvOS) || os(watchOS)
        .init()
#else
        .init(openWindow: openWindow, supportsMultipleWindows: supportsMultipleWindows)
#endif
    }
}

#if !os(tvOS) && !os(watchOS)
@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
struct ExperimentsSceneCommands: Commands {
    @Environment(\.openExperimentsWindow)
    var openExperimentsWindow
    
    @Environment(\.supportsMultipleWindows)
    var supportsMultipleWindows
    
    var body: some Commands {
        if supportsMultipleWindows {
            CommandGroup(after: .toolbar) {
                Button("Show Experiments…") {
                    MainActor.assumeIsolated { // Older SDKs aren't correctly annotated wrt. MainActorness here.
                        openExperimentsWindow()
                    }
                }
                .keyboardShortcut("x", modifiers: [.control, .shift])
            }
        }
    }
}
#endif

#endif
