//
//  Const.swift
//  NucleicAcid
//
//  Created by Lcrnice on 2022/9/1.
//

import Foundation

struct U {
    static let oneDaySeconds = 60 * 60 * 24
    static let targetTimestampKey = "targetTimestampKey"
    static let lastTestTimestampKey = "lastTestTimestampKey"
    static let defaultDayKey = "defaultDayKey"
    static let noticeHourKey = "noticeHourKey"
    static let noticeMinuteKey = "noticeMinuteKey"
    static let withoutRepeatNoticeKey = "withoutRepeatNoticeKey"
}

class Utils {
    static func localNumber(key: String) -> Int {
        UserDefaults.standard.integer(forKey: key)
    }
    
    static func configNumber(_ value: Int, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    static func bool(key: String) -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }
    
    static func configBool(_ value: Bool, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}
