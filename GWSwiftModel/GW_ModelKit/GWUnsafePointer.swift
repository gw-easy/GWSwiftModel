//
//  GWUnsafePointer.swift
//  GWSwiftModel
//
//  Created by zdwx on 2018/12/15.
//  Copyright © 2018 DoubleK. All rights reserved.
//

import Foundation

//typealias 替换名称
typealias GWTYPE = Int8;

//从swift源码copy来
enum GWFieldDescriptorKind : UInt16 {
    case Struct = 0
    case Class
    case Enum
    case MultiPayloadEnum
    case `Protocol`
    case ClassProtocol
    case ObjCProtocol
    case ObjCClass
}

//MARK: - UnsafePointer
extension UnsafePointer {
    init<T>(_ pointer: UnsafePointer<T>) {
        self = UnsafeRawPointer(pointer).assumingMemoryBound(to: Pointee.self)
    }
}

public protocol GW_Pointer{
    
}

extension GW_Pointer{
//    为了能够在实例方法中修改属性值，可以在方法定义前添加关键字mutating
    
//MARK: MemoryLayout
//    var size: Int { get } //  连续的内存占用量T，以字节为单位。
//    var stride: Int { get } // 存储在连续存储器或存储器中的一个实例的开始到下一个实例的开始的字节数
//    var alignment: Int { get } //默认内存对齐方式T，以字节为单位。

    //MARK: 结构体指针-分配内存空间
    mutating func GW_PointerOfStruct() -> UnsafeMutablePointer<GWTYPE>{
        return withUnsafeMutablePointer(to: &self){
            return UnsafeMutableRawPointer($0).bindMemory(to: GWTYPE.self, capacity: MemoryLayout<Self>.stride);
        }
    }
    
    //MARK: 类指针-分配内存空间
    mutating func GW_PointerOfClass() -> UnsafeMutablePointer<GWTYPE>{
        let cPointer = Unmanaged.passUnretained(self as AnyObject).toOpaque().bindMemory(to: GWTYPE.self, capacity: MemoryLayout<Self>.stride);
//        强转UnsafeMutablePointer<GWTYPE>
        return UnsafeMutablePointer<GWTYPE>(cPointer);
    }
    
    //MARK: 判断类型
    mutating func GW_MuPointerType()->UnsafeMutablePointer<GWTYPE>{
        if Self.self is AnyClass{
            return self.GW_PointerOfClass();
        }else{
            return self.GW_PointerOfStruct();
        }
        
    }
    
    func isNSObjectType() -> Bool {
        return (type(of: self) as? NSObject.Type) != nil
    }
    
    func getBridgedPropertyList() -> Set<String> {
        if let anyClass = type(of: self) as? AnyClass {
            return _getBridgedPropertyList(anyClass: anyClass)
        }
        return []
    }
    
    func _getBridgedPropertyList(anyClass: AnyClass) -> Set<String> {
        if !(anyClass is GW_ModelAndJson.Type) {
            return []
        }
        var propertyList = Set<String>()
        if let superClass = class_getSuperclass(anyClass), superClass != NSObject.self {
            propertyList = propertyList.union(_getBridgedPropertyList(anyClass: superClass))
        }
        let count = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        if let props = class_copyPropertyList(anyClass, count) {
            for i in 0 ..< count.pointee {
                let name = String(cString: property_getName(props.advanced(by: Int(i)).pointee))
                propertyList.insert(name)
            }
            free(props)
        }
        #if swift(>=4.1)
        count.deallocate()
        #else
        count.deallocate(capacity: 1)
        #endif
        return propertyList
    }
    
//    属性内存大小
    static func size() -> Int {
        return MemoryLayout<Self>.size
    }
    
//    属性对齐
    static func align() -> Int {
        return MemoryLayout<Self>.alignment
    }
    
    static func offsetToAlignment(value: Int, align: Int) -> Int {
        let m = value % align
        return m == 0 ? 0 : (align - m)
    }
}

