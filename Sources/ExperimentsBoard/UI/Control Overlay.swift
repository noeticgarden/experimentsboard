
#if canImport(SwiftUI) && !EXPERIMENT_BOARD_DO_NOT_USE_SWIFTUI
import SwiftUI

extension View {
    /**
     Displays the experiments control as an overlay on top of this view.
     
     - Parameter hidden: If true, hides the overlay, effectively removing it from the scene. If false, ensures the overlay is shown. `nil` will cause the control to show only if there isn't another visible way to show the editor already.
     
     Using this modifier allows access to the default editor UI on platforms without a connected hardware keyboard. See <doc:Getting-Started> for more information.
     
     The experiments overlay will show a control as an overlay to the receiver, in the bottom trailing corner. If the view doesn't span the entire window or screen, this may cause it to crowd atop the view; you may want to expand a root view using `.frame(maxWidth: .infinity, maxHeight: .infinity)` to compensate for this.
     
     On macOS, iPadOS and visionOS, if you added ``ExperimentsEditorScene`` to your app and you're in an environment that supports multiple windows, the control will open a new window. Otherwise, and on all other platforms, it will show the experiments editor as a sheet presented on this view's window.
     
     Note that some windows, such as visionOS volumes, may not support sheet presentations. Make sure the control can use a separate scene for those windows.
     
     > Note: On macOS, if `hidden` is `nil` (the default), the control will be hidden if the View > Show Experiments menu item is accessible on the screen. Set `hidden` to `false` to force it to be visible regardless of platform.
     
     */
    @MainActor
    @available(macOS 14, *)
    @available(iOS 17, *)
    @available(tvOS 17, *)
    @available(watchOS 10, *)
    @available(visionOS 1, *)
    public func experimentsControlOverlay(hidden: Bool? = nil) -> some View {
        modifier(ExperimentsControlOverlayModifier(controlVisibility: {
            switch hidden {
            case nil:
                .automatic
                
            case true?:
                .hidden
                
            case false?:
                .visible
            }
        }()))
    }
}

// -----

@MainActor
@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
enum ExperimentsControlVisibility {
    static var automatic: Self {
#if os(macOS)
        ExperimentsEditorScene.isAvailable ? .hidden : .visible
#else
        .visible
#endif
    }
    
    case visible
    case hidden
}

@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
struct ExperimentsControlOverlayModifier: ViewModifier {
    let controlVisibility: ExperimentsControlVisibility
    
    @Environment(\.openExperimentsWindow)
    var openExperimentsWindow

    @State var isPresentingSheet = false
    
    var editor: some View {
        let editor = ExperimentsEditor(store: .default)
            .navigationTitle("Experiments")
            .presentationDetents([.fraction(0.3), .medium, .large])
            .presentationDragIndicator(.hidden)
            .modifier(PagePresentationSizingIfAvailable())
            .modifier(Fall2024ModifiersIfAvailable())
#if !os(tvOS) && !os(watchOS)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        self.isPresentingSheet = false
                    } label: {
                        Text("Done")
                    }
                }
            }
#endif
        
#if os(macOS)
        return editor
#else
        return NavigationStack {
            editor
        }
#endif
    }
    
    func body(content: Content) -> some View {
        content
#if os(tvOS)
            .fullScreenCover(isPresented: $isPresentingSheet) {
                GeometryReader { geometry in
                    let editorFrame = CGSize(
                        width: geometry.size.width * 0.4,
                        height: geometry.size.height
                    )
                    
                    let shadeFrame = CGSize(
                        width: geometry.size.width - editorFrame.width,
                        height: geometry.size.height
                    )
                    
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .frame(width: shadeFrame.width, height: shadeFrame.height)
                        .position(x: shadeFrame.width / 2, y: shadeFrame.height / 2)
                    
                    editor
                        .padding()
                        .padding(.leading, geometry.safeAreaInsets.trailing)
                        .background(.regularMaterial)
                        .frame(width: editorFrame.width, height: editorFrame.height)
                        .position(x: geometry.size.width - editorFrame.width / 2, y: geometry.size.height / 2)
                }
            }
#else
            .sheet(isPresented: $isPresentingSheet) {
                editor
            }
#endif
            .overlay {
                if controlVisibility == .visible && !ExperimentsSceneTracking.shared.isShowing {
                    GeometryReader { geometry in
                        let side = max(44,
                                       min(geometry.size.width * 0.15, geometry.size.height * 0.15))
                        
                        ZStack {
                            Button {
                                if openExperimentsWindow.isAvailable {
                                    openExperimentsWindow()
                                    return
                                }
                                
                                self.isPresentingSheet = true
                            } label: {
                                Label("Experiments", systemImage: "gear")
                                    .opacity(0.2)
                                    .frame(width: side, height: side)
                            }
#if !os(tvOS) && !os(watchOS)
                            .keyboardShortcut("x", modifiers: [.control, .shift])
#endif
#if os(macOS)
                            .buttonStyle(.accessoryBar)
#else
                            .buttonStyle(.plain)
#endif
                            .buttonBorderShape(.roundedRectangle)
#if !os(macOS) && !os(visionOS) && !os(watchOS)
                            .hoverEffect()
#endif
                            .labelStyle(.iconOnly)
                            .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
    }
}

@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
fileprivate struct PreviewView: View {
    var body: some View {
        Text("Hello!")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .experimentsControlOverlay(hidden: false)
    }
}

fileprivate struct PagePresentationSizingIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
#if compiler(>=6)
        if #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) {
            content.presentationSizing(.page)
        } else {
            content
        }
#else
        content
#endif
    }
}

fileprivate struct Fall2024ModifiersIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *) {
            content
                .toolbarTitleDisplayMode(.inline)
                .presentationBackgroundInteraction(.enabled)
        } else {
            content
        }
    }
}

#if os(visionOS)
#Preview(windowStyle: .automatic) {
    PreviewView()
}
#endif
#Preview {
    if #available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *) {
        PreviewView()
    }
}
#endif
