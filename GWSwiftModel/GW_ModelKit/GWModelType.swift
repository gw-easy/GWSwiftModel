//
//  GWModel.swift
//  GWSwiftModel
//
//  Created by zdwx on 2018/12/15.
//  Copyright © 2018 DoubleK. All rights reserved.
//

import Foundation


//GWJudgeModelType - 基协议
public protocol GWJudgeModelType:GW_Pointer{
//    static func judgeType(from object: Any) -> Self?
//    func someValue() -> Any?
}

extension GWJudgeModelType{

    static func judgeType(from object:Any)->Self?{
        if let sType = object as? Self {
            return sType;
        }
        switch self {
        case let type as GWCustomBasicType.Type:
            return type.strJudgeType(from: object) as? Self
        case let type as GWBridgeType.Type:
            return type.strJudgeType(from: object) as? Self
        case let type as GWEnumType.Type:
            return type.strJudgeType(from: object) as? Self
        case let type as GWExpendModelType.Type:
            return type.strJudgeType(from: object) as? Self
        default:
            return nil
        }
    }
    
    public func someValue() -> Any? {
        switch self {
        case let rawValue as GWCustomBasicType:
            return rawValue.strSomeValue();
        case let rawValue as GWBridgeType:
            return rawValue.strSomeValue();
        case let rawValue as GWEnumType:
            return rawValue.strSomeValue()
        case let rawValue as GWExpendModelType:
            return rawValue.strSomeValue()
        default:
            return nil
        }
    }
}

//MARK: GWCustomBasicType - 基础判断类型
protocol GWCustomBasicType:GWJudgeModelType{
    static func strJudgeType(from object: Any) -> Self?
    func strSomeValue() -> Any?
}

protocol GW_IntegerType: FixedWidthInteger, GWCustomBasicType {
    init?(_ text: String, radix: Int)
    init(_ number: NSNumber)
}

extension GW_IntegerType{
    static func strJudgeType(from object: Any) -> Self?{
        switch object {
        case let str as String:
            return Self(str, radix: 10)
        case let num as NSNumber:
            return Self(num)
        default:
            return nil
        }
    }
    func strSomeValue() -> Any? {
        return self
    }
}

extension Int: GW_IntegerType {}
extension UInt: GW_IntegerType {}
extension Int8: GW_IntegerType {}
extension Int16: GW_IntegerType {}
extension Int32: GW_IntegerType {}
extension Int64: GW_IntegerType {}
extension UInt8: GW_IntegerType {}
extension UInt16: GW_IntegerType {}
extension UInt32: GW_IntegerType {}
extension UInt64: GW_IntegerType {}

extension Bool:GWCustomBasicType{
    static func strJudgeType(from object: Any) -> Bool? {
        switch object {
        case let str as NSString:
            let lowerCase = str.lowercased;
            if ["0", "false"].contains(lowerCase) {
                return false;
            }
            if ["1", "true"].contains(lowerCase) {
                return true;
            }
            return nil;
        case let num as NSNumber:
            return num.boolValue;
        default:
            return nil;
        }
    }
    func strSomeValue() -> Any? {
        return self;
    }
}

protocol GW_FloatType: GWCustomBasicType, LosslessStringConvertible {
    init(_ number: NSNumber)
}

extension GW_FloatType {
    static func strJudgeType(from object: Any) -> Self? {
        switch object {
        case let str as String:
            return Self(str);
        case let num as NSNumber:
            return Self(num);
        default:
            return nil;
        }
    }
    func strSomeValue() -> Any? {
        return self;
    }
}

extension Float: GW_FloatType {}
extension Double: GW_FloatType {}

fileprivate let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.usesGroupingSeparator = false
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 16
    return formatter
}()

extension String:GWCustomBasicType{
    public static func strJudgeType(from object: Any) -> String? {
        switch object {
        case let str as String:
            return str
        case let num as NSNumber:
            // Boolean Type Inside
            if NSStringFromClass(type(of: num)) == "__NSCFBoolean" {
                if num.boolValue {
                    return "true"
                } else {
                    return "false"
                }
            }
            return formatter.string(from: num)
        case _ as NSNull:
            return nil
        default:
            return "\(object)"
        }
    }
    
