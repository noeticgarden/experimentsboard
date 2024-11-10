
#if canImport(SwiftUI) && !EXPERIMENT_BOARD_DO_NOT_USE_SWIFTUI
import SwiftUI

@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
struct ShowsExperimentsSceneAutomaticallyModifier: ViewModifier {
    @Environment(\.openExperimentsWindow)
    var openExperimentsWindow
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                openExperimentsWindow()
            }
    }
}

extension View {
    /**
     Causes the experiments window to open automatically when the receiver appears.
     
     To function, you must have the experiments editor scene set up by adding ``ExperimentsEditorScene`` to your [App](https://developer.apple.com/documentation/swiftui/app)'s body.
     
     This modifier will use the `onAppear` timing to present the scene, though it will attempt not to present duplicate scenes. If this isn't the root view of a scene, it may cause the scene to reopen suddenly (for example, when navigation in a stack starts or ends).
     
     To control when the window opens programmatically, see the ``SwiftUICore/EnvironmentValues/openExperimentsWindow`` action instead.
     */
    @MainActor
    @available(macOS 14, *)
    @available(iOS 17, *)
    @available(tvOS 17, *)
    @available(watchOS 10, *)
    @available(visionOS 1, *)
    public func showsExperimentsSceneAutomatically() -> some View {
        modifier(ShowsExperimentsSceneAutomaticallyModifier())
    }
}

#endif
