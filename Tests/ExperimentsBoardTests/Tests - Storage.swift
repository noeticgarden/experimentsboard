
import Testing
@testable import ExperimentsBoard

extension Experiments {
    var values: [AnyHashable: any Sendable & Hashable] {
        Dictionary(uniqueKeysWithValues: valuesWithRawKeys.map {
            (AnyHashable($0), $1.base)
        })
    }
}

@Suite
struct ExperimentsStorageTests {
    @Test func settingGetting() {
        let store = Experiments.Storage()
        store.raw[raw: "Wow"] = .init(42)
        #expect(store.raw["Wow"] as? Int == 42)
    }
    
    final actor TestObserver: ExperimentsObserver {
        var experimentValuesDidChangeWasCalled = false
        nonisolated func experimentValuesDidChange() {
            Task {
                await set()
            }
        }
        
        var trueAwaiters: [CheckedContinuation<Void, Never>] = []
        var falseAwaiters: [CheckedContinuation<Void, Never>] = []
        func expect(_ value: Bool) async {
            guard experimentValuesDidChangeWasCalled != value else {
                return
            }
            
            await withCheckedContinuation { continuation in
                if value {
                    trueAwaiters.append(continuation)
                } else {
                    falseAwaiters.append(continuation)
                }
            }
        }
        
        func set() {
            experimentValuesDidChangeWasCalled = true
            let awaiters = self.trueAwaiters
            self.trueAwaiters = []
            for awaiter in awaiters {
                awaiter.resume()
            }
        }
        func reset() {
            experimentValuesDidChangeWasCalled = false
            let awaiters = self.falseAwaiters
            self.trueAwaiters = []
            for awaiter in awaiters {
                awaiter.resume()
            }
        }
    }
    
    @Test(.timeLimit(.minutes(1)))
    @available(macOS 13, *)
    @available(iOS 16, *)
    @available(tvOS 16, *)
    @available(watchOS 9, *)
    @available(visionOS 1, *)
    func observing() async {
        let test = TestObserver()
        let store = Experiments.Storage()
        store.addObserver(test)
        await test.expect(false)
        
        store.raw.set(42, for: "Wow")
        await test.expect(true)
    }
    
    @Test(.timeLimit(.minutes(1)))
    @available(macOS 13, *)
    @available(iOS 16, *)
    @available(tvOS 16, *)
    @available(watchOS 9, *)
    @available(visionOS 1, *)
    func endObserving() async {
        let test = TestObserver()
        let store = Experiments.Storage()
        
        store.addObserver(test)
        await test.expect(false)
        store.raw.set(42, for: "Wow")
        await test.expect(true)
        
        await test.reset()
        store.removeObserver(test)
        store.raw.set(24, for: "Wow")
        await test.expect(false)
    }
    
    @Test func values() {
        let store = Experiments.Storage()
        #expect(store.raw.values as? [String: Int] == [:])
        store.raw.set(42, for: "Wow")
        #expect(store.raw.values as? [String: Int] == ["Wow": 42])
        store.raw.set(252525, for: "Nice")
        #expect(store.raw.values as? [String: Int] == ["Wow": 42, "Nice": 252525])
    }
}

@Suite
struct ExperimentsSnapshots {
    @Test func creating() {
        let store = Experiments.Storage()
        let a = Experiments(store)
        #expect(a.values["Test"] == nil)
        store.raw.set(42, for: "Test")
        #expect(a.values["Test"] == nil)
        
        let b = Experiments(store)
        #expect(b.values["Test"] as? Int == 42)
    }
    
    @Test func usingWithString() {
        let store = Experiments.Storage()
        let a = Experiments(store)
        #expect(store.raw[experimentFor: "Test"] == nil)
        #expect(a.value("Default Value", key: "Test") == "Default Value")
        #expect(store.raw[experimentFor: "Test"]?.experiment == .string)
        #expect(store.raw[experimentFor: "Test"]?.defaultValue.base as? String == "Default Value")
        
        store.raw.set("Wow", for: "Test")
        #expect(a.value("Default Value", key: "Test") == "Default Value")
        
        let b = Experiments(store)
        #expect(b.value("Default Value", key: "Test") == "Wow")
    }
    
    @Test func gettingAllExperiments() throws {
        let store = Experiments.Storage()
        let a = Experiments(store)
        #expect(store.raw[experimentFor: "Test"] == nil)
        #expect(a.value("Default Value", key: "Test") == "Default Value")
        #expect(store.raw[experimentFor: "Test"]?.experiment == .string)
        #expect(store.raw[experimentFor: "Test"]?.experiment == .string)
        
        let experiments = store.raw.experiments
        #expect(experiments.count == 1)
        let experiment = try #require(experiments["Test"])
        #expect(experiment.experiment == .string)
        #expect(experiment.defaultValue.base as? String == "Default Value")
    }
}