    func strSomeValue() -> Any? {
        return self;
    }
}

extension Optional:GWCustomBasicType{
    static func strJudgeType(from object: Any) -> Optional<Wrapped>? {
        if let value = (Wrapped.self as? GWJudgeModelType.Type)?.judgeType(from: object) as? Wrapped {
            return Optional(value);
        } else if let value = object as? Wrapped {
            return Optional(value);
        }
        return nil;
    }
    
    func _getWrappedValue() -> Any? {
        return self.map( { (wrapped) -> Any in
            return wrapped as Any;
        })
    }
    
    func strSomeValue() -> Any? {
        if let value = _getWrappedValue() {
            if let transformable = value as? GWJudgeModelType {
                return transformable.someValue();
            } else {
                return value;
            }
        }
        return nil;
    }
}

//MARK: Collection
extension Collection{
    static func collectionJudgeType(from object: Any) -> [Iterator.Element]? {
        guard let arr = object as? [Any] else {
            print("不是array类型");
            return nil;
        }
        typealias Element = Iterator.Element;
        var result: [Element] = [Element]();
        arr.forEach { (each) in
            if let element = (Element.self as? GWJudgeModelType.Type)?.judgeType(from: each) as? Element {
                result.append(element);
            } else if let element = each as? Element {
                result.append(element);
            }
        }
        return result;
    }
    
    func collectionSomeValue() -> Any? {
        typealias Element = Iterator.Element;
        var result: [Any] = [Any]();
        self.forEach { (each) in
            if let transformable = each as? GWJudgeModelType, let transValue = transformable.someValue() {
                result.append(transValue);
            } else {
                print("value: \(each) isn't transformable type!");
            }
        }
        return result;
    }
}

//MARK: Array
extension Array:GWCustomBasicType{
    static func strJudgeType(from object: Any) -> Array<Element>? {
        return self.collectionJudgeType(from: object);
    }
    func strSomeValue() -> Any? {
        return self.collectionSomeValue();
    }
}

//MARK: Set
extension Set:GWCustomBasicType{
    static func strJudgeType(from object: Any) -> Set<Element>? {
        if let arr = self.collectionJudgeType(from: object) {
            return Set(arr);
        }
        return nil;
    }
    func strSomeValue() -> Any? {
        return self.collectionSomeValue();
    }
}

//MARK: Dictionary
extension Dictionary:GWCustomBasicType{
    public static func strJudgeType(from object: Any) -> Dictionary<Key, Value>? {
        guard let dict = object as? [String: Any] else {
            print("不是字典类型");
            return nil;
        }
        var result = [Key: Value]();
        for (key, value) in dict {
            if let sKey = key as? Key {
                if let nValue = (Value.self as? GWJudgeModelType.Type)?.judgeType(from: value) as? Value {
                    result[sKey] = nValue;
                } else if let nValue = value as? Value {
                    result[sKey] = nValue;
                }
            }
        }
        return result;
    }
    func strSomeValue() -> Any? {
        var result = [String: Any]();
        for (key, value) in self {
            if let key = key as? String {
                if let transformable = value as? GWJudgeModelType {
                    if let transValue = transformable.someValue() {
                        result[key] = transValue;
                    }
                }
            }
        }
        return result;
    }
}



//MARK: GWBridgeType - 判断oc桥接类型
protocol GWBridgeType:GWJudgeModelType{
    static func strJudgeType(from object: Any) -> GWBridgeType?
    func strSomeValue() -> Any?
}

extension NSString:GWBridgeType{
    func strSomeValue() -> Any? {
        return self;
    }
    static func strJudgeType(from object: Any) -> GWBridgeType? {
        if let str = String.judgeType(from: object) {
            return NSString(string: str);
        }
        return nil;
    }
}

