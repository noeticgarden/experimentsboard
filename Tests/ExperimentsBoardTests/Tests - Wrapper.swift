
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
    
    @available(macOS 14, *)
    @available(iOS 17, *)
    @available(tvOS 17, *)
    @available(watchOS 10, *)
    @available(visionOS 1, *)
    actor IsolatedOtherwise {
        let store = Experiments.Storage()
        var observable: Experiments.Observable?
        
        private func observe() -> Experiments.Observable {
            if let observable {
                return observable
            } else {
                let observable = Experiments.Observable(store) { [weak self] in
                    await self?.refresh()
                }
                self.observable = observable
                return observable
            }
        }
        
        private func refresh() {
            observable?.refresh()
        }
        
        func wrapperValueReadingString() async {
            let key = "Hello"
            let defaultValue = "Hi!"
            let newValue = "Nice!"
            
            let observable = observe()
            
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
        
        func wrapperValueReadingInt() async {
            let key = "Hello"
            let defaultValue = 123
            let newValue = 456
            let range = 0...1000
            
            let observable = observe()
            
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
        
        func wrapperValueReadingDouble() async {
            let key = "Hello"
            let defaultValue = 123.0
            let newValue = 456.0
            let range = 0.0...1000.0
            
            let observable = observe()
            
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
    
    @available(macOS 14, *)
    @available(iOS 17, *)
    @available(tvOS 17, *)
    @available(watchOS 10, *)
    @available(visionOS 1, *)
    @Test(.timeLimit(.minutes(1))) func wrapperValueReadingStringInActor() async {
        let isolated = IsolatedOtherwise()
        await isolated.wrapperValueReadingString()
    }
    
    @available(macOS 14, *)
    @available(iOS 17, *)
    @available(tvOS 17, *)
    @available(watchOS 10, *)
    @available(visionOS 1, *)
    @Test(.timeLimit(.minutes(1))) func wrapperValueReadingIntInActor() async {
        let isolated = IsolatedOtherwise()
        await isolated.wrapperValueReadingInt()
    }
    
    @available(macOS 14, *)
    @available(iOS 17, *)
    @available(tvOS 17, *)
    @available(watchOS 10, *)
    @available(visionOS 1, *)
    @Test(.timeLimit(.minutes(1))) func wrapperValueReadingDoubleInActor() async {
        let isolated = IsolatedOtherwise()
        await isolated.wrapperValueReadingDouble()
    }
}

#endif
