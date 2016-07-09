//
//  GitHelper.swift
//  Git Multi-Push
//
//  Created by Brian Han on 2016/6/30.
//  Copyright © 2016年 Brian Han. All rights reserved.
//

import Cocoa
import Foundation

class GitHelper {
    var branches: [Branch]?
    var git: String?
    
    var repoPath: String? {
        didSet {
            self.doBranchList()
        }
    }
    
    // 取得Git命令與Branch Repo位置
    func doBranchList() {
        branches?.removeAll()
        
        if self.git == nil {
            let (location, s0) = self.runCommand(dir: "/", command: "/usr/bin/which", args: "git")
            if location != nil && s0 == 0 {
                self.git = location!.trimmingCharacters(in: CharacterSet.newlines)
            }
        }
        
        let (allBranches, s1) = self.runCommand(dir: self.repoPath!, command: self.git!, args: "branch", "-lvv")
        
        if allBranches != nil && s1 == 0 {
            self.branches = allBranches!.characters.split(separator: "\n").map{ Branch(String($0)) }
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default().post(name: Notification.Name("RELOAD_TABLE_VIEW"), object: self, userInfo: nil)
        }
    }
    
    // 執行Remote Delete & Push
    func doRemotePush() {
        DispatchQueue.global(attributes: .qosBackground).async {
            for (idx, branch) in self.branches!.enumerated() {
                var result: String = ""
                if branch.isDelete {
                    let (delete, _) = self.runCommand(dir: self.repoPath!, command: self.git!, args: "push", "origin", ":" + branch.local)
                    result.append("⦿ \(branch.local) deleted. ")
                    print("\(delete!)")
                }
                
                if branch.isPush {
                    let (push, _) = self.runCommand(dir: self.repoPath!, command: self.git!, args: "push", "origin", branch.local + ":" + branch.local)
                    result.append("⦿ \(branch.local) pushed.")
                    print("\(push!)")
                }
                
                if result != "" { result.append("\n") }
                
                DispatchQueue.main.async {
                    NotificationCenter.default().post(name: Notification.Name("REMOTE_PUSH_DONE"), object: self, userInfo: ["index":idx, "total":self.branches!.count, "result":result])
                }
            }
        }
    }
    
    // 切換Branch
    func doBranchCheckout(branch: Branch) {
        DispatchQueue.global(attributes: .qosBackground).async {
            let (checkout, s0) = self.runCommand(dir: self.repoPath!, command: self.git!, args: "checkout", branch.local)
            if s0 > 0 {
                print("Error: \(checkout!) (code: \(s0))")
            }
            self.doBranchList()
        }
    }
    
    // 傳入Git參數交由命令列執行
    func runCommand(dir:String, command:String, args:String...) -> (output:String?, exitCode:Int32){
        let task = Task()
        task.currentDirectoryPath = dir
        task.launchPath = command
        task.arguments = args
        
        let outpipe = Pipe()
        task.standardOutput = outpipe
        let errpipe = Pipe()
        task.standardError = errpipe
        task.launch()
        
        let outData = outpipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errpipe.fileHandleForReading.readDataToEndOfFile()
        var outStr = String(data: outData, encoding: String.Encoding.utf8)
        if errData.count > 0 {
            outStr = String(data: errData, encoding: String.Encoding.utf8)
        }
        
        task.waitUntilExit()
        let status = task.terminationStatus
        if status > 0 { print("Error : \(outStr!)") }
        
        return (outStr, status)
    }
    
    subscript(index: Int) -> Branch? {
        get {
            if index >= 0 && index < self.branches?.count { return self.branches?[index] }
            else { return nil }
        }
    }
}

