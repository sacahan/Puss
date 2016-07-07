//
//  ViewController.swift
//  Git Multi-Push
//
//  Created by Brian Han on 2016/6/25.
//  Copyright © 2016年 Brian Han. All rights reserved.
//

import Cocoa
import AppKit

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var pathTextField: NSTextField!
    @IBOutlet weak var loading: NSProgressIndicator!
    var helper = GitHelper()
    static var deleteSelectAll: Bool = false
    static var pushSelectAll: Bool = false
    
    // MARK: NSViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        self.helper.viewController = self
        self.loading.isHidden = true
    }

    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    // MARK: NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let branches = self.helper.branches else { return 0 }
        return branches.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        guard let branches = self.helper.branches else { return nil }
        guard branches.count > 0 else { return nil }
        
        switch tableColumn!.identifier {
            case "head":
                return branches[row].head
            case "local":
                return branches[row].local
            case "hash":
                return branches[row].hash
            case "comment":
                return branches[row].comment
            case "delete":
                return branches[row].isDelete
            case "push":
                return branches[row].isPush
            default:
                return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return self.helper[row]?.head != "*"
    }
    
    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        return false
    }
    
    // MARK: NSTableViewDelegate
    func tableView(_ tableView: NSTableView, mouseDownInHeaderOf tableColumn: NSTableColumn) {
        guard let branches = self.helper.branches else {
            return
        }
        
        switch tableColumn.identifier {
            case "delete":
                ViewController.deleteSelectAll = !ViewController.deleteSelectAll
                for branch in branches {
                    branch.isDelete = ViewController.deleteSelectAll
                }
            case "push":
                ViewController.pushSelectAll = !ViewController.pushSelectAll
                for branch in branches {
                    branch.isPush = ViewController.pushSelectAll
                }
            default:
                return
        }
    }
    
    @IBAction func deleteCheck(_ sender: AnyObject) {
        guard let branch = self.helper[sender.selectedRow] else {
            return
        }
        branch.isDelete = !branch.isDelete
    }
    
    @IBAction func pushCheck(_ sender: AnyObject) {
        guard let branch = self.helper[sender.selectedRow] else {
            return
        }
        branch.isPush = !branch.isPush
    }

    @IBAction func doDoubleClick(_ sender: NSTableView) {
        guard let branch = self.helper[sender.selectedRow] else {
            return
        }
        self.helper.doBranchCheckout(branch: branch)
    }
    
    // MARK: Directory
    @IBAction func doRepoPick(_ sender: NSButton) {
        let repoPicker: NSOpenPanel = NSOpenPanel()
        repoPicker.allowsMultipleSelection = false
        repoPicker.canChooseDirectories = true
        repoPicker.canChooseFiles = false
        repoPicker.runModal()
        
        if var path = repoPicker.url?.absoluteString {
            self.pathTextField!.stringValue = path
            //Remove "file://"
            path = path.substring(from: path.index(path.startIndex, offsetBy: 7))
            self.helper.repoPath = path
        }
    }
    
    @IBAction func doGitAction(_ sender: NSButton) {
        guard let branches = self.helper.branches else {
            return
        }
        
        DispatchQueue.main.async {
            self.loading.minValue = 0
            self.loading.maxValue = Double(branches.count)
            self.loading.doubleValue = 0
            self.loading.isHidden = false
            self.loading.startAnimation(self)
        }
        self.helper.doRemotePush()
    }
}

