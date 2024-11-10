
#if canImport(SwiftUI) && !EXPERIMENT_BOARD_DO_NOT_USE_SWIFTUI
import SwiftUI

@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
struct ExperimentsEditorForm: View {
    struct Grouping: Identifiable {
        var id: String { .init(describing: type) }
        
        var type: Any.Type
        var states: [Experiments.Storage.Observable.ExperimentState]
    }
    
    let groupings: [Grouping]
    let get: (_ key: any ExperimentKey) -> any Sendable
    let set: (_ key: any ExperimentKey, _ newValue: any Sendable & Hashable) -> Void
    
    init(experiments: [Experiments.Storage.Observable.ExperimentState], get: @escaping (_: any ExperimentKey) -> any Sendable, set: @escaping (_ key: any ExperimentKey, _ newValue: any Sendable & Hashable) -> Void) {
        var groupings: [String: Grouping] = [:]
        for experiment in experiments {
            let type = type(of: experiment.key.base as Any)
            let key = String(describing: type)
            groupings[key, default: .init(type: type, states: [])]
                .states.append(experiment)
        }
        
        self.groupings = groupings.sorted(by: { $0.key < $1.key })
            .map { _, value in
                var grouping = value
                grouping.states.sort {
                    String(describing: $0.key) < String(describing: $1.key)
                }
                return grouping
            }
        
        self.get = get
        self.set = set
    }
    
    var body: some View {
        Form {
            ForEach(groupings) { grouping in
                Section(grouping.id) {
                    ForEach(grouping.states) { state in
                        EditorRow(experiment: state, get: get) { newValue in
                            set(state.key, newValue)
                        }
                    }
                }
            }
        }
#if os(macOS)
        .formStyle(.grouped)
#endif
    }
}

enum PreviewLabel: String, Hashable, Sendable {
    case key1
    case key2
}

#Preview {
    if #available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *) {
        ExperimentsEditorForm(
            experiments: [
                .init(key: "A", experiment: .string, value: "lol"),
                .init(key: "B", experiment: .string, value: "lmao"),
                .init(key: 1, experiment: .integerRange(0...100), value: 10),
                .init(key: 2, experiment: .floatingPointRange(0.0...100.0), value: 32.5),
                .init(key: 3, experiment: .string, value: "Hello"),
                .init(key: PreviewLabel.key1, experiment: .string, value: nil),
                .init(key: PreviewLabel.key2, experiment: .string, value: "wow"),
            ],
            get: { _ in Optional<Int>.none },
            set: { print("\($0) -> \($1)") })
    }
}

#endif
