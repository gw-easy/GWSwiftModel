//
//  ViewController.swift
//  GWSwiftModel
//
//  Created by zdwx on 2018/12/15.
//  Copyright © 2018 DoubleK. All rights reserved.
//

import UIKit

enum Grade: Int, Gw_JsonWithEnum {
    case One = 1
    case Two = 2
    case Three = 3
}

enum Gender: String, Gw_JsonWithEnum {
    case Male = "Male"
    case Female = "Female"
}

struct Teacher: GW_ModelAndJson {
    var name: String?
    var age: Int?
    var height: Int?
    var gender: Gender?
}

struct Subject: GW_ModelAndJson {
    var name: String?
    var id: Int64?
    var credit: Int?
    var lessonPeriod: Int?
}

class Student: GW_ModelAndJson {
    var id: String?
    var name: String?
    var age: Int?
    var grade: Grade = .One
    var height: Int?
    var gender: Gender?
    var className: String?
    var teacher: Teacher = Teacher()
    var subjects: [Subject]?
    var seat: String?
    
    required init() {}
}
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        self.serialization()
        self.addModelObject()
//        self.deserialization()
    }
    
    func test_json() {
        
    }
    
    func test_json2() {
        
    }
    
    func addModelObject() {
        let path = Bundle.main.path(forResource: "ModelObject", ofType: "json")
        
        let jsonStr = try! String.init(contentsOfFile:path! , encoding: String.Encoding.utf8)
        
        if let tModel = TestModel.jsonToModel(json: jsonStr) as? TestModel{
            printAction(obj:tModel.id)
            printAction(obj:tModel.data)
            printAction(obj:tModel.data?.feedbacks)
            for par in tModel.data?.partnerteamlist ?? []{
                printAction(obj: par.pteamId)
                printAction(obj: par.pteamprice)
                printAction(obj: par.setModel)
                printAction(obj: par.setModel?.model1Str)
                printAction(obj: par.setModel?.baseModel_Int)
                printAction(obj: par.setModel?.baseMM_float)
                printAction(obj: par.setModel?.baseM)
                printAction(obj: par.ptitle)
            }
            printAction(obj:tModel.state)
            printAction(obj:tModel.setModel)
        }
        
    }
    
    func printAction(obj:Any?) {
        print(obj ?? "")
    }
    
    func serialization() {
        let student = Student()
        student.name = "gw"
        student.gender = .Female
        student.subjects = [Subject(name: "gw_model", id: 1, credit: 23, lessonPeriod: 64), Subject(name: "English", id: 2, credit: 12, lessonPeriod: 32)]
        
        
        print(student.modelToJson()!)
//                print(student.modelToJsonString()!)
//                print(student.modelToJsonString(prettyPrint: true)!)
        //
                print([student].modelToJson())
        //        print([student].toJSONString()!)
        //        print([student].toJSONString(prettyPrint: true)!)
    }

    func deserialization() {
        let jsonString = "{\"id\":\"77544\",\"json_name\":\"Tom Li\",\"age\":18,\"grade\":2,\"height\":180,\"gender\":\"Female\",\"className\":\"A\",\"teacher\":{\"name\":\"Lucy He\",\"age\":28,\"height\":172,\"gender\":\"Female\",},\"subjects\":[{\"name\":\"math\",\"id\":18000324583,\"credit\":4,\"lessonPeriod\":48},{\"name\":\"computer\",\"id\":18000324584,\"credit\":8,\"lessonPeriod\":64}],\"seat\":\"4-3-23\"}"

//            Student.json_To_Model(json: jsonString, designatedPath: nil)
        if let student = Student.jsonToModel(json: jsonString) as? GW_ModelAndJson{
            print(student.modelToJson() ?? "");
        }
        let arrayJSONString = "[{\"id\":\"77544\",\"json_name\":\"Tom Li\",\"age\":18,\"grade\":2,\"height\":180,\"gender\":\"Female\",\"className\":\"A\",\"teacher\":{\"name\":\"Lucy He\",\"age\":28,\"height\":172,\"gender\":\"Female\",},\"subjects\":[{\"name\":\"math\",\"id\":18000324583,\"credit\":4,\"lessonPeriod\":48},{\"name\":\"computer\",\"id\":18000324584,\"credit\":8,\"lessonPeriod\":64}],\"seat\":\"4-3-23\"}]"
        
//        Student.json_To_Model(json: arrayJSONString, designatedPath: nil)
        if let students = Student.jsonToModel(json: arrayJSONString) as? [GW_ModelAndJson]{
            print(students[0].modelToJson() ?? "");
        }
//        if let students = [Student].jsonToModel(from: arrayJSONString) {
//            print(students.count)
//            print(students[0]!.modelToJson()!)
//        }
    }
}

