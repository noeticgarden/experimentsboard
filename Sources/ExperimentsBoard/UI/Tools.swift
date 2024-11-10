
struct ObjectIdentity<X: AnyObject>: Equatable, Hashable {
    static func == (lhs: ObjectIdentity<X>, rhs: ObjectIdentity<X>) -> Bool {
        lhs.object === rhs.object
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(object))
    }
    
    let object: X
    init(_ object: X) {
        self.object = object
    }
}