protocol GW_PointerType:Equatable {
    associatedtype PointT
    var pointerUn: UnsafePointer<PointT> { get set }
}

extension GW_PointerType{
    init<T>(pointerUn: UnsafePointer<T>) {
        func cast<T, U>(_ value: T) -> U {
            return unsafeBitCast(value, to: U.self);
        }
        self = cast(UnsafePointer<PointT>(pointerUn));
    }
}

func == <T: GW_PointerType>(lhs: T, rhs: T) -> Bool {
    return lhs.pointerUn == rhs.pointerUn
}



struct GWFieldDescriptor: GW_PointerType {
    
    var pointerUn: UnsafePointer<GW_FieldDescriptor>
    
    var fieldRecordSize: Int {
        return Int(pointerUn.pointee.fieldRecordSize)
    }
    
    var numFields: Int {
        return Int(pointerUn.pointee.numFields)
    }
    
    var fieldRecords: [GWFieldRecord] {
        return (0..<numFields).map({ (i) -> GWFieldRecord in
            return GWFieldRecord(pointerUn: UnsafePointer<GW_FieldRecord>(pointerUn + 1) + i)
        })
    }
}

struct GW_FieldDescriptor {
    var nameOffset: Int32
    var superClassOffset: Int32
    var fieldDescriptorKind: GWFieldDescriptorKind
    var fieldRecordSize: Int16
    var numFields: Int32
}

struct GWFieldRecord: GW_PointerType {
    
    var pointerUn: UnsafePointer<GW_FieldRecord>
    
    var fieldRecordFlags: Int {
        return Int(pointerUn.pointee.fieldRecordFlags)
    }
    
    var mangledTypeName: UnsafePointer<UInt8>? {
        let address = Int(bitPattern: pointerUn) + 1 * 4
        let offset = Int(pointerUn.pointee.changeNameOffset)
        let cString = UnsafePointer<UInt8>(bitPattern: address + offset)
        return cString
    }
    
    var fieldName: String {
        let address = Int(bitPattern: pointerUn) + 2 * 4
        let offset = Int(pointerUn.pointee.fieldNameOffset)
        if let cString = UnsafePointer<UInt8>(bitPattern: address + offset) {
            return String(cString: cString)
        }
        return ""
    }
}

struct GW_FieldRecord {
    var fieldRecordFlags: Int32
    var changeNameOffset: Int32
    var fieldNameOffset: Int32
}

// MARK: MetadataType
protocol GW_MetadataType : GW_PointerType {
    static var kind: Metadata.Kind? { get }
}

extension GW_MetadataType {
    var kind: Metadata.Kind{
        let kP:Int = UnsafePointer<Int>(pointerUn).pointee
        return Metadata.Kind(flag: kP)
    }
    init?(anyType: Any.Type) {
        self.init(pointerUn: unsafeBitCast(anyType, to: UnsafePointer<Int>.self))
        if let kind = type(of: self).kind, kind != self.kind {
            return nil;
        }
    }
}

// MARK: Metadata
struct Metadata : GW_MetadataType {
    var pointerUn: UnsafePointer<Int>
    init(typeT: Any.Type) {
        self.init(pointerUn: unsafeBitCast(typeT, to: UnsafePointer<Int>.self))
    }
    
    
}

extension Metadata {
    static let kind: Kind? = nil
    
    enum Kind {
        case `struct`
        case `enum`
        case optional
        case opaque
        case foreignClass
        case tuple
        case function
        case existential
        case metatype
        case objCClassWrapper
        case existentialMetatype
        case heapLocalVariable
        case heapGenericLocalVariable
        case errorObject
        case `class` // The kind only valid for non-class metadata
        init(flag: Int) {
            print("flag = \(flag)")
            switch flag {
            case 1,512: self = .struct
            case 2,513: self = .enum
            case 3,514: self = .optional
            case 8,768: self = .opaque
            case 9,769: self = .tuple
            case 10,770: self = .function
            case 12,771: self = .existential
            case 13,772: self = .metatype
            case 14,773: self = .objCClassWrapper
            case 15,774: self = .existentialMetatype
            case 16,515: self = .foreignClass
            case 64,1024: self = .heapLocalVariable
            case 65,1280: self = .heapGenericLocalVariable
            case 128,1281: self = .errorObject
            default: self = .class
            }
        }
    }
}

