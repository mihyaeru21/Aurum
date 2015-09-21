//
//  PaymentTransactionHandler.swift
//  Pods
//
//  Created by Mihyaeru on 7/19/15.
//
//

import StoreKit

public class PaymentTransactionHandler : NSObject {
    public typealias TransactionHookType = (SKPaymentTransaction, String?) -> ()
    public typealias VerifyHookType      = (PaymentTransactionHandler, SKPaymentTransaction, String) -> ()

    public var onSuccess  : TransactionHookType?
    public var onRestored : TransactionHookType?
    public var onFailure  : TransactionHookType?
    public var onCanceled : TransactionHookType?
    public var verify     : VerifyHookType?

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

        super.init()
    }

    public func purchase(product product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }

    public func startObserving() {
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }

    public func finish(transaction transaction: SKPaymentTransaction, isSuccess: Bool, canFinish: Bool, message: String? = nil) {
        if canFinish {
            SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        }

        if isSuccess {
            if transaction.transactionState == SKPaymentTransactionState.Restored, let restore = self.onRestored {
                restore(transaction, message)
            }
            else {
                self.onSuccess?(transaction, message)
            }
        }
        else {
            if transaction.error?.code == SKErrorPaymentCancelled, let cancel = self.onCanceled {
                cancel(transaction, message)
            }
            else {
                self.onFailure?(transaction, message)
            }
        }
    }
}

extension PaymentTransactionHandler : SKPaymentTransactionObserver {
    public func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .Restored: fallthrough
            case .Purchased:
                if let verify = self.verify {
                    if let url = NSBundle.mainBundle().appStoreReceiptURL, let receiptData = NSData.init(contentsOfURL: url) {
                       let receipt = receiptData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.init(rawValue: 0))
                        verify(self, transaction, receipt)
                    }
                    // FIXME: レシートが無いのはおかしい
                }
                else {
                    self.finish(transaction: transaction, isSuccess: true, canFinish: true, message: "no_verifying")
                }
            case .Failed:
                self.finish(transaction: transaction, isSuccess: false, canFinish: true)
            case .Purchasing:
                break
            default:
                break
            }
        }
    }
}
