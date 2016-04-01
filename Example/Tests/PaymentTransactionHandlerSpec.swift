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
    override func addTransactionObserver(observer: SKPaymentTransactionObserver) { dummyAddObserver() }
    override func removeTransactionObserver(observer: SKPaymentTransactionObserver) { dummyRemoveObserver() }
    override func addPayment(payment: SKPayment) { dummyAddPayment() }
    override func finishTransaction(transaction: SKPaymentTransaction) { dummyFinish() }
}

class DummyTransaction: SKPaymentTransaction {
    var state : SKPaymentTransactionState?
    override var transactionState : SKPaymentTransactionState { get { return self.state! } }
    var e : NSError?
    override var error : NSError? { get { return self.e! } }
}

class PaymentTransactionHandlerSpec: QuickSpec {
    override func spec() {
        // singletonは、overrideして先にインスタンスを作っちゃえばsuperに勝てる
        DummyQueue.defaultQueue()
        let handler = PaymentTransactionHandler()

        describe("purchase") {
            it("calls SKPaymentQueue#addPayment") {
                var called = 0
                dummyAddPayment = { called += 1 }
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
                    dummyFinish = { called += 1 }
                    handler.finish(transaction: transaction, isSuccess: true, canFinish: true, message: nil)
                    expect(called) == 1
                }

                it("calls onRestored if state is restored and handler has onRestored") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Restored
                    handler.onRestored = { (_, _) in called += 1 }
                    handler.finish(transaction: transaction, isSuccess: true, canFinish: true, message: nil)
                    expect(called) == 1
                }

                it("calls onSuccess if state is restored and handler doesn't have onRestored") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Restored
                    handler.onRestored = nil
                    handler.onSuccess  = { (_, _) in called += 1 }
                    handler.finish(transaction: transaction, isSuccess: true, canFinish: true, message: nil)
                    expect(called) == 1
                }

                it("calls onSuccess if state isn't restored") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Purchased
                    handler.onSuccess  = { (_, _) in called += 1 }
                    handler.finish(transaction: transaction, isSuccess: true, canFinish: true, message: nil)
                    expect(called) == 1
                }
            }

            context("when state is failure") {
                it("doesn't call SKPaymentQueue#finish if canFinish is also false") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Failed
                    transaction.e     = NSError(domain: SKErrorDomain, code: SKErrorCode.PaymentInvalid.rawValue, userInfo: nil)
                    dummyFinish = { called += 1 }
                    handler.finish(transaction: transaction, isSuccess: false, canFinish: false, message: nil)
                    expect(called) == 0
                }

                it("calls SKPaymentQueue#finish if canFinish is true") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Failed
                    transaction.e     = NSError(domain: SKErrorDomain, code: SKErrorCode.PaymentInvalid.rawValue, userInfo: nil)
                    dummyFinish = { called += 1 }
                    handler.finish(transaction: transaction, isSuccess: false, canFinish: true, message: nil)
                    expect(called) == 1
                }

                it("calls onCanceled if error code is canceled and handler has onCanceled") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Failed
                    transaction.e     = NSError(domain: SKErrorDomain, code: SKErrorCode.PaymentCancelled.rawValue, userInfo: nil)
                    handler.onCanceled = { (_, _) in called += 1 }
                    handler.finish(transaction: transaction, isSuccess: false, canFinish: true, message: nil)
                    expect(called) == 1
                }

                it("calls onFailure if error code is canceled and handler doesn't have onCanceled") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Failed
                    transaction.e     = NSError(domain: SKErrorDomain, code: SKErrorCode.PaymentCancelled.rawValue, userInfo: nil)
                    handler.onCanceled = nil
                    handler.onFailure  = { (_, _) in called += 1 }
                    handler.finish(transaction: transaction, isSuccess: false, canFinish: true, message: nil)
                    expect(called) == 1
                }

                it("calls onFailure if error code isn't canceled") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Failed
                    transaction.e     = NSError(domain: SKErrorDomain, code: SKErrorCode.PaymentInvalid.rawValue, userInfo: nil)
                    handler.onFailure  = { (_, _) in called += 1 }
                    handler.finish(transaction: transaction, isSuccess: false, canFinish: true, message: nil)
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
                    handler.onRestored = { (_, _) in called += 1 }
                    handler.paymentQueue(DummyQueue.defaultQueue(), updatedTransactions: [transaction])
                    expect(called) == 1
                }
            }

            context("when state is purchased") {
                it("calls finish with success") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Purchased
                    handler.onRestored = nil
                    handler.onSuccess  = { (_, _) in called += 1 }
                    handler.paymentQueue(DummyQueue.defaultQueue(), updatedTransactions: [transaction])
                    expect(called) == 1
                }
            }

            context("when state is failed") {
                it("calls finish with false") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Failed
                    transaction.e     = NSError(domain: SKErrorDomain, code: SKErrorCode.PaymentInvalid.rawValue, userInfo: nil)
                    handler.onFailure = { (_, _) in called += 1 }
                    handler.paymentQueue(DummyQueue.defaultQueue(), updatedTransactions: [transaction])
                    expect(called) == 1
                }
            }

            context("when state is purchaseing") {
                it("doesn't call finish") {
                    var called = 0
                    transaction.state = SKPaymentTransactionState.Purchasing
                    handler.onSuccess = { (_, _) in called += 1 }
                    handler.onFailure = { (_, _) in called += 1 }
                    handler.paymentQueue(DummyQueue.defaultQueue(), updatedTransactions: [transaction])
                    expect(called) == 0
                }
            }
        }
    }
}
