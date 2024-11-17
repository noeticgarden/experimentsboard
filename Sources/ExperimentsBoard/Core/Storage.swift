
/// A protocol for receiving callbacks when a ``Experiments/Storage`` instance's state changes.
///
/// To get callbacks, create your own ``ExperimentsObserver`` and register it with a storage instance by invoking ``Experiments/Storage/addObserver(_:)-6yxtc``.
///
/// This is useful if you're building a thread-safe or lower-level observer to experiments, such as an editor, or if
/// observation (through the Observation module) is not available.
///
/// If you want to observe changes to experiments on the main actor, consider using ``Experiments/Observable`` instead.
///
/// > Note: Experiment observers are strongly referenced (or copied, for value types). Use ``WeakExperimentsObserver`` to weakly reference an observer.
public protocol ExperimentsObserver: Identifiable, Sendable where ID: Sendable {
    /// Invoked when one or more experiments are added, removed or changed.
    ///
    /// Use the ``Experiments/Storage/Raw-swift.struct`` view's methods to obtain the new set of experiments.
    ///
    /// > Important: You may observe invocations to your observer during the use of ``Experiments/Storage/Raw-swift.struct`` accessors. These invocations occur after the storage's mutex is released; it is fine to access the storage in those callbacks.
    func experimentDefinitionsDidChange() async
    
    /// Invoked when the value of one or more experiments is changed.
    ///
    /// Use the ``Experiments/Storage/Raw-swift.struct`` view's methods to obtain the new set of values.
    ///
    /// > Important: You may observe invocations to your observer during the use of ``Experiments/Storage/Raw-swift.struct`` accessors. These invocations occur after the storage's mutex is released; it is fine to access the storage in those callbacks.
    func experimentValuesDidChange() async
}

extension ExperimentsObserver {
    public nonisolated func experimentValuesDidChange() async {
        // Do nothing.
    }
    
    public nonisolated func experimentDefinitionsDidChange() async {
        // Do nothing.
    }
}

extension ExperimentsObserver where Self: AnyObject, ID == ObjectIdentifier {
    /// By default, tags an object that's an observer with its object identifier as its overall ID.
    public var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}

/**
 A wrapper that stores a type-erased version of an experiment's key or value.
 
 This type works similarly to [`AnyHashable`](https://developer.apple.com/documentation/swift/anyhashable/), except it guarantees the erased value is also [`Sendable`](https://developer.apple.com/documentation/swift/sendable/). It does not have `AnyHashable`'s automatic bridging behavior.
 
 Use ``Swift/AnyHashable/init(_:)`` or cast the ``base`` from this type directly to obtain the original, underlying hashable value.
 */
public struct AnyExperimentStorable: Hashable, Sendable {
    public static func == (lhs: AnyExperimentStorable, rhs: AnyExperimentStorable) -> Bool {
        AnyHashable(lhs.base) == AnyHashable(rhs.base)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(base)
    }
    
    /// The underlying, erased value.
    public let base: any ExperimentKey
    
    /// Creates a new instance of this type by erasing the provided value.
    ///
    /// If you pass an ``AnyExperimentStorable`` to this method, it will not be double-wrapped.
    public init(_ core: some ExperimentKey) {
        if let core = core as? AnyExperimentStorable {
            self.base = core.base
        } else {
            self.base = core
        }
    }
}

extension AnyHashable {
    /// Unwraps a ``AnyExperimentStorable`` to obtain the hashable value it contains.
    public init(_ wrapper: AnyExperimentStorable) {
        self = AnyHashable(wrapper.base)
    }
}


