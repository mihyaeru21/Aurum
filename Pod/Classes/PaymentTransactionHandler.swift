//
//  PaymentTransactionHandler.swift
//  Pods
//
//  Created by Mihyaeru on 7/19/15.
//
//

import StoreKit

public class PaymentTransactionHandler : NSObject {
    public typealias TransactionHookType = (SKPaymentTransaction, NSString?) -> ()
    public typealias VerifyHookType      = (PaymentTransactionHandler, SKPaymentTransaction, NSString) -> ()

    public var onSuccess  : TransactionHookType?
    public var onRestored : TransactionHookType?
    public var onFailure  : TransactionHookType?
    public var onCanceled : TransactionHookType?
    public var verify     : VerifyHookType?

    public var willFinish : Bool

    public init(
        onSuccess:  TransactionHookType? = nil,
        onRestored: TransactionHookType? = nil,
        onFailure:  TransactionHookType? = nil,
        onCanceled: TransactionHookType? = nil,
        verify:     VerifyHookType?      = nil
    ) {
        if (onSuccess  != nil) { self.onSuccess  = onSuccess  }
        if (onRestored != nil) { self.onRestored = onRestored }
        if (onFailure  != nil) { self.onFailure  = onFailure  }
        if (onCanceled != nil) { self.onCanceled = onCanceled }
        if (verify     != nil) { self.verify     = verify     }

        self.willFinish = false
        super.init()
    }

    public func purchase(#product: SKProduct) {
        let queue = SKPaymentQueue.defaultQueue()
        queue.addTransactionObserver(self)
        queue.addPayment(SKPayment(product: product))
    }

    public func fix() {
        let queue = SKPaymentQueue.defaultQueue()
        queue.addTransactionObserver(self)
    }

    public func finish(#transaction: SKPaymentTransaction, isSuccess: Bool, message: NSString? = nil) {
        if isSuccess {
            SKPaymentQueue.defaultQueue().finishTransaction(transaction)
            if transaction.transactionState == SKPaymentTransactionState.Restored, let restore = self.onRestored {
                restore(transaction, message)
            }
            else if let succeed = self.onSuccess {
                succeed(transaction, message)
            }
        }
        else {
            if transaction.error.code == SKErrorPaymentCancelled, let cancel = self.onCanceled {
                cancel(transaction, message)
            }
            else if let fail = self.onFailure {
                fail(transaction, message)
            }
        }

        self.willFinish = true
    }
}

extension PaymentTransactionHandler : SKPaymentTransactionObserver {
    public func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!) {
        for transaction in transactions as! [SKPaymentTransaction] {
            switch transaction.transactionState {
            case .Restored: fallthrough
            case .Purchased:
                if let verify = self.verify {
                    let url = NSBundle.mainBundle().appStoreReceiptURL
                    let receipt = NSData.init(contentsOfURL: url!)
                    let receiptString = receipt!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.init(0))
                    verify(self, transaction, receiptString)
                }
                else {
                    self.finish(transaction: transaction, isSuccess: true, message: "no_verifying")
                }
            case .Failed:
                self.finish(transaction: transaction, isSuccess: false)
            case .Purchasing:
                break
            default:
                break
            }
        }

        if self.willFinish {
            queue.removeTransactionObserver(self)
        }
    }
}