// MARK: Metadata + Class
extension Metadata {
    struct Class : GW_ContextDescriptorType {
        
        static let kind: Kind? = .class
        var pointerUn: UnsafePointer<_Metadata._Class>;
        
        var isSwiftClass: Bool {
            get {
//                #if swift(>=5.0)
                let lowbit = self.pointerUn.pointee.databits & 3
//                #else
//                let lowbit = self.pointerUn.pointee.databits & 1
//                #endif
                return lowbit == 1
            }
        }
        
        var contextDescriptorOffsetLocation: Int {
            return is64BitPlatform ? 8 : 11
        }
        
        var superclass: Class? {
            guard let superclass = pointerUn.pointee.superclass else {
                return nil
            }
            
            // If the superclass doesn't conform to handyjson/handyjsonenum protocol,
            // we should ignore the properties inside
            if !(superclass is GW_ModelAndJson.Type) && !(superclass is Gw_JsonWithEnum.Type) {
                return nil
            }
            
            // ignore objc-runtime layer
            guard let metaclass = Metadata.Class(anyType: superclass) else {
                return nil
            }
            
            return metaclass
        }
        
        var vTableSize: Int {
            // memory size after ivar destroyer
            return Int(pointerUn.pointee.classObjectSize - pointerUn.pointee.classObjectAddressPoint) - (contextDescriptorOffsetLocation + 2) * MemoryLayout<Int>.size
        }
        
        var genericArgumentVector: UnsafeRawPointer? {
            let pointer = UnsafePointer<Int>(self.pointerUn)
            var superVTableSize = 0
            if let _superclass = self.superclass {
                superVTableSize = _superclass.vTableSize / MemoryLayout<Int>.size
            }
            let base = pointer.advanced(by: contextDescriptorOffsetLocation + 2 + superVTableSize)
            if base.pointee == 0 {
                return nil
            }
            return UnsafeRawPointer(base)
        }
        
        func GW_propertyDescriptionsAndStartPoint() -> ([GW_Property.Description], Int32?)? {
            let instanceStart = pointerUn.pointee.class_rw_t()?.pointee.class_ro_t()?.pointee.instanceStart
            var result: [GW_Property.Description] = []
            if let offsets = self.fieldOffsets {
                class NameAndType {
                    var name: String?
                    var type: Any.Type?
                }
                for i in 0..<self.numberOfFields {
//                    #if swift(>=5.0)
                    if let name = self.reflectionFieldDescriptor?.fieldRecords[i].fieldName,
                        let cMangledTypeName = self.reflectionFieldDescriptor?.fieldRecords[i].mangledTypeName,
                        let fieldType = _getTypeByMangledNameInContext(cMangledTypeName, 256, genericContext: self.contextDescriptorPointer, genericArguments: self.genericArgumentVector)
                    {
                        result.append(GW_Property.Description(key: name, type: fieldType, offset: offsets[i]))
                    }
//                    #else
//                    let selfType = unsafeBitCast(self.pointerUn, to: Any.Type.self)
//                    var nameAndType = NameAndType()
//                    _getFieldAt(selfType, i, { (name, type, nameAndTypePtr) in
//                        let name = String(cString: name)
//                        let type = unsafeBitCast(type, to: Any.Type.self)
//                        nameAndTypePtr.assumingMemoryBound(to: NameAndType.self).pointee.name = name
//                        nameAndTypePtr.assumingMemoryBound(to: NameAndType.self).pointee.type = type
//                    }, &nameAndType)
//                    if let name = nameAndType.name, let type = nameAndType.type {
//                        result.append(GW_Property.Description(key: name, type: type, offset: offsets[i]))
//                    }
//                    #endif
                    
                }
            }
            
            if let superclass = superclass,
                String(describing: unsafeBitCast(superclass.pointerUn, to: Any.Type.self)) != "SwiftObject",  
                let superclassProperties = superclass.GW_propertyDescriptionsAndStartPoint(),
                superclassProperties.0.count > 0 {
                
                return (superclassProperties.0 + result, superclassProperties.1)
            }
            return (result, instanceStart)
        }
        
