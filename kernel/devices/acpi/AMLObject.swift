//
//  AMLObject.swift
//  project1
//
//  Created by Simon Evans on 05/01/2025.
//  Copyright © 2025 Simon Evans. All rights reserved.
//

final class AMLObject: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    private enum _Object {
        case uninitialised
        case integer(AMLInteger)
        case string(AMLString)
        case buffer(AMLBuffer)
        case package(AMLPackage)
        case fieldUnit(AMLNamedField)
        case device(AMLDefDevice)
        case event(AMLEvent)
        case method(AMLMethod)
        case mutex(AMLDefMutex)
        case operationRegion(AMLDefOpRegion)
        case powerResource(AMLDefPowerResource)
        case processor(AMLDefProcessor)
        case thermalZone(AMLThermalZone)
        case bufferField(AMLBufferField)
        case ddbHandle(AMLInteger)
        case debugObject(AMLString)
        //case objectReference(AMLObjectReference)
        case objectReference(AMLObject, AMLInteger?)
        case nameString(AMLNameString)      // Used for objectReference
        case dataRegion(AMLDataRegion)
    }

    static func ==(lhs: AMLObject, rhs: AMLObject) -> Bool {
        switch (lhs.object, rhs.object) {
            case (.integer(let lhsValue), .integer(let rhsValue)):
                return lhsValue == rhsValue
            case (.string(let lhsValue), .string(let rhsValue)):
                return lhsValue.data == rhsValue.data

            default:
                return false
        }
    }

    private var object: _Object

    init() {
        self.object = .uninitialised
    }

    init(_ integer: AMLInteger) {
        self.object = .integer(integer)
    }

    init(_ string: AMLString) {
        self.object = .string(string)
    }

    init(_ buffer: AMLBuffer) {
        self.object = .buffer(buffer)
    }

    init(_ package: AMLPackage) {
        self.object = .package(package)
    }


