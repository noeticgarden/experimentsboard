
#if canImport(SwiftUI) && !EXPERIMENT_BOARD_DO_NOT_USE_SWIFTUI
import SwiftUI

/**
 A view that shows an editor for current experiments.
 
 Add this view to your hierarchy to show an editor that allows you to edit all experiments in a specified `Experiments.Storage`.
 
 Consider using the ``ExperimentsEditorScene`` in your app first rather than embedding an editor directly. You may want to use this view if you need to edit experiments in a storage that is not the default one, or if you need to present the editing UI in a custom way within your view hierarchy.
 */
@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
public struct ExperimentsEditor: View {
    let store: Experiments.Storage
    @State var observable: Experiments.Observable?
    
    /// Creates a new editor view that presents and edits experiments for the specified store.
    public init(store: Experiments.Storage = .default) {
        self.store = store
    }
    
    public var body: some View {
        ExperimentsEditorForm(
            experiments: observable?.states ?? [],
            get: {
                store.raw[$0]
            },
            set: { key, newValue in
                store.raw[raw: key] = AnyExperimentStorable(newValue)
            }
        )
        .onChange(of: ObjectIdentity(store), initial: true) { oldValue, newValue in
            self.observable = Experiments.Observable(newValue.object)
        }
    }
}

#if compiler(>=6) // Ensure that previews are for Xcode 16 only.
#Preview {
    if #available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *) {
        ExperimentsEditor(store: {
            let store = Experiments.Storage()
            let experiments = Experiments(store)
            
            _ = experiments.value("Nice", key: "Wow")
            _ = experiments.value(1, key: "Nice", in: 1...100)
            _ = experiments.value(100.0, key: "Optimal", in: -200.0...200.0)
            
            return store
        }())
    }
}
#endif
#endif
