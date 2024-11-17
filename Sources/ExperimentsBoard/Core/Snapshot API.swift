
/**
 Sets up and gets the current value for all your experiments.
 
 The `Experiments` type is the main entry point for setting up experiments.
 
 Use the `value(…)` methods on this class to define which experiments you would like. The first
 time those methods are called, they will return whatever value is given to them, but also
 set up the experiment so that it can be found and edited using the associated editing UI.
 You can repeat these same invocations later to read the value again, and values will then be returned
 including any edits made via the UI.

 ## Static API
 
 This type can be used in two ways. The first is to call the static version of its `value(…)` methods.
 These methods are limited to the main actor, but allow for implicit observation of changes and
 are by far the simplest entry point. These are:
 - ``value(_:key:in:)-9of4y`` (to adjust floating-point values);
 - ``value(_:key:in:)-mqgn`` (to adjust integer values);
 - ``value(_:key:)-swift.type.method`` (to adjust strings).
 
 As an example for the static API, let's turn the following value into an adjustable experiment:
 
 ```swift
 let number = 42
 ```
 
 This can become an experiment by wrapping the value in a call to a static ``value(_:key:in:)-mqgn``
 method, and, for numbers, specifying a range of valid values:
 
 ```swift
 let number = Experiments.value(42,
    key: MyExperiments.number,
    in: 0...100)
 ```
 
 This will have no immediate effect, but should let your experiment appear in the editing UI.
 If you invoke this in a context that observes changes, like a SwiftUI view's `body`, you will
 also get appropriate updates when the editor changes your value, and executing this again
 will return the edited value rather than your default.
 
 For each experiment, you will need to specify a _key_ to uniquely identify and label it in the UI.
 
 Any `Hashable` and `Sendable` type will do for the key; you can use the ``ExperimentKey`` alias to
 quickly define one as an enumeration, but you can also just pass in a string or another
 existing type. Using a custom type lets editing UIs group experiments by the type of their key, which
 helps you find related experiments quickly.
 
 A sample definition for the key above may be:
 
 ```swift
 enum MyExperiments: ExperimentKey {
    case number
 }
 ```
 
 That is all that it takes. Setting up an experiment this way requires very few changes or bookkeeping
 and can let you edit and experiment very quickly.
 
 ## Instance API
 
 The static API is bound to the main actor. If you need to access and define experiments off of the main
 actor, or want more control on the editing or display of a set of experiments, you will need to create
 instances of this type and use their `value(…)` methods:
 - ``value(_:key:in:)-41f0i`` (floating-point values);
 - ``value(_:key:in:)-5zzrl`` (integer values);
 - ``value(_:key:)-swift.method`` (strings).
 
 Each instance is bound to one instance of ``Storage``, which is the thread-safe container
 for experiment data and the source of observation callbacks. The storage accessible as the
 ``Storage/default`` instance is recommended for use, but you can group and abandon
 experiments by making your own storage instance, if needed.
 
 To read the contents of the storage, create instances of this type. Each instance contains
 a snapshot of the storage's contents at time of creation. Its instance methods will return those
 snapshot values, but will also define experiments on the associated storage when invoked
 for the first time with a new key, like their static counterparts do.
 
 For example, to read the shared storage, you can create an instance like so:
 
 ```swift
 let snapshot = Experiments()
 let number = snapshot.value(42,
  key: MyExperiments.number,
  in: 0...100)
 ```
 
 The first time this code runs, it will return the default value, 42, and add the experiment to
 the storage, so that editor UI can display and modify it. That instance will, however, continue
 returning 42, even if the value is edited in the meantime. When you are ready to accept edits,
 create a new instance again to snapshot the new values; that instance's `value(…)`
 invocations will then include those new edits.
 
 If you want to separate some of your experiments into their own storage, create it manually:
 
 ```swift
 let store = Experiments.Storage()
 ```
 
 You can then read snapshots of that store specifically:
 
 ```swift
 let snapshot = Experiments(store)
 ```
 
 Snapshots are immutable and do not set up any sort of observation. If you use snapshots,
 you will need to observe the storage separately. You can use ``Storage/addObserver(_:)-6yxtc``
 to get callbacks from the storage directly, or use ``Storage/Observable`` to
 get [Observation](https://developer.apple.com/documentation/observation) callbacks (for example, to integrate with the change cycle in SwiftUI).
 
 */
public struct Experiments: Sendable {
    let valuesWithRawKeys: [AnyExperimentStorable: AnyExperimentStorable]
    let store: Experiments.Storage
    
    /// Creates a snapshot of the given storage.
    ///
    /// The snapshot will be immutable and always return values that were set
    /// on the storage at creation time, but invocations of its `value(…)` methods will
    /// set up experiments with the specified store as a side effect.
    public init(_ store: Experiments.Storage = .default) {
        self.store = store
        self.valuesWithRawKeys = store.raw.valuesWithRawKeys
    }
    
    /// Defines a floating-point experiment for the specified key, and
    /// returns its current value.
    public func value<D: BinaryFloatingPoint & Sendable>(_ value: D, key: some ExperimentKey, in range: ClosedRange<D>) -> D {
        store.raw[experimentFor: key] = .init(experiment: .floatingPointRange(AnyClosedFloatingPointRange(range)), defaultValue: .init(value))
        return valuesWithRawKeys[AnyExperimentStorable(key)]?.base as? D ?? value
    }
    
    /// Defines an integer experiment for the specified key, and
    /// returns its current value.
    public func value<D: BinaryInteger & Sendable>(_ value: D, key: some ExperimentKey, in range: ClosedRange<D>) -> D {
        store.raw[experimentFor: key] = .init(experiment: .integerRange(AnyClosedIntegerRange(range)), defaultValue: .init(value))
        return valuesWithRawKeys[AnyExperimentStorable(key)]?.base as? D ?? value
    }
    
    /// Defines a string experiment for the specified key, and
    /// returns its current value.
    public func value(_ value: String, key: some ExperimentKey) -> String {
        store.raw[experimentFor: key] = .init(experiment: .string, defaultValue: .init(value))
        return valuesWithRawKeys[AnyExperimentStorable(key)]?.base as? String ?? value
    }
}