//    init(_ objectReference: AMLObjectReference) {
//        self.object = .objectReference(objectReference)
//    }
    init(_ object: AMLObject, index: AMLInteger? = nil) {
        self.object = .objectReference(object, index)
    }

    private init(_ object: _Object) {
        self.object = object
    }

    // Convert directly to a reference
    init(_ nameString: AMLNameString) {
        self.object = .objectReference(AMLObject(.nameString(nameString)), nil)
    }


    init(_ method: AMLMethod) {
        self.object = .method(method)
    }

    init(_ mutex: AMLDefMutex) {
        self.object = .mutex(mutex)
    }

    init(_ bufferField: AMLBufferField) {
        self.object = .bufferField(bufferField)
    }

    init(_ fieldUnit: AMLNamedField) {
        self.object = .fieldUnit(fieldUnit)
    }

    init (_ processor: AMLDefProcessor) {
        self.object = .processor(processor)
    }

    init(_ device: AMLDefDevice) {
        self.object = .device(device)
    }

    init(_ operationRegion: AMLDefOpRegion) {
        self.object = .operationRegion(operationRegion)
    }

    init(_ thermalZone: AMLThermalZone) {
        self.object = .thermalZone(thermalZone)
    }

    init(_ event: AMLEvent) {
        self.object = .event(event)
    }

    init(_ powerResource: AMLDefPowerResource) {
        self.object = .powerResource(powerResource)
    }

    init(_ dataRegion: AMLDataRegion) {
        self.object = .dataRegion(dataRegion)
    }

    var isUninitialised: Bool {
        if case .uninitialised = self.object { return true } else { return false }
    }

    var isInteger: Bool {
        if case .integer = self.object { return true } else { return false }
    }

    var isString: Bool {
        if case .string = self.object { return true } else { return false }
    }

    var isObjectReference: Bool {
        if case .objectReference = self.object { return true } else { return false }
    }

    var isDataRefObject: Bool {
        switch self.object {
            case .integer, .string, .package, .buffer, .objectReference: return true
            default: return false
        }
    }

    var integerValue: AMLInteger? {
        // FIXME, do any conversions
        switch self.object {
            case .integer(let integer):
                return integer
            default: return nil
        }
    }

    // Used for updating buffer elements
    var byteValue: UInt8? {
        // FIXME, do any conversions
        switch self.object {
            case .integer(let integer):
                return UInt8(truncatingIfNeeded: integer)
            case .buffer(let buffer):
                return buffer.first
            case .string(let string):
                return string.data.first
            default: return nil
        }
    }

    var stringValue: AMLString? {
        // FIXME, do any conversions
        switch self.object {
            case .string(let string):
                return string
            case .objectReference(let reference, _):
                // FIXME, this might not be the best thing
                if case .nameString(let nameString) = reference.object {
                    return AMLString(nameString)
                } else {
                    return nil
                }
            default: return nil
        }
    }

    var packageValue: AMLPackage? {
        // FIXME, do any conversions
        switch self.object {
            case .package(let package):
                return package
            default: return nil
        }
    }

    var bufferValue: AMLBuffer? {
        // FIXME, do any conversions
        // FIXME, should this return a AMLSharedBuffer or an AMLBuffer?
        switch self.object {
            case .buffer(let buffer):
                return buffer
            default: return nil
        }
    }

    var objectReferenceValue: (AMLObject, AMLInteger?)? {
        switch self.object {
            case .objectReference(let referencedObject, let index):
                return (referencedObject, index)
            default: return nil
        }
    }

    func asInteger() throws(AMLError) -> AMLInteger {
        switch self.object {
            case .integer(let integer): return integer
            case .string(let string):
                return try string.asAMLInteger()
            case .buffer(let buffer):
                return try buffer.asAMLInteger()
            default:
                throw AMLError.invalidDataConversion
        }
    }


    func asString() throws(AMLError) -> AMLString {
        switch self.object {
            case .integer(let integer): return AMLString(integer: integer, radix: 10)
            case .string(let string): return string
            case .buffer(let buffer): return buffer.asAMLString()
            default: return AMLString(asciiString: self.description)
        }
    }

    func asBuffer() throws(AMLError) -> AMLBuffer {
        switch self.object {
            case .integer(let integer): return AMLBuffer(integer: integer)
            case .string(let string): return string.asAMLBuffer()
            case .buffer(let buffer): return buffer
            default: throw AMLError.invalidData(reason: "Invalid type \(self.description)")
        }
    }

    func updateValue(to newValue: AMLObject) throws(AMLError) {
        // FIXME, do conversion
        self.object = newValue.object
    }

    func updateValue(at index: AMLInteger, to newValue: AMLObject) throws(AMLError) {
        switch object {
            case .package(let package):
                package[Int(index)] = newValue
            case .string(var string):
                string.data[Int(index)] = newValue.byteValue!
                self.object = .string(string)
            case .buffer(var buffer):
                buffer[Int(index)] = newValue.byteValue!
                self.object = .buffer(buffer)
            default: throw AMLError.invalidData(reason: "\(object) is not indexable")
        }
    }

    func updateReferencedValue(to newValue: AMLObject) throws(AMLError) {
        // FIXME, do something with index
        guard case .objectReference(let reference, _) = self.object else {
            throw AMLError.invalidData(reason: "Not a reference")
        }
        reference.object = newValue.object
    }

    func dereference() throws(AMLError) -> AMLObject {
        guard case .objectReference(let referencedObject, let index) = self.object else {
            throw AMLError.invalidData(reason: "Not a reference")
        }
        guard let index = index else {
            return referencedObject
        }

        switch referencedObject.object {
            case .string(let string):
                let byte = string.data[Int(index)]
                return AMLObject(AMLInteger(byte))
            case .buffer(let buffer):
                let byte = buffer[Int(index)]
                return AMLObject(AMLInteger(byte))
            case .package(let package):
                return package[Int(index)]
            default:
                throw AMLError.invalidData(reason: "Object of type (\referenceObject.object) cannot be indexed")
        }
    }

    var fieldUnitValue: AMLNamedField? {
        if case .fieldUnit(let namedField) = self.object {
            return namedField
        } else {
            return nil
        }
    }

    var methodValue: AMLMethod? {
        if case .method(let method) = self.object {
            return method
        } else {
            return nil
        }
    }

    var operationRegionValue: AMLDefOpRegion? {
        if case .operationRegion(let region) = object {
            return region
        } else {
            return nil
        }
    }

    var maxIndex: AMLInteger? {
        switch self.object {
            case .string(let string): return AMLInteger(string.data.count)
            case .buffer(let buffer): return AMLInteger(buffer.count)
            case .package(let package): return AMLInteger(package.count)
            default: return nil
        }
    }

    func sizeof() -> AMLInteger? {
        switch self.object {
            case .string(let string): return AMLInteger(string.data.count - 1)
            case .buffer(let buffer): return AMLInteger(buffer.count)
            case .package(let package): return AMLInteger(package.count)
            case .objectReference(let referencedObject, let index):
                switch referencedObject.object {
                    case .string(let string):
                        return index == nil ? AMLInteger(string.data.count) : 1
                    case .buffer(let buffer):
                        return index == nil ? AMLInteger(buffer.count) : 1
                    case .package(let package):
                        return index == nil ? AMLInteger(package.count) : package[Int(index!)].sizeof()
                    default:
                        return referencedObject.sizeof()
                }
            default: return nil
        }
    }

    var isDevice: Bool {
        switch self.object {
        case .device: return true
        default: return false
        }
    }

    var description: String {
        switch self.object {
            case .uninitialised:
                return "Uninitialised Object"
            case .integer:
                return "Integer"
            case .string:
                return "String"
            case .buffer:
                return "Buffer"
            case .package:
                return "Package"
            case .fieldUnit:
                return "Field"
            case .device:
                return "Device"
            case .event:
                return "Event"
            case .method:
                return "Control Method"
            case .mutex:
                return "Mutex"
            case .operationRegion:
                return "Operation Region"
            case .powerResource:
                return "Power Resource"
            case .processor:
                return "Processor"
            case .thermalZone:
                return "Thermal Zone"
            case .bufferField:
                return "Buffer Field"
            case .ddbHandle:
                return "DDB Handle"
            case .debugObject:
                return "Debug Object"
            case .objectReference:
                return "Object Reference"
            case .nameString:
                return "Namestring"
            case .dataRegion:
                return "Data Region"
        }
    }

    var debugDescription: String {
        switch self.object {
            case .integer(let integer):
                return "Integer(\(integer))"
            case .string(let string):
                return "String('\(string.asString())')"
            default:
                return self.description
        }
    }


    var objectType: AMLInteger {
        switch self.object {

            case .uninitialised:
                return 0
            case .integer:
                return 1
            case .string:
                return 2
            case .buffer:
                return 3
            case .package:
                return 4
            case .fieldUnit:
                return 5
            case .device:
                return 6
            case .event:
                return 7
            case .method:
                return 8
            case .mutex:
                return 9
            case .operationRegion:
                return 10
            case .powerResource:
                return 11
            case .processor:
                return 12
            case .thermalZone:
                return 13
            case .bufferField:
                return 14
            case .ddbHandle:
                return 15
            case .debugObject:
                return 16
            case .objectReference:
                return 32
            case .nameString:
                return 33
            case .dataRegion:
                return 34
        }
    }

    func readValue(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        switch self.object {
            case .uninitialised:
                throw AMLError.invalidData(reason: "Uninitialised Data")
            case .integer, .string, .buffer, .package:
                return self
            case .method(let method):
                return try method.readValue(context: &context)
            case .objectReference:
                return try self.dereference()
            case .fieldUnit(let fieldUnit):
                return try fieldUnit.readValue(context: &context)
            case .bufferField(let bufferField):
                return try bufferField.readValue(context: &context)

            default: throw AMLError.invalidData(reason: "Object is not a value")
        }
    }

    func updateValue(to newValue: AMLObject, context: inout ACPI.AMLExecutionContext) throws(AMLError) {
        switch self.object {
            case .uninitialised:
                throw AMLError.invalidData(reason: "Uninitialised Data")
            case .integer:
                self.object = .integer(newValue.integerValue!)
            case .string:
                self.object = .string(newValue.stringValue!)
            case .buffer:
                // FIXME: dont force unwrap
                self.object = .buffer(newValue.bufferValue!)
            case .package:
                self.object = .package(newValue.packageValue!)
            case .fieldUnit(let fieldUnit):
                try fieldUnit.updateValue(to: newValue, context: &context)
            case .bufferField(let bufferField):
                try bufferField.updateValue(to: newValue, context: &context)
            default:
                throw AMLError.unimplemented()
        }
    }
}
