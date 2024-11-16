
/**
 A property wrapper that can be used to quickly switch turn a variable into an experiment.
 
 Using this property wrapper is equivalent to calling the static methods of the ``Experiments`` type, but it will update
 a variable that you can refer to multiple times in code, or use as part of the declaration of a view.
 
 Like the corresponding static methods, this wrapper's value is isolated to the main actor.
 
 To use, declare a variable and specify the key in the annotation. The value you use to initialize the variable
 will be the default value of the experiment. For example:
 
 ```swift
 @Experimentable(MyExperiments.title)
 var title = "Hello!"
 ```
 
 Numeric values require a valid range, passed as the `in` argument of the annotation.
 
 ```swift
 @Experimentable(MyExperiments.width, in: 50...900)
 var width = 200.0
 ```
 
 You can also specify a custom ``Experiments/Storage/Observable`` to use a different store
 than the ``Experiments/Storage/default`` instance.
 
 ```swift
 @Experimentable(MyExperiments.title, observing: myExperiments)
 var title = "Hello!"
 ```
 
 ## Platform Support
 
 This type is available on all platforms. On platforms that support the [Observation](https://developer.apple.com/documentation/observation) module, using this type will cause changes to be tracked. This will update SwiftUI `View`s that use this variable in their `body`, for example.
 
 Tracking a store other than the default one with this type requires a platform that supports the Observation module.
 
 */
@propertyWrapper
@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
public struct Experimentable<Value> {
    let _accessor: @MainActor () -> Value
    
    /// Returns the current value of this experiment.
    @MainActor
    public var wrappedValue: Value {
        _accessor()
    }
    
    /// Defines a variable that takes the value from a string experiment in the default storage.
    ///
    /// This initializer is invoked when you define a variable like this:
    ///
    /// ```swift
    /// @Experimented(MyExperiments.title)
    /// var title = "Default Title"
    /// ```
    public init(wrappedValue: Value, _ key: some ExperimentKey) where Value == String {
        _accessor = {
            Experiments.observable.value(wrappedValue, key: key)
        }
    }
    
#if canImport(Observation) && !EXPERIMENT_BOARD_DO_NOT_USE_OBSERVATION
    /// Defines a variable that takes the value from a string experiment in the storage observed by the specified ``Experiments/Storage/Observable``.
    ///
    /// This initializer is invoked when you define a variable like this:
    ///
    /// ```swift
    /// @Experimented(MyExperiments.title, observing: observable)
    /// var title = "Default Title"
    /// ```
    public init(wrappedValue: Value, _ key: some ExperimentKey, observing observable: Experiments.Storage.Observable) where Value == String {
        _accessor = {
            observable.snapshot.value(wrappedValue, key: key)
        }
    }
#endif
    
    /// Defines a variable that takes the value from an integer experiment in the default storage.
    ///
    /// This initializer is invoked when you define a variable like this:
    ///
    /// ```swift
    /// @Experimented(MyExperiments.iterations, in: 50...1000)
    /// var iterations = 200
    /// ```
    public init(wrappedValue: Value, _ key: some ExperimentKey, in range: ClosedRange<Value>) where Value: BinaryFloatingPoint & Sendable {
        _accessor = {
            Experiments.observable.value(wrappedValue, key: key, in: range)
        }
    }
    
#if canImport(Observation) && !EXPERIMENT_BOARD_DO_NOT_USE_OBSERVATION
    /// Defines a variable that takes the value from an integer experiment in the storage observed by the specified ``Experiments/Storage/Observable``.
    ///
    /// This initializer is invoked when you define a variable like this:
    ///
    /// ```swift
    /// @Experimented(MyExperiments.iterations, in: 50...1000,
    ///     observing: observable)
    /// var iterations = 200
    /// ```
    public init(wrappedValue: Value, _ key: some ExperimentKey, in range: ClosedRange<Value>, observing observable: Experiments.Storage.Observable)  where Value: BinaryFloatingPoint & Sendable {
        _accessor = {
            observable.snapshot.value(wrappedValue, key: key, in: range)
        }
    }
#endif
    
    /// Defines a variable that takes the value from a floating-point value experiment in the default storage.
    ///
    /// This initializer is invoked when you define a variable like this:
    ///
    /// ```swift
    /// @Experimented(MyExperiments.precision, in: 0.0...1.0)
    /// var precision = 0.8
    /// ```
    public init(wrappedValue: Value, _ key: some ExperimentKey, in range: ClosedRange<Value>) where Value: BinaryInteger & Sendable {
        _accessor = {
            Experiments.observable.value(wrappedValue, key: key, in: range)
        }
    }
    
#if canImport(Observation) && !EXPERIMENT_BOARD_DO_NOT_USE_OBSERVATION
    /// Defines a variable that takes the value from a floating-point value experiment in the storage observed by the specified ``Experiments/Storage/Observable``.
    ///
    /// This initializer is invoked when you define a variable like this:
    ///
    /// ```swift
    /// @Experimented(MyExperiments.precision, in: 0.0...1.0,
    ///     observing: observable)
    /// var precision = 0.8
    /// ```
    public init(wrappedValue: Value, _ key: some ExperimentKey, in range: ClosedRange<Value>, observing observable: Experiments.Storage.Observable) where Value: BinaryInteger & Sendable {
        _accessor = {
            observable.snapshot.value(wrappedValue, key: key, in: range)
        }
    }
#endif
}