extension Experiments {
    /**
     A low-level, thread-safe storage type that coordinates editing experiments.
     
     You don't generally interact with this type unless:
     - you want to segregate some experiments and control their lifecycle; or
     - you're building a low-level observer for experiments, such as editor UI.
     
     If possible, use the ``Experiments`` type to interact with experiments instead; see its documentation
     for details. For example, to control the lifecycle of some experiments, see the examples in that documentation
     for how to build a separate store and interact with it.
     
     If that API is not sufficient, use the ``raw`` property on this type to obtain direct accessors
     to the storage and perform editing or lookup operations.
     
     Uses of ``Experiments`` that do not specify a store will interact with the default store, accessible via the ``default`` property.
     
     ### Raw Access & Thread-Safety
     
     Use the methods in the ``Raw`` interface to access the contents of this storage. A storage instance can contain:
     
     - Experiment definitions, accessible through ``Raw/subscript(experimentFor:)``, determine
     what type of experiment is conducted, what the default value is, and options such as acceptable ranges for numeric experiments. See ``ExperimentDefinition`` for more.
     
     - Value overrides, accessible through ``Raw/subscript(_:)``, cause the `value(…)` methods of
     the ``Experiments`` type to return different values for their experiments.
     
     You can perform single-key accesses or get a bulk copy of either dictionary using the ``Raw/values`` and ``Raw/experiments``
     properties, or even of the entire state of the storage using the ``Raw/state`` property.
     
     Each access performed through these accessors is atomic, synchronous, and unrelated to other accesses
     any code performs on the same ``Storage``, including through different ``Raw`` interfaces. This guarantees
     correctness of the storage in the face of multiple actors or threads using it concurrently.
     
     > Important: Each use of an accessor in ``Raw`` is protected by a mutex. Concurrent usage is supported,
     but you may need to think about issues such as time-of-access-to-time-of-use, lost reads, or lost writes in
     your invoking code.
     
     */
    public final class Storage: @unchecked Sendable {
        /// The default instance of storage.
        ///
        /// This instance stores experiments and values for uses of ``Experiments`` where the storage
        /// isn't specified.
        public static let `default` = Experiments.Storage()
        
        /// Creates a new instance of storage with no content.
        public init() {}
        
        private let state = LockedState(initialState: RequiresLock())
        struct RequiresLock {
            var values:        [AnyExperimentStorable: AnyExperimentStorable] = [:]
            var experiments:   [AnyExperimentStorable: ExperimentDefinition] = [:]
            var observers:     [AnyExperimentStorable: any ExperimentsObserver] = [:]
            var weakObservers: [AnyExperimentStorable: any _WeakExperimentsObserverBox] = [:]
            
            mutating func gatherObservers() -> [any ExperimentsObserver] {
                var observers = Array(observers.values)
                for (key, box) in weakObservers {
                    if let observer = box.get() {
                        observers.append(observer)
                    } else {
                        weakObservers[key] = nil
                    }
                }
                
                return observers
            }
        }
        
        /// A low-level definition of an experiment, registered with ``Storage``.
        public struct ExperimentDefinition: Sendable, Equatable {
            public static func == (lhs: Experiments.Storage.ExperimentDefinition, rhs: Experiments.Storage.ExperimentDefinition) -> Bool {
                lhs.experiment == rhs.experiment && AnyHashable(lhs.defaultValue) == AnyHashable(rhs.defaultValue)
            }
            
            /// The type and options of the experiment.
            public var experiment: ExperimentKind
            
            /// The default value provided by the user for this experiment.
            ///
            /// This value is wrapped in a ``AnyExperimentStorable`` type eraser. See that type for more information.
            public var defaultValue: AnyExperimentStorable
            
            /// Creates a new definition using an already-wrapped default value.
            ///
            /// Use low-level API in ``Storage/Raw`` to register a new definition with storage.
            public init(experiment: ExperimentKind, defaultValue: AnyExperimentStorable) {
                self.experiment = experiment
                self.defaultValue = defaultValue
            }

            /// Creates a new definition by wrapping the provided default value.
            ///
            /// Use low-level API in ``Storage/Raw`` to register a new definition with storage.
            public init(experiment: ExperimentKind, defaultValue: some Hashable & Sendable) {
                self.experiment = experiment
                self.defaultValue = .init(defaultValue)
            }
        }
        
        /// A view onto the contents of a ``Storage`` for low-level clients.
        public struct Raw {
            let storage: Storage
            
            /// Returns or registers the current value of an experiment in its current
            /// type-erased wrapper.
            ///
            /// An editor can use this subscript to get or set values for experiments.
            ///
            /// This accessor returns the current value of the experiment without unwrapping it from its ``AnyExperimentStorable`` wrapper.
            /// Use the convenience accessors at ``subscript(_:)`` and the ``set(_:for:)`` function to read and write values
            /// without an intervening wrapper.
            ///
            /// > Important: Every single use of the getter or setter will acquire the storage's mutex for its duration. See the discussion in ``Storage`` for more information.
            public subscript(raw key: some ExperimentKey) -> AnyExperimentStorable? {
                get {
                    storage.state.withLock {
                        $0.values[AnyExperimentStorable(key)]
                    }
                }
                nonmutating set {
                    let observers: [any ExperimentsObserver] = storage.state.withLock {
                        let erasedKey = AnyExperimentStorable(key)
                        
                        let old = $0.values[erasedKey]
                        guard old != newValue else {
                            return []
                        }
                        
                        $0.values[erasedKey] = newValue
                        return $0.gatherObservers()
                    }
                    
                    for observer in observers {
                        Task {
                            await observer.experimentValuesDidChange()
                        }
                    }
                }
            }
            
