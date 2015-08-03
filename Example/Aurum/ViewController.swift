//
//  ViewController.swift
//  Aurum
//
//  Created by Mihyaeru on 07/18/2015.
//  Copyright (c) 2015 Mihyaeru. All rights reserved.
//

import UIKit
import Aurum

class ViewController: UIViewController {
    // replace your product ids
    private let validProductId1  = "com.mihyaeru.Aurum.item.1"
    private let validProductId2  = "com.mihyaeru.Aurum.item.2"
    private let invalidProductId = "com.mihyaeru.Aurum.item.invalid"

    private let aurum = Aurum.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        self.aurum.onStarted  = { (_, _) in println("start") }
        self.aurum.onFailure  = { error in println("failure with error: \(error)") }
        self.aurum.onCanceled = { println("cancel") }
        self.aurum.onTimeout  = { println("timeout") }
        self.aurum.onSuccess  = { println("success") }
        self.aurum.verify = { (transactionHandler, transaction, receipt) in
            println("verify for transaction: \(transaction)")
            // make success!
            transactionHandler.finish(transaction: transaction, isSuccess: true)
        }
    }

    @IBAction func buyValidItem1() {
        self.aurum.start(self.validProductId1)
    }

    @IBAction func buyValidItem2() {
        self.aurum.start(self.validProductId2)
    }

    @IBAction func buyInvalidItem() {
        self.aurum.start(self.invalidProductId)
    }

    @IBAction func fix() {
        self.aurum.fix()
    }
}

