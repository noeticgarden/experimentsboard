
/// Defines the requirements for an experiment key.
///
/// Conform your type to this alias to quickly set up new keys for your experiments.
/// For example:
///
/// ```swift
/// enum MyExperiments: ExperimentKey { … }
/// ```
public typealias ExperimentKey = Hashable & Sendable

#if canImport(Observation) && !EXPERIMENT_BOARD_DO_NOT_USE_OBSERVATION
import Observation

extension Experiments.Storage {
    /**
     Allows code that uses the Observation module, like SwiftUI, to observe changes in experiment storage.
     
     Each instance of this class is associated with one ``Experiments/Storage`` and will produce
     change callbacks that can be tracked by [`withObservationTracking(_:onChange:)`](https://developer.apple.com/documentation/observation/withobservationtracking(_:onchange:)) whenever any experiment definition or value changes in the storage instance.
     
     To ensure updates occur, access experiment information within that block (or within a similarly tracked context, like a SwiftUI `View`'s `body`) by using the ``snapshot`` or ``states`` properties.
     
     Using the static methods of the ``Experiments`` type will also similarly trigger observation callbacks for the ``Experiments/Storage/default`` storage instance. You only need to create instances of this class if you want experiment state information, on top of experiment values; or if you want to follow the state of a different storage instance.
     
     > Note: This class is bound to the main actor. To observe the state of storage outside of the main actor, use ``ExperimentsObserver`` instead.
     */
    @available(macOS 14, *)
    @available(iOS 17, *)
    @available(tvOS 17, *)
    @available(watchOS 10, *)
    @available(visionOS 1, *)
    @Observable
    @MainActor
    public final class Observable {
        final actor Observer: ExperimentsObserver {
            weak var owner: Observable?
            
            func refresh() async {
                await owner?.refresh()
            }
            
            nonisolated func experimentValuesDidChange() {
                Task {
                    await refresh()
                }
            }
            
            nonisolated func experimentDefinitionsDidChange() {
                Task {
                    await refresh()
                }
            }
            
            func set(owner: Observable) {
                self.owner = owner
            }
        }
        
        public struct ExperimentState: Sendable, Identifiable {
            public var id: AnyExperimentStorable { key }
            public var key: AnyExperimentStorable
            public var experiment: ExperimentKind
            public var value: (any Sendable & Hashable)?
            
            public init(key: some ExperimentKey, experiment: ExperimentKind, value: (any Sendable & Hashable)?) {
                self.key = AnyExperimentStorable(key)
                self.experiment = experiment
                self.value = value
            }
            
            public static func all(from store: Experiments.Storage) -> [Self] {
                let values = store.raw.valuesWithRawKeys
                let experiments = store.raw.experimentsWithRawKeys
                
                return experiments.compactMap { key, definition -> ExperimentState? in
                    return ExperimentState(key: key, experiment: definition.experiment, value: values[key]?.base ?? definition.defaultValue.base)
                }
            }
        }
        
        /// Provides the state of experiment values on the associated storage instance, and allows registering new experiments.
        ///
        /// This property will change and emit Observable change notifications as the storage changes.
        private(set) public var snapshot: Experiments
        
        /// Provides the current state and definitions of all registered experiments on the associated storage instance.
        ///
        /// This property will change and emit Observable change notifications as the storage changes.
        private(set) public var states: [ExperimentState] = []
        
        private let store: Experiments.Storage
        private let observer = Observer()
        
        /// Creates a new ``Experiments/Storage/Observable`` that updates on the main actor as the specified storage instance's content changes.
        public init(_ store: Experiments.Storage = .default) {
            self.store = store
            self.states = ExperimentState.all(from: store)
            self.snapshot = Experiments(store)
            Task {
                await observer.set(owner: self)
                store.addObserver(observer)
            }
        }
        
        deinit {
            store.removeObserver(observer)
        }
        
        private func refresh() {
            self.states = ExperimentState.all(from: store)
            self.snapshot = Experiments(store)
        }
    }
}
#endif
