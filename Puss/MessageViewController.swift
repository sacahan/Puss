//
//  MessageViewController.swift
//  Puss
//
//  Created by Brian Han on 2016/7/8.
//  Copyright © 2016年 Brian Han. All rights reserved.
//

import Cocoa

class MessageViewController: NSViewController {

    @IBOutlet weak var messageLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.messageLabel.stringValue = representedObject as! String
    }
}