            /// Returns  the current value of an experiment.
            ///
            /// An editor can use this subscript to get the values of experiments.
            ///
            /// Using this subscript is equivalent to invoking the ``subscript(raw:)`` getter,
            /// and then unwrapping the returned wrapper.
            ///
            /// Because of the need to preserve type information before erasure, there is not
            /// a corresponding setter to this subscript. Use the ``set(_:for:)`` function
            /// instead.
            ///
            /// > Important: Every single use of this getter will acquire the storage's mutex for its duration. See the discussion in ``Storage`` for more information.
            public subscript(_ key: some ExperimentKey) -> (any Hashable & Sendable)? {
                self[raw: key]?.base
            }
            
            /// Registers the current value of an experiment.
            ///
            /// An editor can use this subscript to set values for experiments.
            ///
            /// Using this method is equivalent to invoking the ``subscript(raw:)`` setter,
            /// after wrapping the value appropriately.
            ///
            /// > Note: This functions as the setter equivalent of ``subscript(_:)``, with a signature
            /// > that preserves type information to allow for wrapping.
            ///
            /// > Important: Every single use of this method will acquire the storage's mutex for its duration. See the discussion in ``Storage`` for more information.
            public func set(_ value: some Hashable & Sendable, for key: some ExperimentKey) {
                self[raw: key] = .init(value)
            }
            
            /// Returns or registers the current definition of a new experiment.
            ///
            /// An editor can use this subscript to add a new experiment. In addition, ``Experiments`` sets this for you when you invoke any of its `value(…)` methods.
            ///
            /// > Important: Every single use of the getter or setter will acquire the storage's mutex for its duration. See the discussion in ``Storage`` for more information.
            public subscript(experimentFor key: some ExperimentKey) -> ExperimentDefinition? {
                get {
                    storage.state.withLock {
                        $0.experiments[AnyExperimentStorable(key)]
                    }
                }
                nonmutating set {
                    let observers: [any ExperimentsObserver] = storage.state.withLock {
                        let erasedKey = AnyExperimentStorable(key)
                        
                        let old = $0.experiments[erasedKey]
                        guard old != newValue else {
                            return []
                        }
                        
                        $0.experiments[erasedKey] = newValue
                        return $0.gatherObservers()
                    }
                    
                    for observer in observers {
                        Task {
                            await observer.experimentValuesDidChange()
                        }
                    }
                }
            }
            
            /// Returns the current state of experiment values in storage.
            ///
            /// This method returns the same content as ``values``, without unwrapping keys from their original ``AnyExperimentStorable`` wrappers. This means, for example, that this may not work as you expect:
            ///
            /// ```swift
            /// let values = storage.raw.valuesWithRawKeys
            /// let value = values["Wow"] // Always nil.
            /// ```
            ///
            /// Instead, you need to wrap or unwrap values from ``AnyExperimentStorable``. For example:
            ///
            /// ```swift
            /// let values = storage.raw.valuesWithRawKeys
            /// let value = values[AnyExperimentStorable("Wow")] // Works as expected.
            /// ```
            ///
            /// In exchange for this, the return value of this method is [`Sendable`](https://developer.apple.com/documentation/swift/sendable/), and can safely be saved or loaded across isolation boundaries.
            ///
            /// > Important: Every single use of this getter will acquire the storage's mutex for its duration. See the discussion in ``Storage`` for more information.
            public var valuesWithRawKeys: [AnyExperimentStorable: AnyExperimentStorable] {
                storage.state.withLock {
                    $0.values
                }
            }
            
