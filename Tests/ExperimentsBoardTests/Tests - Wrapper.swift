
#if canImport(Observation)
import Testing
import Observation
@testable import ExperimentsBoard

@Suite
struct WrapperTests {
    @MainActor
    @available(macOS 14, *)
    @available(iOS 17, *)
    @available(tvOS 17, *)
    @available(watchOS 10, *)
    @available(visionOS 1, *)
    @Test(.timeLimit(.minutes(1))) func wrapperValueReadingString() async {
        let key = "Hello"
        let defaultValue = "Hi!"
        let newValue = "Nice!"
        
        let store = Experiments.Storage()
        let observable = Experiments.Observable(store)
        
        #expect(store.raw[experimentFor: key] == nil)
        
        @Experimentable(key, observing: observable)
        var nice = defaultValue
        
        #expect(store.raw[experimentFor: key] == nil)
        #expect(nice == defaultValue)
        #expect(store.raw[experimentFor: key] == .init(experiment: .string, defaultValue: defaultValue))
        
        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = nice
            } onChange: {
                continuation.resume()
            }

            store.raw.set(newValue, for: key)
        }

        #expect(nice == newValue)
    }
    
    @MainActor
    @available(macOS 14, *)
    @available(iOS 17, *)
    @available(tvOS 17, *)
    @available(watchOS 10, *)
    @available(visionOS 1, *)
    @Test(.timeLimit(.minutes(1))) func wrapperValueReadingInt() async {
        let key = "Hello"
        let defaultValue = 123
        let newValue = 456
        let range = 0...1000
        
        let store = Experiments.Storage()
        let observable = Experiments.Observable(store)
        
        #expect(store.raw[experimentFor: key] == nil)
        
        @Experimentable(key, in: range, observing: observable)
        var nice = defaultValue
        
        #expect(store.raw[experimentFor: key] == nil)
        #expect(nice == defaultValue)
        #expect(store.raw[experimentFor: key] == .init(experiment: .integerRange(range), defaultValue: defaultValue))
        
        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = nice
            } onChange: {
                continuation.resume()
            }

            store.raw.set(newValue, for: key)
        }

        #expect(nice == newValue)
    }
    
    @MainActor
    @available(macOS 14, *)
    @available(iOS 17, *)
    @available(tvOS 17, *)
    @available(watchOS 10, *)
    @available(visionOS 1, *)
    @Test(.timeLimit(.minutes(1))) func wrapperValueReadingDouble() async {
        let key = "Hello"
        let defaultValue = 123.0
        let newValue = 456.0
        let range = 0.0...1000.0
        
        let store = Experiments.Storage()
        let observable = Experiments.Observable(store)
        
        #expect(store.raw[experimentFor: key] == nil)
        
        @Experimentable(key, in: range, observing: observable)
        var nice = defaultValue
        
        #expect(store.raw[experimentFor: key] == nil)
        #expect(nice == defaultValue)
        #expect(store.raw[experimentFor: key] == .init(experiment: .floatingPointRange(range), defaultValue: defaultValue))
        
        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = nice
            } onChange: {
                continuation.resume()
            }

            store.raw.set(newValue, for: key)
        }

        #expect(nice == newValue)
    }
}

#endif