        func propertyDescriptions() -> [GW_Property.Description]? {
            let propsAndStp = GW_propertyDescriptionsAndStartPoint()
            if let firstInstanceStart = propsAndStp?.1,
                let firstProperty = propsAndStp?.0.first?.offset {
                return propsAndStp?.0.map({ (propertyDesc) -> GW_Property.Description in
                    let offset = propertyDesc.offset - firstProperty + Int(firstInstanceStart)
                    return GW_Property.Description(key: propertyDesc.key, type: propertyDesc.type, offset: offset)
                })
            } else {
                return propsAndStp?.0
            }
        }
    }
}

// MARK: Metadata + Struct
extension Metadata {
    struct Struct : GW_ContextDescriptorType {
        static let kind: Kind? = .struct
        var pointerUn: UnsafePointer<_Metadata._Struct>
        var contextDescriptorOffsetLocation: Int {
            return 1
        }
        
        var genericArgumentOffsetLocation: Int {
            return 2
        }
        
        var genericArgumentVector: UnsafeRawPointer? {
            
            let pointer = UnsafePointer<Int>(self.pointerUn)
            let base = pointer.advanced(by: genericArgumentOffsetLocation)
            if base.pointee == 0 {
                return nil
            }
            return UnsafeRawPointer(base)
        }
        
        func propertyDescriptions() -> [GW_Property.Description]? {
            guard let fieldOffsets = self.fieldOffsets else {
                return []
            }
            var result: [GW_Property.Description] = []
            class NameAndType {
                var name: String?
                var type: Any.Type?
            }
            for i in 0..<self.numberOfFields {
//                #if swift(>=5.0)
                if let name = self.reflectionFieldDescriptor?.fieldRecords[i].fieldName,
                    let cMangledTypeName = self.reflectionFieldDescriptor?.fieldRecords[i].mangledTypeName,
                    let fieldType = _getTypeByMangledNameInContext(cMangledTypeName, 256, genericContext: self.contextDescriptorPointer, genericArguments: self.genericArgumentVector){
                    result.append(GW_Property.Description(key: name, type: fieldType, offset: fieldOffsets[i]))
                }
//                #else
//                let selfType = unsafeBitCast(self.pointerUn, to: Any.Type.self)
//                var nameAndType = NameAndType()
//                _getFieldAt(selfType, i, { (name, type, nameAndTypePtr) in
//                    let name = String(cString: name)
//                    let type = unsafeBitCast(type, to: Any.Type.self)
//                    let nameAndType = nameAndTypePtr.assumingMemoryBound(to: NameAndType.self).pointee
//                    nameAndType.name = name
//                    nameAndType.type = type
//                }, &nameAndType)
//                if let name = nameAndType.name, let type = nameAndType.type {
//                    result.append(GW_Property.Description(key: name, type: type, offset: fieldOffsets[i]))
//                }
//                #endif
            }
            return result
        }
    }
}



// MARK: Metadata + ObjcClassWrapper 类型
extension Metadata {
    struct ObjcClassWrapper: GW_ContextDescriptorType {
        
        static let kind: Kind? = .objCClassWrapper
        var pointerUn: UnsafePointer<_Metadata._ObjcClassWrapper>
        var contextDescriptorOffsetLocation: Int {
            return is64BitPlatform ? 8 : 11
        }
        
        var targetType: Any.Type? {
            get {
                return pointerUn.pointee.targetType
            }
        }
    }
}

