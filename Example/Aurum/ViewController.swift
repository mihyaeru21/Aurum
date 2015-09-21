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
    private var verifySuccess = true {
        didSet {
            let str = self.verifySuccess ? "Success" : "Failure"
            self.verifyToggleButton.setTitle("Verify: " + str, forState: UIControlState.Normal)
            self.verifyToggleButton.setTitle("Verify: " + str, forState: UIControlState.Highlighted)
        }
    }

    @IBOutlet weak var verifyToggleButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.aurum.onStarted  = { (_, _) in println("start") }
        self.aurum.onFailure  = { _, error, _ in println("failure with error: \(error)") }
        self.aurum.onCanceled = { _, _ in println("cancel") }
        self.aurum.verify = { (transactionHandler, transaction, receipt) in
            println("verify for transaction: \(transaction) will \(self.verifySuccess)")
            transactionHandler.finish(transaction: transaction, isSuccess: self.verifySuccess, canFinish: self.verifySuccess)
        }
        self.aurum.onSuccess = { transaction, _ in
            if let product = self.aurum.getProductFromCache(transaction.payment.productIdentifier) {
                println("success: id: \(product.productIdentifier), price: \(product.price), locale: \(product.priceLocale)")
            }
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

    @IBAction func addTransactionObserver(sender: AnyObject) {
        // in general, this method shoud be called during application initialization
        self.aurum.startObserving()
    }

    @IBAction func toggleVerifySuccess() {
        self.verifySuccess = !self.verifySuccess
    }
}