extension NSNumber:GWBridgeType{
    static func strJudgeType(from object: Any) -> GWBridgeType? {
        switch object {
        case let num as NSNumber:
            return num;
        case let str as NSString:
            let lowercase = str.lowercased
            if lowercase == "true" {
                return NSNumber(booleanLiteral: true)
            } else if lowercase == "false" {
                return NSNumber(booleanLiteral: false)
            } else {
                // normal number
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                return formatter.number(from: str as String)
            }
        default:
            return nil;
        }
    }
    
    func strSomeValue() -> Any? {
        return self;
    }
}

extension NSArray:GWBridgeType{
    static func strJudgeType(from object: Any) -> GWBridgeType? {
        return object as? NSArray;
    }
    func strSomeValue() -> Any? {
        return (self as? Array<Any>)?.someValue();
    }
}

extension NSDictionary:GWBridgeType {
    static func strJudgeType(from object: Any) -> GWBridgeType? {
        return object as? NSDictionary;
    }
    func strSomeValue() -> Any? {
        return (self as? Dictionary<String, Any>)?.someValue();
    }
}

//MARK: GWEnumType - 枚举
public protocol GWEnumType:GWJudgeModelType {
    static func strJudgeType(from object: Any) -> Self?
    func strSomeValue() -> Any?
}

extension RawRepresentable where Self:GWEnumType{
    static func strJudgeType(from object: Any) -> Self? {
        if let transformableType = RawValue.self as? GWJudgeModelType.Type {
            if let typedValue = transformableType.judgeType(from: object) {
                return Self(rawValue: typedValue as! RawValue);
            }
        }
        return nil;
    }
    func strSomeValue() -> Any? {
        return self.rawValue;
    }
}

//MARK: GWExpendModelType - 自定义model类型
public protocol GWExpendModelType:GWJudgeModelType {
    init();
    static func strJudgeType(from object: Any) -> Self?
    func strSomeValue() -> Any?
    
    mutating func mapping(mapper: HelpingMapper)
}

extension GWExpendModelType {
    public mutating func mapping(mapper: HelpingMapper) {}
}

//判断类型
extension GWExpendModelType{
    static func strJudgeType(from object: Any) -> Self?{
//        判断是否是字典
        if let dict = object as? [String: Any] {
            return self.strJudgeType(dict: dict) as? Self;
        }
        return nil;
    }
    static func strJudgeType(dict: [String: Any]) -> GWExpendModelType? {
        var instance: Self;
        if let _nsType = Self.self as? NSObject.Type {
            instance = _nsType.createInstance() as! Self;
        } else {
            instance = Self.init()
        }
        strJudgeType(dict: dict, to: &instance);
        return instance
    }
//    inout 指的是获取对象内存地址
    static func strJudgeType(dict: [String: Any], to instance: inout Self) {
        guard let properties = getProperties(forType: Self.self) else {
            print("获取类型失败: \(type(of: Self.self))")
            return
        }
        
        // do user-specified mapping first
        let mapper = HelpingMapper()
        instance.mapping(mapper: mapper)
        
        // 获取指针
        let rawPointer = instance.GW_MuPointerType()
//        print("instance start at: ", Int(bitPattern: rawPointer))
        
        // process dictionary
        let _dict = convertKeyIfNeeded(dict: dict)
        
//        是否是nsobject类型
        let instanceIsNsObject = instance.isNSObjectType()
//        是否是oc桥接类型
        let bridgedPropertyList = instance.getBridgedPropertyList()
        
//        遍历自身属性
        for property in properties {
            let isBridgedProperty = instanceIsNsObject && bridgedPropertyList.contains(property.key)
            
//           获取指针地址
            let propAddr = rawPointer.advanced(by: property.offset)
//            print(property.key, "address at: ", Int(bitPattern: propAddr))
            if mapper.propertyExcluded(key: Int(bitPattern: propAddr)) {
                print("Exclude property: \(property.key)")
                continue
            }
            
            let propertyDetail = PropertyInfo(key: property.key, type: property.type, address: propAddr, bridged: isBridgedProperty)
//            print("field: ", property.key, "  offset: ", property.offset, "  isBridgeProperty: ", isBridgedProperty)
            
            if let rawValue = getRawValueFrom(dict: _dict, property: propertyDetail, mapper: mapper) {
                if let convertedValue = convertValue(rawValue: rawValue, property: propertyDetail, mapper: mapper) {
                    assignProperty(convertedValue: convertedValue, instance: instance, property: propertyDetail)
                    continue
                }
            }
//            print("Property: \(property.key) hasn't been written in")
        }
    }
}

