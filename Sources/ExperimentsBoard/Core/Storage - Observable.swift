
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
     This type has been renamed to ``Experiments/Observable``.
     */
    @available(*, deprecated, renamed: "Experiments.Observable")
    @available(macOS 14, *)
    @available(iOS 17, *)
    @available(tvOS 17, *)
    @available(watchOS 10, *)
    @available(visionOS 1, *)
    public typealias Observable = Experiments.Observable
}

extension Experiments {
    /**
     Allows code that uses the Observation module, like SwiftUI, to observe changes in experiment storage.
     
     Each instance of this class is associated with one ``Experiments/Storage`` and will produce
     change callbacks that can be tracked by [`withObservationTracking(_:onChange:)`](https://developer.apple.com/documentation/observation/withobservationtracking(_:onchange:)) whenever any experiment definition or value changes in the storage instance.
     
     To ensure updates occur, access experiment information within that block (or within a similarly tracked context, like a SwiftUI `View`'s `body`) by using the ``snapshot`` or ``states`` properties.
     
     Using the static methods of the ``Experiments`` type will also similarly trigger observation callbacks for the ``Experiments/Storage/default`` storage instance. You only need to create instances of this class if you want experiment state information, on top of experiment values; or if you want to follow the state of a different storage instance.
     
     ## Concurrency
     
     Instances of this class are not `Sendable` and remain isolated to one isolation context at a time.
     
     If you want to use an observer that is isolated to the main actor, use the ``init(_:)`` initializer. Observation callbacks will be sent isolated to that actor.
     
     If you want to isolate callbacks to another  isolation context, use the ``init(_:executor:)`` callback. The closure you provide must eventually call the ``refresh()`` method in the context of your choice, and the change callbacks will be emitted isolated to that specific context.
     
     For example:
     
     ```swift
     actor MyActor {
        var observable: Observable?
     
        init(store: Experiments.Storage) {
            observable =
                Experiments.Observable(store)
                { [weak self] in
                   await self?.refresh()
                }
        }
     
        private func refresh() {
            observable?.refresh()
        }
     }
     ```
    
     Since ``Observable`` isn't `Sendable`, the call to ``refresh()`` ensures that the change callbacks are occurring in the isolation context that owns the ``Observable`` instance.

     */
    @available(macOS 14, *)
    @available(iOS 17, *)
    @available(tvOS 17, *)
    @available(watchOS 10, *)
    @available(visionOS 1, *)
    @Observable
    public final class Observable {
        @MainActor
        static let `default` = Observable()
        
        final actor Observer: WeakExperimentsObserver {
            weak var owner: Observable?
            init(owner: Observable) {
                self.owner = owner
            }
            
            func refresh() async {
                await owner?.executor?()
            }
            
            nonisolated func experimentValuesDidChange() async {
                await refresh()
            }
            
            nonisolated func experimentDefinitionsDidChange() async {
                await refresh()
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
        @ObservationIgnored private var observer: Observer?
        @ObservationIgnored private var executor: (@Sendable () async -> Void)?
        
        /// Creates a new ``Experiments/Observable`` that updates on the main actor as the specified storage instance's content changes.
        ///
        /// - Parameter store: The storage to observe.
        @MainActor
        public init(_ store: Experiments.Storage = .default) {
            self.store = store
            self.states = ExperimentState.all(from: store)
            self.snapshot = Experiments(store)
            
            self.executor = { @MainActor [weak self] in
                self?.refresh()
            }
            
            let observer = Observer(owner: self)
            store.addObserver(observer)
            self.observer = observer
        }
        
        /// Creates a new ``Experiments/Observable`` that updates by invoking the specified executor as the specified storage instance's content changes.
        ///
        /// Use this method to invoke observable callbacks to a specific isolation context; for example, if you're using an `actor`, pass a closure that invokes `notification` on the actor's executor.
        ///
        /// To use this method, pass a closure that calls ``refresh()`` on this instance. See the concurrency discussion in the ``Observable`` documentation for more information.
        ///
        /// - Parameter store: The storage to observe.
        /// - Parameter executor: A block that will be invoked when the observable needs to refresh. It must ensure that the notification is invoked on the same isolation as this observer.
        public init(_ store: Experiments.Storage = .default, executor: @escaping @Sendable () async -> Void) {
            self.store = store
            self.states = ExperimentState.all(from: store)
            self.snapshot = Experiments(store)
            self.executor = executor
            
            let observer = Observer(owner: self)
            store.addObserver(observer)
            self.observer = observer
        }
        
        /// Causes the observer to refresh its state from the ``Experiments/Storage`` it's associated to.
        ///
        /// If you're using ``Observable`` from the main actor, with the ``init(_:)`` constructor, this method is invoked for you automatically as the storage changes.
        ///
        /// If you're supplying your own isolation, you must call this method from the `executor` closure you pass the ``init(_:executor:)`` initializer. This ensures that the refresh only ever occurs in the isolation context you provide.
        public func refresh() {
            self.states = ExperimentState.all(from: self.store)
            self.snapshot = Experiments(self.store)
        }
    }
}

@available(*, unavailable)
extension Experiments.Observable: Sendable {}
#endif
