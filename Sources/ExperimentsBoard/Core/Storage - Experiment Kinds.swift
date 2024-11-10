
/**
 Determines the type and options of an experiment, as provided by the call to ``Experiments`` that created it.
 */
public enum ExperimentKind: Sendable, Hashable {
    /// Indicates an experiment that varies a floating-point value in the specified range.
    case floatingPointRange(AnyClosedFloatingPointRange)
    
    /// Indicates an experiment that varies an integer value in the specified range.
    case integerRange(AnyClosedIntegerRange)
    
    /// Indicates an experiment that varies a string.
    case string
    
    /// Indicates an experiment that varies an integer value in the specified range.
    ///
    /// This constructor will wrap the indicated range in a type-erasing ``AnyClosedIntegerRange`` wrapper.
    public static func integerRange<I: BinaryInteger & Sendable>(_ range: ClosedRange<I>) -> Self {
        .integerRange(AnyClosedIntegerRange(range))
    }
    
    /// Indicates an experiment that varies a floating-point value in the specified range.
    ///
    /// This constructor will wrap the indicated range in a type-erasing ``AnyClosedFloatingPointRange`` wrapper.
    public static func floatingPointRange<F: BinaryFloatingPoint & Sendable>(_ range: ClosedRange<F>) -> Self {
        .floatingPointRange(AnyClosedFloatingPointRange(range))
    }
}

/// A type-erased version of a `ClosedRange` over a floating-point type.
public struct AnyClosedFloatingPointRange: Sendable, Hashable {
    public static func == (lhs: AnyClosedFloatingPointRange, rhs: AnyClosedFloatingPointRange) -> Bool {
        lhs.core == rhs.core
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(core)
    }
    
    /// The type-erased value itself.
    public let core: AnyExperimentStorable
    /// The type of the range, captured at creation time.
    public let type: Any.Type
    
    /// Creates a type-erased version of the specified range.
    public init<X: BinaryFloatingPoint & Sendable>(_ range: ClosedRange<X>) {
        self.core = AnyExperimentStorable(range)
        self.type = X.self
    }
}

/// A type-erased version of a `ClosedRange` over an integer type.
public struct AnyClosedIntegerRange: Sendable, Hashable {
    public static func == (lhs: AnyClosedIntegerRange, rhs: AnyClosedIntegerRange) -> Bool {
        lhs.core == rhs.core
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(core)
    }
    
    /// The type-erased value itself.
    public let core: AnyExperimentStorable
    /// The type of the range, captured at creation time.
    public let type: Any.Type
    
    /// Creates a type-erased version of the specified range.
    public init<X: BinaryInteger & Sendable>(_ range: ClosedRange<X>) {
        self.core = AnyExperimentStorable(range)
        self.type = X.Type.self
    }
}

extension ClosedRange {
    /// Unwraps a type-erased range into a fully known `ClosedRange`.
    ///
    /// If the type of the `Bound` of the wrapped range does not correspond to what you indicated at construction time, returns `nil`.
    public init?(_ range: AnyClosedFloatingPointRange) where Bound: BinaryFloatingPoint {
        if let core = AnyHashable(range.core) as? Self {
            self = core
        } else {
            return nil
        }
    }
    
    /// Unwraps a type-erased range into a fully known `ClosedRange`.
    ///
    /// If the type of the `Bound` of the wrapped range does not correspond to what you indicated at construction time, returns `nil`.
    public init?(_ range: AnyClosedIntegerRange) where Bound: BinaryInteger {
        if let core = AnyHashable(range.core) as? Self {
            self = core
        } else {
            return nil
        }
    }
}
