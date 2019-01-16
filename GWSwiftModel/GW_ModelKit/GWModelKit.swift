//
//  GWModelKit.swift
//  GWSwiftModel
//
//  Created by zdwx on 2018/12/17.
//  Copyright © 2018 DoubleK. All rights reserved.
//

import Foundation


//GW_ModelAndJson协议
public protocol GW_ModelAndJson : GWExpendModelType{
    
}

//model->json
public extension GW_ModelAndJson{
    public func modelToJson() -> [String: Any]? {
        if let dict = Self._serializeAny(object: self) as? [String: Any] {
            return dict
        }
        return nil
    }
    
    public func modelToJsonString(prettyPrint: Bool = false) -> String? {
        if let anyObject = self.modelToJson() {
            if JSONSerialization.isValidJSONObject(anyObject) {
                do {
                    let jsonData: Data
                    if prettyPrint {
                        jsonData = try JSONSerialization.data(withJSONObject: anyObject, options: [.prettyPrinted])
                    } else {
                        jsonData = try JSONSerialization.data(withJSONObject: anyObject, options: [])
                    }
                    return String(data: jsonData, encoding: .utf8)
                } catch let error {
                    print(error)
                }
            } else {
                print("\(anyObject)) is not a valid JSON Object")
            }
        }
        return nil
    }
}

public extension Collection where Iterator.Element: GW_ModelAndJson {
    public func modelToJson() -> [[String: Any]?] {
        return self.map{ $0.modelToJson() }
    }
    
    public func toJSONString(prettyPrint: Bool = false) -> String? {
        
        let anyArray = self.modelToJson()
        if JSONSerialization.isValidJSONObject(anyArray) {
            do {
                let jsonData: Data
                if prettyPrint {
                    jsonData = try JSONSerialization.data(withJSONObject: anyArray, options: [.prettyPrinted])
                } else {
                    jsonData = try JSONSerialization.data(withJSONObject: anyArray, options: [])
                }
                return String(data: jsonData, encoding: .utf8)
            } catch let error {
                print("Collection \(error)")
            }
        } else {
            print("\(self.modelToJson()) is not a valid JSON Object")
        }
        return nil
    }
}

//MARK: model->json
public extension GW_ModelAndJson{
    public static func jsonToModel(json:Any?,designatedPath: String? = nil) -> Any?{
        switch json {
        case let ar as String:
            return JSONDeserializer<Self>.jsonToModelFrom(json: ar, designatedPath: designatedPath)
        case let ar as NSArray:
            return JSONDeserializer<Self>.jsonToModelArrayFrom(array: ar)
        case let ar as [Any]:
            return JSONDeserializer<Self>.jsonToModelArrayFrom(array: ar)
        case let ar as NSDictionary:
            return JSONDeserializer<Self>.jsonToModelFrom(dict: ar, designatedPath: designatedPath)
        case let ar as [String:Any]:
            return JSONDeserializer<Self>.jsonToModelFrom(dict: ar, designatedPath: designatedPath)
        default:
            return nil
        }
    }
}

public class JSONDeserializer<T: GW_ModelAndJson> {
    
    /// Finds the internal dictionary in `dict` as the `designatedPath` specified, and map it to a Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public static func jsonToModelFrom(dict: NSDictionary?, designatedPath: String? = nil) -> T? {
        return jsonToModelFrom(dict: dict as? [String: Any], designatedPath: designatedPath)
    }
    
    /// Finds the internal dictionary in `dict` as the `designatedPath` specified, and map it to a Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public static func jsonToModelFrom(dict: [String: Any]?, designatedPath: String? = nil) -> T? {
        var targetDict = dict
        if let path = designatedPath {
            targetDict = getInnerObject(inside: targetDict, by: path) as? [String: Any]
        }
        if let _dict = targetDict {
            return T.strJudgeType(dict: _dict) as? T
        }
        return nil
    }
    
    
    /// Finds the internal JSON field in `json` as the `designatedPath` specified, and converts it to Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public static func jsonToModelFrom(json: String?, designatedPath: String? = nil) -> Any? {
        guard let _json = json else {
            return nil
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: _json.data(using: String.Encoding.utf8)!, options: .allowFragments)
            if let jsonDict = jsonObject as? NSDictionary {
                return self.jsonToModelFrom(dict: jsonDict, designatedPath: designatedPath)
            }else if let jsonArray = getInnerObject(inside: jsonObject, by: designatedPath) as? [Any] {
                return jsonArray.map({ (item) -> T? in
                    return self.jsonToModelFrom(dict: item as? [String: Any])
                })
            }
        } catch let error {
            print(error)
        }
        return nil
    }
    
    /// Finds the internal dictionary in `dict` as the `designatedPath` specified, and use it to reassign an exist model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public static func update(object: inout T, from dict: [String: Any]?, designatedPath: String? = nil) {
        var targetDict = dict
        if let path = designatedPath {
            targetDict = getInnerObject(inside: targetDict, by: path) as? [String: Any]
        }
        if let _dict = targetDict {
            T.strJudgeType(dict: _dict, to: &object)
        }
    }
    
    /// Finds the internal JSON field in `json` as the `designatedPath` specified, and use it to reassign an exist model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public static func update(object: inout T, from json: String?, designatedPath: String? = nil) {
        guard let _json = json else {
            return
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: _json.data(using: String.Encoding.utf8)!, options: .allowFragments)
            if let jsonDict = jsonObject as? [String: Any] {
                update(object: &object, from: jsonDict, designatedPath: designatedPath)
            }
        } catch let error {
            print(error)
        }
    }
    
    
    /// mapping raw array to Models array
    public static func jsonToModelArrayFrom(array: NSArray?) -> [T?]? {
        return jsonToModelArrayFrom(array: array as? [Any])
    }
    
    /// mapping raw array to Models array
    public static func jsonToModelArrayFrom(array: [Any]?) -> [T?]? {
        guard let _arr = array else {
            return nil
        }
        return _arr.map({ (item) -> T? in
            return self.jsonToModelFrom(dict: item as? NSDictionary)
        })
    }
}

//json路径替换
fileprivate func getInnerObject(inside object: Any?, by designatedPath: String?) -> Any? {
    var result: Any? = object
    var abort = false
    if let paths = designatedPath?.components(separatedBy: "/"), paths.count > 0 {
        var next = object as? [String: Any]
        paths.forEach({ (seg) in
            if seg.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "" || abort {
                return
            }
            if let _next = next?[seg] {
                result = _next
                next = _next as? [String: Any]
            } else {
                abort = true
            }
        })
    }
    return abort ? nil : result
}

//枚举 
public protocol Gw_JsonWithEnum : GWEnumType{
    
}
