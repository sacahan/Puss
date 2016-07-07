//
//  Branch.swift
//  Puss
//
//  Created by Brian Han on 2016/7/7.
//  Copyright © 2016年 Brian Han. All rights reserved.
//


class Branch: CustomDebugStringConvertible {
    var head: String?
    let local: String
    let hash: String
    let comment: String
    var isDelete: Bool = false
    var isPush: Bool = false
    
    init(_ record:String) {
        let segments = record.characters.split(separator: " ").map{ String($0) }
        if segments[0] == "*" {
            self.head = segments[0]
            self.local = segments[1]
            self.hash = segments[2]
            self.comment = segments.suffix(from: 3).joined(separator: " ")
        }else {
            self.head = nil
            self.local = segments[0]
            self.hash = segments[1]
            self.comment = segments.suffix(from: 2).joined(separator: " ")
        }
    }
    
    var debugDescription: String {
        return "(\(self.head), \(self.local), \(self.hash), \(self.comment), \(self.isDelete), \(self.isPush))"
    }
}