struct _class_rw_t {
    var flags: Int32
    var version: Int32
    var ro: UInt
    // other fields we don't care
    
    func class_ro_t() -> UnsafePointer<_class_ro_t>? {
        return UnsafePointer<_class_ro_t>(bitPattern: self.ro)
    }
}

struct _class_ro_t {
    var flags: Int32
    var instanceStart: Int32
    var instanceSize: Int32
    // other fields we don't care
}

struct _Metadata {}

extension _Metadata {
    struct _Class {
        var kind: Int
        var superclass: Any.Type?
        var reserveword1: Int
        var reserveword2: Int
        var databits: UInt
        var rodataPointer: UInt
        var classFlags: UInt32
        var instanceAddressPoint: UInt32
        var instanceSize: UInt32
        var instanceAlignmentMask: UInt16
        var runtimeReservedField: UInt16
        var classObjectSize: UInt32
        var classObjectAddressPoint: UInt32
        var nominalTypeDescriptor: Int
        var ivarDestroyer: Int
        func class_rw_t() -> UnsafePointer<_class_rw_t>? {
            if is64BitPlatform {
                let fast_data_mask: UInt64 = 0x00007ffffffffff8
                let databits_t: UInt64 = UInt64(self.databits)
                return UnsafePointer<_class_rw_t>(bitPattern: UInt(databits_t & fast_data_mask))
            } else {
                return UnsafePointer<_class_rw_t>(bitPattern: self.databits & 0xfffffffc)
            }
        }
    }
}

extension _Metadata {
    struct _Struct {
        var kind: Int
        var contextDescriptorOffset: Int
        var parent: Metadata?
    }
}

extension _Metadata {
    struct _ObjcClassWrapper {
        var kind: Int
        var targetType: Any.Type?
    }
}

protocol GWContextDescriptorProtocol {
    var numberOfFields: Int { get }
    var fieldOffsetVector: Int { get }
//    #if swift(>=5.0)
    var reflectionFieldDescriptor: Int { get }
//    #endif
}

protocol GW_ContextDescriptorType : GW_MetadataType {
    var contextDescriptorOffsetLocation: Int { get }
}

protocol GW_ContextDescriptorProtocol {
//    属性数量 - 必须
    var numberOfFields: Int32 { get }
//    属性偏移量 - 必须
    var fieldOffsetVector: Int32 { get }
//    反射属性描述 - 5.0
//    #if swift(>=5.0)
    var reflectionFieldDescriptor: Int32 { get }
//    #endif
}

struct ContextDescriptor<T: GW_ContextDescriptorProtocol>: GWContextDescriptorProtocol, GW_PointerType {
    
    var pointerUn: UnsafePointer<T>
    
    var numberOfFields: Int {
        return Int(pointerUn.pointee.numberOfFields)
    }
    
    var fieldOffsetVector: Int {
        return Int(pointerUn.pointee.fieldOffsetVector)
    }
//    #if swift(>=5.0)
    var reflectionFieldDescriptor: Int {
    return Int(pointerUn.pointee.reflectionFieldDescriptor)
    }
//    #endif
    
}

//结构体顺序不能乱
struct GW_StructContextDescriptor: GW_ContextDescriptorProtocol {
    var flags: Int32
    var parent: Int32
    var changeName: Int32
    var fieldTypesAccessor: Int32
//    #if swift(>=5.0)
    var reflectionFieldDescriptor: Int32
//    #endif
    var numberOfFields: Int32
    var fieldOffsetVector: Int32
}

struct GW_ClassContextDescriptor: GW_ContextDescriptorProtocol {
    var flags: Int32
    var parent: Int32
    var changeName: Int32
    var fieldTypesAccessor: Int32
//    #if swift(>=5.0)
    var reflectionFieldDescriptor: Int32
//    #endif
    var superClsRef: Int32
    var reservedWord1: Int32
    var reservedWord2: Int32
    var numImmediateMembers: Int32
    var numberOfFields: Int32
    var fieldOffsetVector: Int32
}



