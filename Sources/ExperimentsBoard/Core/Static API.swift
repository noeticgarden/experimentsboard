
extension Experiments {
    @MainActor
    static var observable: Experiments {
#if canImport(Observation) && !EXPERIMENT_BOARD_DO_NOT_USE_OBSERVATION
        if #available(macOS 14,
                      iOS 17,
                      tvOS 17,
                      watchOS 10,
                      visionOS 1, *) {
            Experiments.Storage.Observable.default.snapshot
        } else {
            Experiments()
        }
#else
        Experiments()
#endif
    }
    
    /// Defines a floating-point experiment for the specified key,
    /// registering it with the default experiments store, and
    /// returns its current value.
    ///
    /// This method is observable through the change tracking in
    /// the [Observation](https://developer.apple.com/documentation/observation) module.
    @MainActor
    public static func value<D: BinaryFloatingPoint & Sendable>(_ value: D, key: some ExperimentKey, in range: ClosedRange<D>) -> D {
        observable.value(value, key: key, in: range)
    }
    
    /// Defines an integer experiment for the specified key,
    /// registering it with the default experiments store, and
    /// returns its current value.
    ///
    /// This method is observable through the change tracking in
    /// the [Observation](https://developer.apple.com/documentation/observation) module.
    @MainActor
    public static func value<D: BinaryInteger & Sendable>(_ value: D, key: some ExperimentKey, in range: ClosedRange<D>) -> D {
        observable.value(value, key: key, in: range)
    }
    
    /// Defines a string experiment for the specified key,
    /// registering it with the default experiments store, and
    /// returns its current value.
    ///
    /// This method is observable through the change tracking in
    /// the [Observation](https://developer.apple.com/documentation/observation) module.
    @MainActor
    public static func value(_ value: String, key: some ExperimentKey) -> String {
        observable.value(value, key: key)
    }
}