//获取值
extension GWExpendModelType {
    
    func strSomeValue() -> Any? {
        return Self._serializeAny(object: self)
    }
    
    static func _serializeAny(object: GWJudgeModelType) -> Any? {
        
        let mirror = Mirror(reflecting: object)
        
        guard let displayStyle = mirror.displayStyle else {
            return object.someValue()
        }
        
        // after filtered by protocols above, now we expect the type is pure struct/class
        switch displayStyle {
            case .class, .struct:
                let mapper = HelpingMapper()
                // do user-specified mapping first
                if !(object is GWExpendModelType) {
                    print("This model of type: \(type(of: object)) is not mappable but is class/struct type")
                    return object
                }
                
                let children = readAllChildrenFrom(mirror: mirror)
                
                guard let properties = getProperties(forType: type(of: object)) else {
                    print("Can not get properties info for type: \(type(of: object))")
                    return nil
                }
                
                var mutableObject = object as! GWExpendModelType
                let instanceIsNsObject = mutableObject.isNSObjectType()
                let head = mutableObject.GW_MuPointerType()
                let bridgedProperty = mutableObject.getBridgedPropertyList()
                let propertyInfos = properties.map({ (desc) -> PropertyInfo in
                    return PropertyInfo(key: desc.key, type: desc.type, address: head.advanced(by: desc.offset),
                                        bridged: instanceIsNsObject && bridgedProperty.contains(desc.key))
                })
                
                mutableObject.mapping(mapper: mapper)
                
                let requiredInfo = merge(children: children, propertyInfos: propertyInfos)
                
                return _serializeModelObject(instance: mutableObject, properties: requiredInfo, mapper: mapper) as Any
            default:
                return object.someValue()
        }
    }
    
    static func _serializeModelObject(instance: GWExpendModelType, properties: [String: (Any, PropertyInfo?)], mapper: HelpingMapper) -> [String: Any] {
        
        var dict = [String: Any]()
        for (key, property) in properties {
            var realKey = key
            var realValue = property.0
            
            if let info = property.1 {
                if info.bridged, let _value = (instance as! NSObject).value(forKey: key) {
                    realValue = _value
                }
                
                if mapper.propertyExcluded(key: Int(bitPattern: info.address)) {
                    continue
                }
                
                if let mappingHandler = mapper.getMappingHandler(key: Int(bitPattern: info.address)) {
                    // if specific key is set, replace the label
                    if let mappingPaths = mappingHandler.mappingPaths, mappingPaths.count > 0 {
                        // take the first path, last segment if more than one
                        realKey = mappingPaths[0].segments.last!
                    }
                    
                    if let transformer = mappingHandler.takeValueClosure {
                        if let _transformedValue = transformer(realValue) {
                            dict[realKey] = _transformedValue
                        }
                        continue
                    }
                }
            }
            
            if let typedValue = realValue as? GWJudgeModelType {
                if let result = self._serializeAny(object: typedValue) {
                    dict[realKey] = result
                    continue
                }
            }
            
//            print("The value for key: \(key) is not transformable type")
        }
        return dict
    }
}

//进行子父类整合
fileprivate func merge(children: [(String, Any)], propertyInfos: [PropertyInfo]) -> [String: (Any, PropertyInfo?)] {
    var infoDict = [String: PropertyInfo]()
    propertyInfos.forEach { (info) in
        infoDict[info.key] = info
    }
    
    var result = [String: (Any, PropertyInfo?)]()
    children.forEach { (child) in
        result[child.0] = (child.1, infoDict[child.0])
    }
    return result
}

