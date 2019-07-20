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
    
    // memory size occupy by self object
    static func size() -> Int {
        return MemoryLayout<Self>.size
    }
    
    // align
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
    init<T>(pointer: UnsafePointer<T>) {
        func cast<T, U>(_ value: T) -> U {
            return unsafeBitCast(value, to: U.self);
        }
//        typealias PointT = T
        self = cast(UnsafePointer<T>(pointer));
    }
}

func == <T: GW_PointerType>(lhs: T, rhs: T) -> Bool {
    return lhs.pointerUn == rhs.pointerUn
}



// MARK: MetadataType
protocol GW_MetadataType : GW_PointerType {
//    var pointerUn: UnsafePointer<Int>{ get set }
    static var kind: Metadata.Kind? { get }
}

extension GW_MetadataType {
    var kind: Metadata.Kind{
        let pointerUn:UnsafePointer<Int>
            = self.pointerUn.withMemoryRebound(to: Int.self, capacity: 1, { a_pt_uint8 in
            return a_pt_uint8
        })
        return Metadata.Kind(flag: pointerUn.pointee)
    }
    init?(anyType: Any.Type) {
        self.init(pointer: unsafeBitCast(anyType, to: UnsafePointer<Int>.self))
        if let kind = type(of: self).kind, kind != self.kind {
            return nil;
        }
    }
}

// MARK: Metadata
struct Metadata : GW_MetadataType {
//    typealias pointT = Int;
    var pointerUn: UnsafePointer<Int>
    init(typeT: Any.Type) {
        self.init(pointer: unsafeBitCast(typeT, to: UnsafePointer<Int>.self))
    }
    
    
}

extension Metadata {
    static let kind: Kind? = nil
    
    enum Kind {
        case `struct`
        case `enum`
        case optional
        case opaque
        case tuple
        case function
        case existential
        case metatype
        case objCClassWrapper
        case existentialMetatype
        case foreignClass
        case heapLocalVariable
        case heapGenericLocalVariable
        case errorObject
        case `class`
        init(flag: Int) {
            switch flag {
            case 1: self = .struct
            case 2: self = .enum
            case 3: self = .optional
            case 8: self = .opaque
            case 9: self = .tuple
            case 10: self = .function
            case 12: self = .existential
            case 13: self = .metatype
            case 14: self = .objCClassWrapper
            case 15: self = .existentialMetatype
            case 16: self = .foreignClass
            case 64: self = .heapLocalVariable
            case 65: self = .heapGenericLocalVariable
            case 128: self = .errorObject
            default: self = .class
            }
        }
    }
}

// MARK: Metadata + Class
extension Metadata {
    struct Class : GW_ContextDescriptorType {
        
//        typealias pointT = _Metadata._Class;
        
        static let kind: Kind? = .class
        var pointerUn: UnsafePointer<_Metadata._Class>;
        
        var isSwiftClass: Bool {
            get {
                let lowbit = self.pointerUn.pointee.databits & 1
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
            guard let metaclass = Metadata.Class(anyType: superclass), metaclass.isSwiftClass else {
                return nil
            }
            
            return metaclass
        }
        
        func _propertyDescriptionsAndStartPoint() -> ([GW_Property.Description], Int32?)? {
            let instanceStart = pointerUn.pointee.class_rw_t()?.pointee.class_ro_t()?.pointee.instanceStart
            var result: [GW_Property.Description] = []
            let selfType = unsafeBitCast(self.pointerUn, to: Any.Type.self)
            if let offsets = self.fieldOffsets {
                class NameAndType {
                    var name: String?
                    var type: Any.Type?
                }
                for i in 0..<self.numberOfFields {
                    var nameAndType = NameAndType()
                    _getFieldAt(selfType, i, { (name, type, nameAndTypePtr) in
                        let name = String(cString: name)
                        let type = unsafeBitCast(type, to: Any.Type.self)
                        nameAndTypePtr.assumingMemoryBound(to: NameAndType.self).pointee.name = name
                        nameAndTypePtr.assumingMemoryBound(to: NameAndType.self).pointee.type = type
                    }, &nameAndType)
                    if let name = nameAndType.name, let type = nameAndType.type {
                        result.append(GW_Property.Description(key: name, type: type, offset: offsets[i]))
                    }
                }
            }
            
            if let superclass = superclass,
                String(describing: unsafeBitCast(superclass.pointerUn, to: Any.Type.self)) != "SwiftObject",  // ignore the root swift object
                let superclassProperties = superclass._propertyDescriptionsAndStartPoint(),
                superclassProperties.0.count > 0 {
                
                return (superclassProperties.0 + result, superclassProperties.1)
            }
            return (result, instanceStart)
        }
        
        func propertyDescriptions() -> [GW_Property.Description]? {
            let propsAndStp = _propertyDescriptionsAndStartPoint()
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
//        typealias pointT = _Metadata._Struct;
        static let kind: Kind? = .struct
        var pointerUn: UnsafePointer<_Metadata._Struct>
        var contextDescriptorOffsetLocation: Int {
            return 1
        }
        
        func propertyDescriptions() -> [GW_Property.Description]? {
            guard let fieldOffsets = self.fieldOffsets else {
                return []
            }
            var result: [GW_Property.Description] = []
            let selfType = unsafeBitCast(self.pointerUn, to: Any.Type.self)
            class NameAndType {
                var name: String?
                var type: Any.Type?
            }
            for i in 0..<self.numberOfFields {
                var nameAndType = NameAndType()
                _getFieldAt(selfType, i, { (name, type, nameAndTypePtr) in
                    let name = String(cString: name)
                    let type = unsafeBitCast(type, to: Any.Type.self)
                    let nameAndType = nameAndTypePtr.assumingMemoryBound(to: NameAndType.self).pointee
                    nameAndType.name = name
                    nameAndType.type = type
                }, &nameAndType)
                if let name = nameAndType.name, let type = nameAndType.type {
                    result.append(GW_Property.Description(key: name, type: type, offset: fieldOffsets[i]))
                }
            }
            return result
        }
    }
}

// MARK: Metadata + ObjcClassWrapper 类型
extension Metadata {
    struct ObjcClassWrapper: GW_ContextDescriptorType {
        
//        typealias pointT = _Metadata._ObjcClassWrapper;
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
        // other fields we don't care
        
