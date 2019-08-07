//
//  GWModelProperty.swift
//  GWSwiftModel
//
//  Created by zdwx on 2018/12/15.
//  Copyright © 2018 DoubleK. All rights reserved.
//

import Foundation

//扩展类型
public protocol GW_AnyExtensions {
    
}

extension GW_AnyExtensions{
    public static func isValueTypeOrSubtype(_ value: Any) -> Bool {
        return value is Self
    }
    
    public static func value(from storage: UnsafeRawPointer) -> Any {
        return storage.assumingMemoryBound(to: self).pointee
    }
    
    public static func write(_ value: Any, to storage: UnsafeMutableRawPointer) {
        guard let wValue = value as? Self else {
            return
        }
        print("write + \(Self.self)")
        print("value + \(value)")
        print("storage + \(storage)")
        print("wValue + \(wValue)")
        let uPoint:UnsafeMutablePointer = storage.assumingMemoryBound(to: self)
        print("uPoint + \(uPoint)")
        uPoint.pointee = wValue
        print("pointee + \(uPoint.pointee)")
    }
    
    public static func takeValue(from anyValue: Any) -> Self? {
        return anyValue as? Self
    }
}

func extensions(of type: Any.Type) -> GW_AnyExtensions.Type {
    struct Extensions : GW_AnyExtensions {}
    var extensions: GW_AnyExtensions.Type = Extensions.self
    withUnsafePointer(to: &extensions) { pointer in
        UnsafeMutableRawPointer(mutating: pointer).assumingMemoryBound(to: Any.Type.self).pointee = type
    }
    return extensions
}

func extensions(of value: Any) -> GW_AnyExtensions {
    struct Extensions : GW_AnyExtensions {}
    var extensions: GW_AnyExtensions = Extensions()
    withUnsafePointer(to: &extensions) { pointer in
        UnsafeMutableRawPointer(mutating: pointer).assumingMemoryBound(to: Any.self).pointee = value
    }
    return extensions
}

//MARK: 属性详情
struct PropertyInfo {
    let key: String
    let type: Any.Type
    let address: UnsafeMutableRawPointer
    let bridged: Bool
}

//MARK: 属性结构体
struct GW_Property {
    let key: String
    let value: Any
    
    /// An instance property description
    struct Description {
        public let key: String
        public let type: Any.Type
        public let offset: Int
        public func write(_ value: Any, to storage: UnsafeMutableRawPointer) {
            return extensions(of: type).write(value, to: storage.advanced(by: offset))
        }
    }
}

/// Retrieve property descriptions for `type`
func getProperties(forType type: Any.Type) -> [GW_Property.Description]? {
    if let structDescriptor = Metadata.Struct(anyType: type) {
        return structDescriptor.propertyDescriptions()
    } else if let classDescriptor = Metadata.Class(anyType: type) {
        return classDescriptor.propertyDescriptions()
    } else if let objcClassDescriptor = Metadata.ObjcClassWrapper(anyType: type),
        let targetType = objcClassDescriptor.targetType {
        return getProperties(forType: targetType)
    }
    return nil
}
