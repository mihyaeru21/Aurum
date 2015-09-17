//
//  Aurum.swift
//  Pods
//
//  Created by Mihyaeru on 7/18/15.
//
//

import Foundation
import StoreKit

public class Aurum {
    public static let sharedInstance = Aurum()

    // for error
    public static let ErrorDomain = "com.mihyaeru.Aurum"
    public enum Error : Int {
        case CannotMakePayments = 1
        case InvalidProductId   = 2
    }

    public typealias OnStartedType  = ProductsRequestHandler.OnStartedType
    public typealias OnSuccessType  = PaymentTransactionHandler.TransactionHookType
    public typealias OnRestoredType = PaymentTransactionHandler.TransactionHookType
    public typealias OnCanceledType = PaymentTransactionHandler.TransactionHookType
    public typealias OnFailureType  = (SKPaymentTransaction?, NSError?, NSString?) -> ()   // transaction.error may be nil when transaction.state was Failed

    public var onStarted  : OnStartedType?
    public var onSuccess  : OnSuccessType?
    public var onRestored : OnRestoredType?
    public var onFailure  : OnFailureType?
    public var onCanceled : OnCanceledType?
    public var verify     : PaymentTransactionHandler.VerifyHookType?

    let requestHandler     : ProductsRequestHandler
    let transactionHandler : PaymentTransactionHandler

    private init() {
        self.requestHandler     = ProductsRequestHandler()
        self.transactionHandler = PaymentTransactionHandler()
        setupHandlers()
    }

    private func setupHandlers() {
        self.transactionHandler.onSuccess  = { self.onSuccess?($0, $1)  }
        self.transactionHandler.onRestored = { self.onRestored?($0, $1) }
        self.transactionHandler.onCanceled = { self.onCanceled?($0, $1) }
        self.transactionHandler.verify     = { self.verify?($0, $1, $2) }
        self.transactionHandler.onFailure  = { transaction, message in self.onFailure?(transaction, transaction.error, message) }

        self.requestHandler.onStarted = { (productIds, request) in self.onStarted?(productIds, request) }
        self.requestHandler.onFailure = { (error) in self.onFailure?(nil, error, nil)                   }
        self.requestHandler.onSuccess = { (products) in
            let product = products[0]  // FIXME: ひとまず1個だけ対応
            self.transactionHandler.purchase(product: product)
        }
    }

    public func start(productId: String) {
        if SKPaymentQueue.canMakePayments() {
            self.requestHandler.request(productIds: Set([productId]))
        }
        else {
            self.onFailure?(nil, NSError(domain: Aurum.ErrorDomain, code: Error.CannotMakePayments.rawValue, userInfo:nil), nil)
        }
    }

    // this method shoud be called during application initialization
    public func startObserving() {
        self.transactionHandler.startObserving()
    }
}
