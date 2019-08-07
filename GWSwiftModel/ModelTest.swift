//
//  ModelTest.swift
//  GWSwiftModel
//
//  Created by zdwx on 2019/7/19.
//  Copyright © 2019 DoubleK. All rights reserved.
//

import UIKit

class ModelTest: NSObject {
    
}

protocol proTest:GW_ModelAndJson {
    
}

class proTest1: proTest {
    var Id: String?
    required init() {
        
    }
}

class proTest2: proTest {
    var ParentId: String?
    required init() {
        
    }
}

struct proTest3 : proTest {
    var Title: String?
}

class Test_model3<T:proTest>: proTest {
    var Process: NSNumber?
    var LectureNotesInfo: Int?
    var Id: String?
    var Title: String?
    var ParentId: String?
    var ClassHoursInfo: String?
    var pBuyInfo: String?
    var MP4Url: String?
    var Children: [T]?
    required init() {
        
    }
}

class BaseM: GW_ModelAndJson {
    var baseM: String?
    var baseM_float: Float?
    var Id: String?
    required init() {
        
    }
}

class baseMM: BaseM {
    var baseMM: String?
    var baseMM_float: Float?
    var c_str: u_char?
    var ParentId: String?
    required init() {
        
    }
}

class BaseModel: baseMM {
    var baseModelStr: String?
    var baseModel_Int: NSInteger?
    required init() {
        
    }
}

class Model3: GW_ModelAndJson {
    var model3Str: String?
    var m3Bool: Bool?
    required init() {
        
    }
}

class Model2: GW_ModelAndJson {
    var model2Str: String?
    var m2_Int: Int?
    var model3: Model3?
    required init() {
        
    }
}

class Model1: BaseModel {
    var model1Str: String?
    var model1_int: Int?
    var num: NSNumber?
    var dddr: String?
    var model2: Model2?
    required init() {
        
    }
}

class feedback_testContent: GW_ModelAndJson {
    var comment: String?
    var Fee: Int?
    var createtime: Date?
    var score: Int?
    var username : String?
    var setModel: Model1?
    required init() {
        
    }
}

class Head_test: GW_ModelAndJson {
    var totalcount: String?
    var totalscore: String?
    var feedbacklist: [feedback_testContent]?
    var model1Str: String?
    required init() {
        
    }
}

class Partnerteamlist_test: GW_ModelAndJson {
    var pteamId: Int?
    var pteamprice: Int?
    var setModel: Model1?
    var ptitle: String?
    required init() {
        
    }
}

class Liketeam_testContent: GW_ModelAndJson {
    var limage: String?
    var lmarketprice: Float?
    var ltitle: String?
    var lteamId: Int?
    var lteamprice : Int?
    var setModel: Model1?
    required init() {
        
    }
}

class response_Test: GW_ModelAndJson {
    var feedbacks: Head_test?
    var partnerteamlist: [Partnerteamlist_test]?
    var liketeamlist: [Liketeam_testContent]?
    var setModel: [feedback_testContent]?
    required init() {
        
    }
}

class TestModel: GW_ModelAndJson {
    var id: String?
    var data: response_Test?
    var state: Int?
    var setModel: Model1?
    required init() {
        
    }
}