func relativePointer<T, U, V>(base: UnsafePointer<T>, offset: U) -> UnsafePointer<V> where U : FixedWidthInteger {
    return UnsafeRawPointer(base).advanced(by: Int(integer: offset)).assumingMemoryBound(to: V.self)
}

extension Int {
    fileprivate init<T : FixedWidthInteger>(integer: T) {
        switch integer {
        case let value as Int: self = value
        case let value as Int32: self = Int(value)
        case let value as Int16: self = Int(value)
        case let value as Int8: self = Int(value)
        default: self = 0
        }
    }
}


extension GW_ContextDescriptorType {
    
    var contextDescriptor: GWContextDescriptorProtocol? {
        
        let pointer = UnsafePointer<Int>(self.pointerUn)
        let base = pointer.advanced(by: contextDescriptorOffsetLocation)
        if base.pointee == 0 {
            return nil
        }
        if self.kind == .class {
            let res = ContextDescriptor<GW_ClassContextDescriptor>(pointerUn: relativePointer(base: base, offset: base.pointee - Int(bitPattern: base)))
            return res
        } else {
            return ContextDescriptor<GW_StructContextDescriptor>(pointerUn: relativePointer(base: base, offset: base.pointee - Int(bitPattern: base)))
        }
    }
    
    var contextDescriptorPointer: UnsafeRawPointer? {
        let pointerClass = UnsafePointer<Int>(self.pointerUn)
        let base = pointerClass.advanced(by: contextDescriptorOffsetLocation)
        if base.pointee == 0 {
            return nil
        }
        return UnsafeRawPointer(bitPattern: base.pointee)
    }
    
    var numberOfFields: Int {
        return contextDescriptor?.numberOfFields ?? 0
    }
    
    var fieldOffsets: [Int]? {
        guard let contextDescriptor = self.contextDescriptor else {
            return nil
        }
        let vectorOffset = contextDescriptor.fieldOffsetVector
        guard vectorOffset != 0 else {
            return nil
        }
        if self.kind == .class {
            return (0..<contextDescriptor.numberOfFields).map {
                let pointerClass = UnsafePointer<Int>(pointerUn)
                return pointerClass[vectorOffset + $0]
            }
        } else {
            return (0..<contextDescriptor.numberOfFields).map {
                let pointerStrc = UnsafePointer<Int32>(pointerUn)
                return Int(pointerStrc[vectorOffset * (is64BitPlatform ? 2 : 1) + $0])
            }
        }
    }
//    #if swift(>=5.0)
    var reflectionFieldDescriptor: GWFieldDescriptor? {
        guard let contextDescriptor = self.contextDescriptor else {
            return nil
        }
        let pointerClass = UnsafePointer<Int>(pointerUn)
        let base = pointerClass.advanced(by: contextDescriptorOffsetLocation)
        let offset = contextDescriptor.reflectionFieldDescriptor
        let address = base.pointee + 4 * 4
        guard let fieldDescriptorPtr = UnsafePointer<GW_FieldDescriptor>(bitPattern: address + offset) else {
            return nil
        }
        return GWFieldDescriptor(pointerUn: fieldDescriptorPtr)
    }
//    #endif
    
}

var is64BitPlatform: Bool {
    return MemoryLayout<Int>.size == MemoryLayout<Int64>.size
}


//@_silgen_name("swift_getTypeByMangledNameInContext")
//public func _getTypeByMangledNameInContext(
//    _ name: UnsafePointer<UInt8>,
//    _ nameLength: UInt,
//    genericContext: UnsafeRawPointer?,
//    genericArguments: UnsafeRawPointer?)
//    -> Any.Type?
//
//@_silgen_name("swift_getFieldAt")
//public func _getFieldAt(
//    _ type: Any.Type,
//    _ index: Int,
//    _ callback: @convention(c) (UnsafePointer<CChar>, UnsafeRawPointer, UnsafeMutableRawPointer) -> Void,
//    _ ctx: UnsafeMutableRawPointer
//)