            /// Returns the current state of experiment definitions in storage.
            ///
            /// This method returns the same content as ``experiments``, without unwrapping keys from their original ``AnyExperimentStorable`` wrappers. This means, for example, that this may not work as you expect:
            ///
            /// ```swift
            /// let experiments = storage.raw.experimentsWithRawKeys
            /// let experiment = experiments["Wow"] // Always nil.
            /// ```
            ///
            /// Instead, you need to wrap or unwrap values from ``AnyExperimentStorable``. For example:
            ///
            /// ```swift
            /// let experiments = storage.raw.valuesWithRawKeys
            /// let experiment = experiments[AnyExperimentStorable("Wow")]
            ///     // Works as expected.
            /// ```
            ///
            /// In exchange for this, the return value of this method is [`Sendable`](https://developer.apple.com/documentation/swift/sendable/), and can safely be saved or loaded across isolation boundaries.
            ///
            /// > Important: Every single use of this getter will acquire the storage's mutex for its duration. See the discussion in ``Storage`` for more information.
            public var experimentsWithRawKeys: [AnyExperimentStorable: ExperimentDefinition] {
                storage.state.withLock {
                    $0.experiments
                }
            }
            
            /// Returns the current state of experiment values in storage.
            ///
            /// This contains the same values you could access via ``subscript(_:)``, but the access is atomic for the entire contents of the storage.
            ///
            /// The result value of this method isn't [`Sendable`](https://developer.apple.com/documentation/swift/sendable/), even though all values in the dictionary are guaranteed to be. If you need a version that is, invoke the ``valuesWithRawKeys`` property instead.
            ///
            /// > Important: Every single use of this getter will acquire the storage's mutex for its duration. See the discussion in ``Storage`` for more information.
            public var values: [AnyHashable: any Sendable & Hashable] {
                let values = storage.state.withLock {
                    $0.values
                }
                
                return Dictionary(uniqueKeysWithValues: values.map { (key, value) in
                    (AnyHashable(key.base), value.base)
                })
            }
            
            /// Returns the current state of experiment definitions in storage.
            ///
            /// This contains the same values you could access via ``subscript(experimentFor:)``, but the access is atomic for the entire contents of the storage.
            ///
            /// The result value of this method isn't [`Sendable`](https://developer.apple.com/documentation/swift/sendable/), even though all values in the dictionary are guaranteed to be. If you need a version that is, invoke the ``experimentsWithRawKeys`` property instead.
            ///
            /// > Important: Every single use of this getter will acquire the storage's mutex for its duration. See the discussion in ``Storage`` for more information.
            public var experiments: [AnyHashable: ExperimentDefinition] {
                let experiments = storage.state.withLock {
                    $0.experiments
                }
                
                return Dictionary(uniqueKeysWithValues: experiments.map { (key, value) in
                    (AnyHashable(key.base), value)
                })
            }
            
            /// A snapshot of the raw state of ``Storage``.
            ///
            /// Use this type with the ``state-swift.property`` property to read or write the contents of the entire storage
            /// in a single, atomic operation.
            public struct State: Sendable {
                /// A dictionary of all values set for all experiments in storage.
                ///
                /// See the discussion for ``Storage/Raw/valuesWithRawKeys`` for working with wrapped ``AnyExperimentStorable`` keys.
                public var values:      [AnyExperimentStorable: AnyExperimentStorable] = [:]
                
                /// A dictionary of all experiment definitions for all experiments in storage.
                ///
                /// See the discussion for ``Storage/Raw/experimentsWithRawKeys`` for working with wrapped ``AnyExperimentStorable`` keys.
                public var experiments: [AnyExperimentStorable: ExperimentDefinition] = [:]
                
                /// Creates a new instance of state.
                ///
                /// To actually set it on storage, use this value with ``Raw/state``.
                public init(values: [AnyExperimentStorable: AnyExperimentStorable], experiments: [AnyExperimentStorable: ExperimentDefinition]) {
                    self.values = values
                    self.experiments = experiments
                }
            }
            
            /// Returns the storage's contents as a low-level snapshot.
            ///
            /// See the ``State`` type for a discussion of the state you can get or set.
            ///
            /// The state is set atomically in exclusion with all other invocations of accessors on this type. You may need to account for e.g. lost reads or lost writes if you replace state atomically, especially if you do so as a function of previous state.
            ///
            /// > Important: Every single use of this getter or setter will acquire the storage's mutex for its duration. See the discussion in ``Storage`` for more information.
            public var state: State {
                get {
                    storage.state.withLock {
                        .init(values: $0.values, experiments: $0.experiments)
                    }
                }
                nonmutating set {
                    let observers = storage.state.withLock {
                        $0.values = newValue.values
                        $0.experiments = newValue.experiments
                        return $0.gatherObservers()
                    }
                    
                    for observer in observers {
                        Task {
                            await observer.experimentDefinitionsDidChange()
                            await observer.experimentValuesDidChange()
                        }
                    }
                }
            }
        }
        
