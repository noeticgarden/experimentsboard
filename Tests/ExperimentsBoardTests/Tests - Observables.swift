
#if canImport(Observation)
import Testing
import Observation
@testable import ExperimentsBoard

@Suite
struct ObservablesTests {
    @MainActor
    @Test(.timeLimit(.minutes(1)))
    @available(macOS 14, *)
    @available(iOS 17, *)
    @available(tvOS 17, *)
    @available(watchOS 10, *)
    @available(visionOS 1, *)
    func testValuesObservable() async {
        let store = Experiments.Storage()
        let observable = Experiments.Storage.Observable(store)
        
        await withCheckedContinuation { continuation in
            withObservationTracking {
                let result = observable.snapshot.value("Default Value", key: "Test")
                #expect(result == "Default Value")
            } onChange: {
                continuation.resume()
            }
            
            store.raw[raw: "Test"] = .init("Wow")
        }
    }
    
    @MainActor
    @Test(.timeLimit(.minutes(1)))
    @available(macOS 14, *)
    @available(iOS 17, *)
    @available(tvOS 17, *)
    @available(watchOS 10, *)
    @available(visionOS 1, *)
    func testKindsObservable() async {
        let store = Experiments.Storage()
        
        let key = "Wow"
        let kind = ExperimentKind.integerRange(0...100)
        let value = 52
        store.raw.set(value, for: key)
        store.raw[experimentFor: key] = .init(experiment: kind, defaultValue: value)
        
        let observable = Experiments.Storage.Observable(store)
        
        await withCheckedContinuation { continuation in
            withObservationTracking {
                let states = observable.states
                #expect(states.count == 1)
                if let first = try? #require(states.first) {
                    #expect(first.experiment == kind)
                    #expect(first.value as? Int == value)
                }
            } onChange: {
                continuation.resume()
            }
            
            store.raw[experimentFor: key] = .init(experiment: .integerRange(0...200), defaultValue: value)
        }
    }
}
#endif
