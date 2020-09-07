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
    func modelToJson() -> [String: Any]? {
        if let dict = Self.gw_serializeAny(object: self) as? [String: Any] {
            return dict
        }
        return nil
    }
    
    func modelToJsonString(prettyPrint: Bool = false) -> String? {
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
    func modelToJson() -> [[String: Any]?] {
        return self.map{ $0.modelToJson() }
    }
    
    func toJSONString(prettyPrint: Bool = false) -> String? {
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

//MARK: json->model
public extension GW_ModelAndJson{
    static func jsonToModel(json:Any?,designatedPath: String? = nil) -> Any?{
        switch json {
        case let obj as String:
            do{
                let jsonObject = try JSONSerialization.jsonObject(with: obj.data(using: String.Encoding.utf8)!, options: .allowFragments)
                return Self.jsonToModel(json: jsonObject,designatedPath: designatedPath)
            }catch let error{
                print(error)
                return nil;
            }
        case let obj as Data:
            do{
                let jsonObject = try JSONSerialization.jsonObject(with: obj, options: .allowFragments)
                return Self.jsonToModel(json: jsonObject,designatedPath: designatedPath)
            }catch let error{
                print(error)
                return nil;
            }
        case let obj as NSArray:
            return JSONDeserializer<Self>.jsonToModelArrayFrom(array: obj,designatedPath: designatedPath)
        case let obj as [Any]:
            return JSONDeserializer<Self>.jsonToModelArrayFrom(array: obj,designatedPath: designatedPath)
        case let obj as NSDictionary:
            return JSONDeserializer<Self>.jsonToModelFrom(dict: obj, designatedPath: designatedPath)
        case let obj as [String:Any]:
            return JSONDeserializer<Self>.jsonToModelFrom(dict: obj, designatedPath: designatedPath)
        default:
            return nil
        }
    }
}

public class JSONDeserializer<Obj: GW_ModelAndJson> {
    
    public static func jsonToModelFrom(dict: NSDictionary?, designatedPath: String? = nil) -> Any? {
        return jsonToModelFrom(dict: dict as? [String: Any], designatedPath: designatedPath)
    }
    
    public static func jsonToModelFrom(dict: [String: Any]?, designatedPath: String? = nil) -> Any? {
        if let path = designatedPath {
            let target = dict;
            let subJct = getInnerObject(inside: target, by: path)
            return Obj.jsonToModel(json: subJct, designatedPath: nil)
        }
        if let _dict = dict {
            return Obj.strJudgeType(dict: _dict) as? Obj
        }
        return nil
    }
    
    public static func update(object: inout Obj, from dict: [String: Any]?, designatedPath: String? = nil) {
        var targetDict = dict
        if let path = designatedPath {
            targetDict = getInnerObject(inside: targetDict, by: path) as? [String: Any]
        }
        if let _dict = targetDict {
            Obj.strJudgeType(dict: _dict, to: &object)
        }
    }
    
    public static func update(object: inout Obj, from json: String?, designatedPath: String? = nil) {
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
    
    public static func jsonToModelArrayFrom(array: NSArray?,designatedPath: String? = nil) -> [Any?]? {
        return jsonToModelArrayFrom(array: array as? [Any] , designatedPath: designatedPath)
    }
    
    public static func jsonToModelArrayFrom(array: [Any]?,designatedPath: String? = nil) -> [Any?]? {
        guard let _arr = array else {
            return nil
        }
        return _arr.map({ (item) -> Any? in
            return self.jsonToModelFrom(dict: item as? [String: Any] ,designatedPath: designatedPath)
        })
    }
}

//json路径替换
fileprivate func getInnerObject(inside object: Any?, by designatedPath: String?) -> Any? {
    var result: Any? = object
    var abort = false
    print("path =\(String(describing: designatedPath))")
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