        func class_rw_t() -> UnsafePointer<_class_rw_t>? {
            if MemoryLayout<Int>.size == MemoryLayout<Int64>.size {
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

protocol ContextDescriptorProtocol {
    var numberOfFields: Int { get }
    var fieldOffsetVector: Int { get }
}

protocol GW_ContextDescriptorType : GW_MetadataType {
    var contextDescriptorOffsetLocation: Int { get }
}

protocol _ContextDescriptorProtocol {
    var mangledName: Int32 { get }
    var numberOfFields: Int32 { get }
    var fieldOffsetVector: Int32 { get }
    var fieldTypesAccessor: Int32 { get }
}

struct ContextDescriptor<T: _ContextDescriptorProtocol>: ContextDescriptorProtocol, GW_PointerType {
    
    var pointerUn: UnsafePointer<T>
    
    var numberOfFields: Int {
        return Int(pointerUn.pointee.numberOfFields)
    }
    
    var fieldOffsetVector: Int {
        return Int(pointerUn.pointee.fieldOffsetVector)
    }
}

struct _StructContextDescriptor: _ContextDescriptorProtocol {
    var flags: Int32
    var parent: Int32
    var mangledName: Int32
    var fieldTypesAccessor: Int32
    var numberOfFields: Int32
    var fieldOffsetVector: Int32
}

struct _ClassContextDescriptor: _ContextDescriptorProtocol {
    var flags: Int32
    var parent: Int32
    var mangledName: Int32
    var fieldTypesAccessor: Int32
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
    
    var contextDescriptor: ContextDescriptorProtocol? {
        
        let pointer:UnsafePointer<Int> = pointerUn.withMemoryRebound(to: Int.self, capacity: 1, { a_pt_uint8 in
            return a_pt_uint8
        })
        let base = pointer.advanced(by: contextDescriptorOffsetLocation)
        if base.pointee == 0 {
            return nil
        }
        if self.kind == .class {
            return ContextDescriptor<_ClassContextDescriptor>(pointerUn: relativePointer(base: base, offset: base.pointee - Int(bitPattern: base)))
        } else {
            return ContextDescriptor<_StructContextDescriptor>(pointerUn: relativePointer(base: base, offset: base.pointee - Int(bitPattern: base)))
        }
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
                let pointerClass:UnsafePointer<Int> = pointerUn.withMemoryRebound(to: Int.self, capacity: 1, { a_pt_uint8 in
                    return a_pt_uint8
                })
                return pointerClass[vectorOffset + $0]
            }
        } else {
            return (0..<contextDescriptor.numberOfFields).map {
                let pointerStrc:UnsafePointer<Int32> = pointerUn.withMemoryRebound(to: Int32.self, capacity: 1, { a_pt_uint8 in
                    return a_pt_uint8
                })
                return Int(pointerStrc[vectorOffset * (is64BitPlatform ? 2 : 1) + $0])
            }
        }
    }
}

var is64BitPlatform: Bool {
    return MemoryLayout<Int>.size == MemoryLayout<Int64>.size
}

@_silgen_name("swift_getFieldAt")
func _getFieldAt(
    _ type: Any.Type,
    _ index: Int,
    _ callback: @convention(c) (UnsafePointer<CChar>, UnsafeRawPointer, UnsafeMutableRawPointer) -> Void,
    _ ctx: UnsafeMutableRawPointer
)
