
#if canImport(SwiftUI) && !EXPERIMENT_BOARD_DO_NOT_USE_SWIFTUI
import SwiftUI

extension String {
    fileprivate init(experimentLabelFor key: some ExperimentKey) {
        var result: any Hashable = key
        if let key = result as? AnyExperimentStorable {
            result = key.base
        }
        if let key = result as? AnyHashable,
           let base = key.base as? any Hashable {
            result = base
        }
        
        self = .init(describing: result)
    }
}

struct TypeBox: Equatable {
    let type: Any.Type
    init(_ type: Any.Type) {
        self.type = type
    }
    static func == (_ lhs: Self, rhs: Self) -> Bool {
        lhs.type == rhs.type
    }
}

@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
struct EditorRow: View {
    let experiment: Experiments.Storage.Observable.ExperimentState
    let get: (_ key: any ExperimentKey) -> any Sendable
    let set: (_ newValue: any Sendable & Hashable) -> Void
    
    var body: some View {
        switch experiment.experiment {
        case .floatingPointRange(let anyClosedFloatingPointRange):
            if let range = ClosedRange<Double>(anyClosedFloatingPointRange) {
                EditorRowForFloatingPoint(experiment: experiment, range: range, get: get, set: set)
            } else if let range = ClosedRange<Float>(anyClosedFloatingPointRange) {
                EditorRowForFloatingPoint(experiment: experiment, range: range, get: get, set: set)
            } else if let range = ClosedRange<Float32>(anyClosedFloatingPointRange) {
                EditorRowForFloatingPoint(experiment: experiment, range: range, get: get, set: set)
            } else if let range = ClosedRange<Float64>(anyClosedFloatingPointRange) {
                EditorRowForFloatingPoint(experiment: experiment, range: range, get: get, set: set)
            } else if let range = ClosedRange<CGFloat>(anyClosedFloatingPointRange) {
                EditorRowForFloatingPoint(experiment: experiment, range: range, get: get, set: set)
            }
        case .integerRange(let anyClosedIntegerRange):
            if let range = ClosedRange<Int>(anyClosedIntegerRange) {
                EditorRowForInteger(experiment: experiment, range: range, get: get, set: set)
            } else if let range = ClosedRange<Int8>(anyClosedIntegerRange) {
                EditorRowForInteger(experiment: experiment, range: range, get: get, set: set)
            } else if let range = ClosedRange<Int16>(anyClosedIntegerRange) {
                EditorRowForInteger(experiment: experiment, range: range, get: get, set: set)
            } else if let range = ClosedRange<Int32>(anyClosedIntegerRange) {
                EditorRowForInteger(experiment: experiment, range: range, get: get, set: set)
            } else if let range = ClosedRange<Int64>(anyClosedIntegerRange) {
                EditorRowForInteger(experiment: experiment, range: range, get: get, set: set)
            } else {
                EmptyView()
            }
        case .string:
            EditorRowForString(experiment: experiment, get: get, set: set)
        }
    }
}

// By experiment kind:

@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
fileprivate struct EditorRowForString: View {
    let experiment: Experiments.Storage.Observable.ExperimentState
    let get: (_ key: any ExperimentKey) -> any Sendable
    let set: (_ newValue: any Sendable & Hashable) -> Void
    
    @State var text = ""
    
    var body: some View {
        let textField = TextField(String(experimentLabelFor: experiment.key), text: $text, prompt: Text("Default value"))
            .multilineTextAlignment(.trailing)
#if !os(macOS)
            .textInputAutocapitalization(.never)
#endif
            .onAppear {
                self.text = experiment.value as? String ?? get(experiment.key) as? String ?? ""
            }
            .onChange(of: text) { oldValue, newValue in
                set(newValue)
            }
        
#if os(macOS)
        textField
#else
        LabeledContent(String(experimentLabelFor: experiment.key)) {
            textField
        }
#endif
    }
}

