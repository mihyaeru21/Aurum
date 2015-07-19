//
//  PaymentTransactionHandlerSpec.swift
//  Aurum
//
//  Created by Mihyaeru on 7/19/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import StoreKit
import Quick
import Nimble
import Aurum

private var dummyAddObserver    : () -> () = {}
private var dummyRemoveObserver : () -> () = {}
private var dummyAddPayment     : () -> () = {}
private var dummyFinish         : () -> () = {}
class DummyQueue : SKPaymentQueue {
    override func addTransactionObserver(observer: SKPaymentTransactionObserver!) { dummyAddObserver() }
    override func removeTransactionObserver(observer: SKPaymentTransactionObserver!) { dummyRemoveObserver() }
    override func addPayment(payment: SKPayment!) { dummyAddPayment() }
    override func finishTransaction(transaction: SKPaymentTransaction!) { dummyFinish() }
}

class DummyTransaction: SKPaymentTransaction {
    var state : SKPaymentTransactionState?
    override var transactionState : SKPaymentTransactionState { get { return self.state! } }
    var e : NSError?
    override var error : NSError { get { return self.e! } }
}


class PaymentTransactionHandlerSpec: QuickSpec {
    override func spec() {
        // singletonは、overrideして先にインスタンスを作っちゃえばsuperに勝てる
        DummyQueue.defaultQueue()
        let handler = PaymentTransactionHandler()

        describe("purchase") {
            it ("calls SKPaymentQueue#addTransactionObserver") {
                var called = 0
                dummyAddObserver = { called++ }
                handler.purchase(product: SKProduct())
                expect(called) == 1
            }

            it("calls SKPaymentQueue#addPayment") {
                var called = 0
                dummyAddPayment = { called++ }
                handler.purchase(product: SKProduct())
                expect(called) == 1
            }
        }

        describe("finish") {
            let transaction = DummyTransaction()

            context("when state is success") {
                it("calls SKPaymentQueue#finish") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Purchased
                    dummyFinish = { called++ }
                    handler.finish(transaction: transaction, isSuccess: true, message: nil)
                    expect(called) == 1
                }

                it("sets willFinish to true") {
                    transaction.state = SKPaymentTransactionState.Purchased
                    handler.finish(transaction: transaction, isSuccess: true, message: nil)
                    expect(handler.willFinish) == true
                }

                it("calls onRestored if state is restored and handler has onRestored") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Restored
                    handler.onRestored = { (_, _) in called++ }
                    handler.finish(transaction: transaction, isSuccess: true, message: nil)
                    expect(called) == 1
                }

                it("calls onSuccess if state is restored and handler doesn't have onRestored") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Restored
                    handler.onRestored = nil
                    handler.onSuccess  = { (_, _) in called++ }
                    handler.finish(transaction: transaction, isSuccess: true, message: nil)
                    expect(called) == 1
                }

                it("calls onSuccess if state isn't restored") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Purchased
                    handler.onSuccess  = { (_, _) in called++ }
                    handler.finish(transaction: transaction, isSuccess: true, message: nil)
                    expect(called) == 1
                }
            }

            context("when state is failure") {
                it("doesn't call SKPaymentQueue#finish") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Failed
                    transaction.e     = NSError(domain: SKErrorDomain, code: SKErrorPaymentInvalid, userInfo: nil)
                    dummyFinish = { called++ }
                    handler.finish(transaction: transaction, isSuccess: false, message: nil)
                    expect(called) == 0
                }

                it("sets willFinish to true") {
                    transaction.state = SKPaymentTransactionState.Failed
                    transaction.e     = NSError(domain: SKErrorDomain, code: SKErrorPaymentCancelled, userInfo: nil)
                    handler.finish(transaction: transaction, isSuccess: false, message: nil)
                    expect(handler.willFinish) == true
                }

                it("calls onCanceled if error code is canceled and handler has onCanceled") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Failed
                    transaction.e     = NSError(domain: SKErrorDomain, code: SKErrorPaymentCancelled, userInfo: nil)
                    handler.onCanceled = { (_, _) in called++ }
                    handler.finish(transaction: transaction, isSuccess: false, message: nil)
                    expect(called) == 1
                }

                it("calls onFailure if error code is canceled and handler doesn't have onCanceled") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Failed
                    transaction.e     = NSError(domain: SKErrorDomain, code: SKErrorPaymentCancelled, userInfo: nil)
                    handler.onCanceled = nil
                    handler.onFailure  = { (_, _) in called++ }
                    handler.finish(transaction: transaction, isSuccess: false, message: nil)
                    expect(called) == 1
                }

                it("calls onFailure if error code isn't canceled") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Failed
                    transaction.e     = NSError(domain: SKErrorDomain, code: SKErrorPaymentInvalid, userInfo: nil)
                    handler.onFailure  = { (_, _) in called++ }
                    handler.finish(transaction: transaction, isSuccess: false, message: nil)
                    expect(called) == 1
                }
            }
        }

        describe("paymentQueue:updatedTransactions:") {
            let transaction = DummyTransaction()

            context("when state is restored") {
                it("calls finish with success") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Restored
                    handler.onRestored = { (_, _) in called++ }
                    handler.paymentQueue(DummyQueue.defaultQueue(), updatedTransactions: [transaction])
                    expect(called) == 1
                }
            }

            context("when state is purchased") {
                it("calls finish with success") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Purchased
                    handler.onRestored = nil
                    handler.onSuccess  = { (_, _) in called++ }
                    handler.paymentQueue(DummyQueue.defaultQueue(), updatedTransactions: [transaction])
                    expect(called) == 1
                }
            }

            context("when state is failed") {
                it("calls finish with false") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Failed
                    transaction.e     = NSError(domain: SKErrorDomain, code: SKErrorPaymentInvalid, userInfo: nil)
                    handler.onFailure = { (_, _) in called++ }
                    handler.paymentQueue(DummyQueue.defaultQueue(), updatedTransactions: [transaction])
                    expect(called) == 1
                }
            }

            context("when state is purchaseing") {
                it("doesn't call finish") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Purchasing
                    handler.onSuccess = { (_, _) in called++ }
                    handler.onFailure = { (_, _) in called++ }
                    handler.paymentQueue(DummyQueue.defaultQueue(), updatedTransactions: [transaction])
                    expect(called) == 0
                }
            }

            context("when sillFinish is true") {
                it("calls SKPaymentQueue#removeTransactionObserver") {
                    var called = 0
                    dummyRemoveObserver = { called++ }
                    handler.willFinish = true
                    handler.paymentQueue(DummyQueue.defaultQueue(), updatedTransactions: [])
                    expect(called) == 1
                }
            }

            context("when sillFinish is false") {
                it("doesn't call SKPaymentQueue#removeTransactionObserver") {
                    var called = 0
                    dummyRemoveObserver = { called++ }
                    handler.willFinish = false
                    handler.paymentQueue(DummyQueue.defaultQueue(), updatedTransactions: [])
                    expect(called) == 0
                }
            }
        }
    }
}
