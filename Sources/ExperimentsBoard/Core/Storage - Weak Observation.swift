
/// A protocol for receiving callbacks when a ``Experiments/Storage`` instance's state changes, which automatically unregisters the observer when it is deallocated.
///
/// Observers that conform to this protocol are registered with ``Experiments/Storage/addObserver(_:)-ngjv``, and will automatically be removed if the instance is deallocated.
///
/// > Note: To have a storage strongly reference an observer, use the ``ExperimentsObserver`` protocol instead.
public protocol WeakExperimentsObserver: ExperimentsObserver, AnyObject {}

protocol _WeakExperimentsObserverBox {
    func get() -> (any ExperimentsObserver)?
}

final class WeakObserverBox<Actual: WeakExperimentsObserver>: _WeakExperimentsObserverBox {
    weak var actualObserver: Actual?
    
    func get() -> (any ExperimentsObserver)? {
        actualObserver
    }
    
    init(actualObserver: Actual) {
        self.actualObserver = actualObserver
    }
}