@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
fileprivate struct EditorRowForInteger<Integer: BinaryInteger & Sendable>: View {
    let experiment: Experiments.Storage.Observable.ExperimentState
    let range: ClosedRange<Integer>
    let get: (_ key: any ExperimentKey) -> any Sendable
    let set: (_ newValue: any Sendable & Hashable) -> Void
    
    @State var value = 0.0
    
    var body: some View {
        LabeledContent(String(experimentLabelFor: experiment.key)) {
#if os(tvOS)
            HStack {
                Text("\(Integer(value))")
                    .foregroundStyle(.primary)
                HStack(spacing: 8) {
                    Button {
                        value += 1.0
                    } label: {
                        Image(systemName: "plus")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                    .buttonBorderShape(.circle)
                    .disabled(Integer(value) + 1 > range.upperBound)
                    
                    Button {
                        value -= 1.0
                    } label: {
                        Image(systemName: "minus")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                    .buttonBorderShape(.circle)
                    .disabled(Integer(value) - 1 < range.lowerBound)
                }
                .buttonStyle(.bordered)
                .labelStyle(.iconOnly)
            }
#else
            Slider(
                value: $value,
                in: Double(range.lowerBound)...Double(range.upperBound),
                label: { Text("\(Integer(value))").monospacedDigit().frame(minWidth: 25) },
                minimumValueLabel: { Text("\(range.lowerBound)") },
                maximumValueLabel: { Text("\(range.upperBound)") }
            )
#endif
        }
        .onAppear {
            self.value = Double(experiment.value as? Integer ?? get(experiment.key) as? Integer ?? 0)
        }
        .onChange(of: value) { oldValue, newValue in
            set(Integer(newValue))
        }
    }
}

@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
fileprivate struct EditorRowForFloatingPoint<FloatingPoint: BinaryFloatingPoint & Sendable>: View {
    let experiment: Experiments.Storage.Observable.ExperimentState
    let range: ClosedRange<FloatingPoint>
    let get: (_ key: any ExperimentKey) -> any Sendable
    let set: (_ newValue: any Sendable & Hashable) -> Void
    
    @State var value = 0.0
    
    var valueLabel: String {
        value.formatted(.number.precision(.fractionLength(3)))
    }
    
    var body: some View {
        LabeledContent(String(experimentLabelFor: experiment.key)) {
#if os(tvOS)
            HStack {
                Text("\(FloatingPoint(value))")
                    .foregroundStyle(.primary)
                HStack(spacing: 8) {
                    Button {
                        value += 0.3
                    } label: {
                        Image(systemName: "plus")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                    .buttonBorderShape(.circle)
                    .disabled(FloatingPoint(value) + 0.3 > range.upperBound)
                    
                    Button {
                        value -= 0.3
                    } label: {
                        Image(systemName: "minus")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                    .buttonBorderShape(.circle)
                    .disabled(FloatingPoint(value) - 0.3 < range.lowerBound)
                }
                .buttonStyle(.bordered)
                .labelStyle(.iconOnly)
            }
#else
            Slider(
                value: $value,
                in: Double(range.lowerBound)...Double(range.upperBound),
                label: { Text(valueLabel).monospacedDigit().frame(minWidth: 65) },
                minimumValueLabel: { Text("\(range.lowerBound)") },
                maximumValueLabel: { Text("\(range.upperBound)") }
            )
#endif
        }
        .onAppear {
            self.value = Double(experiment.value as? FloatingPoint ?? get(experiment.key) as? FloatingPoint ?? 0)
        }
        .onChange(of: value) { oldValue, newValue in
            set(FloatingPoint(newValue))
        }
    }
}

// -----

#if compiler(>=6) // Ensure that previews are for Xcode 16 only.

@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
fileprivate struct _PreviewViewForString: View {
    @State var current: any Sendable = "Current"
    var body: some View {
        Form {
            EditorRow(experiment: .init(
                key: "testForString",
                experiment: .string,
                value: nil
            )) { _ in
                current
            } set: { (newValue) in
                current = newValue
                print("SET: \(newValue)")
            }
        }
    #if os(macOS)
        .formStyle(.grouped)
    #endif
    }
}

#Preview("Editor Row (String)") {
    if #available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *) {
        _PreviewViewForString()
    }
}

@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
fileprivate struct _PreviewViewForInteger<I: BinaryInteger & Sendable>: View {
    @State var current: any Sendable = I(12)
    
    var body: some View {
        Form {
            EditorRow(experiment: .init(
                key: "testFor\(I.self)",
                experiment: .integerRange(I(0)...I(100)),
                value: nil
            )) { _ in
                current
            } set: { (newValue) in
                current = newValue
                print("SET: \(newValue)")
            }
        }
#if os(macOS)
        .formStyle(.grouped)
#endif
    }
}

#Preview("Editor Row (Int)") {
    if #available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *) {
        _PreviewViewForInteger<Int>()
    }
}


#Preview("Editor Row (Int8)") {
    if #available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *) {
        _PreviewViewForInteger<Int8>()
    }
}

@available(macOS 14, *)
@available(iOS 17, *)
@available(tvOS 17, *)
@available(watchOS 10, *)
@available(visionOS 1, *)
fileprivate struct _PreviewViewForFloatingPoint<I: BinaryFloatingPoint & Sendable>: View {
    @State var current: any Sendable = I(12.0)
    
    var body: some View {
        Form {
            EditorRow(experiment: .init(
                key: "testFor\(I.self)",
                experiment: .floatingPointRange(I(0)...I(100)),
                value: nil
            )) { _ in
                current
            } set: { (newValue) in
                current = newValue
                print("SET: \(newValue)")
            }
        }
#if os(macOS)
        .formStyle(.grouped)
#endif
    }
}

#Preview("Editor Row (Double)") {
    if #available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *) {
        _PreviewViewForFloatingPoint<Double>()
    }
}

#Preview("Editor Row (Float)") {
    if #available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *) {
        _PreviewViewForFloatingPoint<Float>()
    }
}
#endif

#endif