//获取所有子类
fileprivate func readAllChildrenFrom(mirror: Mirror) -> [(String, Any)] {
    var children = [(label: String?, value: Any)]()
    let mirrorChildrenCollection = AnyRandomAccessCollection(mirror.children)!
    children += mirrorChildrenCollection
    
    var currentMirror = mirror
    while let superclassChildren = currentMirror.superclassMirror?.children {
        let randomCollection = AnyRandomAccessCollection(superclassChildren)!
        children += randomCollection
        currentMirror = currentMirror.superclassMirror!
    }
    var result = [(String, Any)]()
    children.forEach { (child) in
        if let _label = child.label {
            result.append((_label, child.value))
        }
    }
    return result
}

//覆盖成小写
fileprivate func convertKeyIfNeeded(dict: [String: Any]) -> [String: Any] {
    if GW_ModelFilter.deserializeOptions.contains(.caseInsensitive) {
        var newDict = [String: Any]()
        dict.forEach({ (kvPair) in
            let (key, value) = kvPair
            newDict[key.lowercased()] = value
        })
        return newDict
    }
    return dict
}

//获取指针对应的value
fileprivate func getRawValueFrom(dict: [String: Any], property: PropertyInfo, mapper: HelpingMapper) -> Any? {
    let address = Int(bitPattern: property.address)
    if let mappingHandler = mapper.getMappingHandler(key: address) {
        if let mappingPaths = mappingHandler.mappingPaths, mappingPaths.count > 0 {
            for mappingPath in mappingPaths {
                if let _value = dict.findValueBy(path: mappingPath) {
                    return _value
                }
            }
            return nil
        }
    }
    if GW_ModelFilter.deserializeOptions.contains(.caseInsensitive) {
        return dict[property.key.lowercased()]
    }
    return dict[property.key]
}

extension Dictionary where Key == String, Value: Any {
    func findValueBy(path: MappingPath) -> Any? {
        var currentDict: [String: Any]? = self
        var lastValue: Any?
        path.segments.forEach { (segment) in
            lastValue = currentDict?[segment]
            currentDict = currentDict?[segment] as? [String: Any]
        }
        return lastValue
    }
}

//重新赋值
fileprivate func convertValue(rawValue: Any, property: PropertyInfo, mapper: HelpingMapper) -> Any? {
    if rawValue is NSNull { return nil }
    if let mappingHandler = mapper.getMappingHandler(key: Int(bitPattern: property.address)), let transformer = mappingHandler.assignmentClosure {
        return transformer(rawValue)
    }
    if let transformableType = property.type as? GWJudgeModelType.Type {
        return transformableType.judgeType(from: rawValue)
    } else {
        return extensions(of: property.type).takeValue(from: rawValue)
    }
}

//基本数据类型
fileprivate func assignProperty(convertedValue: Any, instance: GWExpendModelType, property: PropertyInfo) {
    if property.bridged {
        (instance as! NSObject).setValue(convertedValue, forKey: property.key)
    } else {
        extensions(of: property.type).write(convertedValue, to: property.address)
    }
}

struct MappingPath {
    var segments: [String]
    
    static func buildFrom(rawPath: String) -> MappingPath {
        let regex = try! NSRegularExpression(pattern: "(?<![\\\\])\\.")
        let nsString = rawPath as NSString
        let results = regex.matches(in: rawPath, range: NSRange(location: 0, length: nsString.length))
        var splitPoints = results.map { $0.range.location }
        
        var curPos = 0
        var pathArr = [String]()
        splitPoints.append(nsString.length)
        splitPoints.forEach({ (point) in
            let start = rawPath.index(rawPath.startIndex, offsetBy: curPos)
            let end = rawPath.index(rawPath.startIndex, offsetBy: point)
            let subPath = String(rawPath[start ..< end]).replacingOccurrences(of: "\\.", with: ".")
            if !subPath.isEmpty {
                pathArr.append(subPath)
            }
            curPos = point + 1
        })
        return MappingPath(segments: pathArr)
    }
}

