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
    weak var viewController: ViewController?
    var branches: [Branch]?
    var git: String?
    
    var repoPath: String? {
        didSet { self.doBranchList() }
    }
    
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
        
        self.viewController?.tableView?.reloadData()
    }
    
    func doRemotePush() {
        DispatchQueue.global(attributes: .qosBackground).async {
            for branch in self.branches! {
                if branch.isDelete {
                    let (delete, _) = self.runCommand(dir: self.repoPath!, command: self.git!, args: "push", "origin", ":" + branch.local)
                    print("\(delete!)")
                }
                
                if branch.isPush {
                    let (push, _) = self.runCommand(dir: self.repoPath!, command: self.git!, args: "push", "origin", branch.local + ":" + branch.local)
                    print("\(push!)")
                }
                
                DispatchQueue.main.async {
                    self.viewController?.loading.increment(by: 1)
                }
            }
            
            DispatchQueue.main.async {
                self.viewController?.loading.stopAnimation(self)
                self.viewController?.loading.isHidden = true
                self.doBranchList()
            }
        }
    }
    
    func doBranchCheckout(branch: Branch) {
        DispatchQueue.global(attributes: .qosBackground).async {
            let (checkout, s0) = self.runCommand(dir: self.repoPath!, command: self.git!, args: "checkout", branch.local)
            if s0 > 0 {
                print("Error: \(checkout!) (code: \(s0))")
            }
            
            DispatchQueue.main.async {
                self.doBranchList()
            }
        }
    }
    
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