        /// Obtains a low-level view that allows you to access the raw contents of this storage.
        ///
        /// See the ``Storage`` type's discussion for more information.
        ///
        /// Even though the ``Raw`` type is a value type, it's a view over a shared resource rather than a value in itself. All values of that type access obtained from the same storage access the same backend and lock the same mutex. Copying the value does not change this.
        public var raw: Raw { .init(storage: self) }
        
        /// Adds an observer that is informed of changes to this storage.
        ///
        /// If a different observer with the same ID is already registered, it will be atomically removed and replaced with this one.
        ///
        /// The observer will be strongly referenced (or copied, for value types). To weakly reference an observer, conform to ``WeakExperimentsObserver`` and invoke  ``addObserver(_:)-ngjv`` to register it.
        ///
        /// > Important: Every single use of this method will acquire the storage's mutex for its duration. This means that the observer will get notifications for any changes you can guarantee are sequenced after this method returns, but there is no guarantee that concurrently executing changes may produce notifications for this observer. See the discussion in ``Storage`` for more information.
        /// >
        /// > Note that you may observe invocations to your observer during the use of ``Raw-swift.struct`` accessors. These invocations occur after the storage's mutex is released; it is fine to access the storage in those callbacks.
        public func addObserver(_ observer: some ExperimentsObserver) {
            state.withLock {
                $0.observers[AnyExperimentStorable(observer.id)] = observer
                $0.weakObservers[AnyExperimentStorable(observer.id)] = nil
            }
        }
        
        /// Adds an observer that is informed of changes to this storage, weakly referenced.
        ///
        /// If a different observer with the same ID is already registered, it will be atomically removed and replaced with this one.
        ///
        /// The observer will be referenced weakly. When it deallocates, it will automatically be removed.
        ///
        /// > Note: To strongly reference an observer, use ``ExperimentsObserver`` and invoke ``addObserver(_:)-6yxtc`` instead.
        ///
        /// > Important: Every single use of this method will acquire the storage's mutex for its duration. This means that the observer will get notifications for any changes you can guarantee are sequenced after this method returns, but there is no guarantee that concurrently executing changes may produce notifications for this observer. See the discussion in ``Storage`` for more information.
        /// >
        /// > Note that you may observe invocations to your observer during the use of ``Raw-swift.struct`` accessors. These invocations occur after the storage's mutex is released; it is fine to access the storage in those callbacks.
        public func addObserver(_ observer: some WeakExperimentsObserver) {
            state.withLock {
                $0.observers[AnyExperimentStorable(observer.id)] = nil
                $0.weakObservers[AnyExperimentStorable(observer.id)] = WeakObserverBox(actualObserver: observer)
            }
        }
        
        /// Removes an observer from the set of observers informed of changes to this storage.
        ///
        /// The ID of the value you pass in will be used to remove the observer, rather than the value itself. If no observer with the same ID is registered, this method has no effect; and if an observer is different, but registered with the same ID, that observer will be removed.
        ///
        /// > Important: Every single use of this method will acquire the storage's mutex for its duration. This means that the observer will not get notifications for any changes you can guarantee are sequenced after this method returns, but may or may not get notifications for changes executed concurrently with the removal. See the discussion in ``Storage`` for more information.
        public func removeObserver(_ observer: some ExperimentsObserver) {
            state.withLock {
                $0.observers[AnyExperimentStorable(observer.id)] = nil
                $0.weakObservers[AnyExperimentStorable(observer.id)] = nil
            }
        }
        
        /// Removes an observer from the set of observers informed of changes to this storage, given its ID.
        ///
        /// If no observer with the same ID is registered, this method has no effect.
        ///
        /// > Important: Every single use of this method will acquire the storage's mutex for its duration. This means that the observer will not get notifications for any changes you can guarantee are sequenced after this method returns, but may or may not get notifications for changes executed concurrently with the removal. See the discussion in ``Storage`` for more information.
        public func removeObserver(id: some Hashable & Sendable) {
            state.withLock {
                $0.observers[AnyExperimentStorable(id)] = nil
            }
        }
    }
}