public class MappingPropertyHandler {
    var mappingPaths: [MappingPath]?
    var assignmentClosure: ((Any?) -> (Any?))?
    var takeValueClosure: ((Any?) -> (Any?))?
    
    public init(rawPaths: [String]?, assignmentClosure: ((Any?) -> (Any?))?, takeValueClosure: ((Any?) -> (Any?))?) {
        let mappingPaths = rawPaths?.map({ (rawPath) -> MappingPath in
            if GW_ModelFilter.deserializeOptions.contains(.caseInsensitive) {
                return MappingPath.buildFrom(rawPath: rawPath.lowercased())
            }
            return MappingPath.buildFrom(rawPath: rawPath)
        }).filter({ (mappingPath) -> Bool in
            return mappingPath.segments.count > 0
        })
        if let count = mappingPaths?.count, count > 0 {
            self.mappingPaths = mappingPaths
        }
        self.assignmentClosure = assignmentClosure
        self.takeValueClosure = takeValueClosure
    }
}

public class HelpingMapper {
    
    private var mappingHandlers = [Int: MappingPropertyHandler]()
    private var excludeProperties = [Int]()
    
    internal func getMappingHandler(key: Int) -> MappingPropertyHandler? {
        return self.mappingHandlers[key]
    }
    
    internal func propertyExcluded(key: Int) -> Bool {
        return self.excludeProperties.contains(key)
    }
    
    public func specify<T>(property: inout T, name: String) {
        self.specify(property: &property, name: name, converter: nil)
    }
    
    public func specify<T>(property: inout T, converter: @escaping (String) -> T) {
        self.specify(property: &property, name: nil, converter: converter)
    }
    
    public func specify<T>(property: inout T, name: String?, converter: ((String) -> T)?) {
        let pointer = withUnsafePointer(to: &property, { return $0 })
        let key = Int(bitPattern: pointer)
        let names = (name == nil ? nil : [name!])
        
        if let _converter = converter {
            let assignmentClosure = { (jsonValue: Any?) -> Any? in
                if let _value = jsonValue{
                    if let object = _value as? NSObject{
                        if let str = String.judgeType(from: object){
                            return _converter(str)
                        }
                    }
                }
                return nil
            }
            self.mappingHandlers[key] = MappingPropertyHandler(rawPaths: names, assignmentClosure: assignmentClosure, takeValueClosure: nil)
        } else {
            self.mappingHandlers[key] = MappingPropertyHandler(rawPaths: names, assignmentClosure: nil, takeValueClosure: nil)
        }
    }
    
    public func exclude<T>(property: inout T) {
        self._exclude(property: &property)
    }
    
    fileprivate func addCustomMapping(key: Int, mappingInfo: MappingPropertyHandler) {
        self.mappingHandlers[key] = mappingInfo
    }
    
    fileprivate func _exclude<T>(property: inout T) {
        let pointer = withUnsafePointer(to: &property, { return $0 })
        self.excludeProperties.append(Int(bitPattern: pointer))
    }
}


public struct GW_ModelFilter{
    private static var _mode = DebugMode.error
    public static var debugMode: DebugMode {
        get {
            return _mode
        }
        set {
            _mode = newValue
        }
    }
    
    public static var deserializeOptions: DeserializeOptions = .defaultOptions
}

public struct DeserializeOptions: OptionSet {
    public let rawValue: Int
    
    public static let caseInsensitive = DeserializeOptions(rawValue: 1 << 0)
    
    public static let defaultOptions: DeserializeOptions = []
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public enum DebugMode: Int {
    case verbose = 0
    case debug = 1
    case error = 2
    case none = 3
}


extension NSObject{
    static func createInstance() -> NSObject {
        return self.init()
    }
}
