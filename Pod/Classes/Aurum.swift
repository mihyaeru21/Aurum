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
    public typealias OnSuccessType  = () -> ()
    public typealias OnRestoredType = () -> ()
    public typealias OnFailureType  = (NSError?) -> ()
    public typealias OnCanceledType = () -> ()
    public typealias OnTimeoutType  = () -> ()

    public var onStarted  : OnStartedType?
    public var onSuccess  : OnSuccessType?
    public var onRestored : OnRestoredType?
    public var onFailure  : OnFailureType?
    public var onCanceled : OnCanceledType?
    public var onTimeout  : OnTimeoutType?
    public var verify     : PaymentTransactionHandler.VerifyHookType?

    let requestHandler     : ProductsRequestHandler
    let transactionHandler : PaymentTransactionHandler

    private init() {
        self.requestHandler     = ProductsRequestHandler()
        self.transactionHandler = PaymentTransactionHandler()
        setupHandlers()
    }

    private func setupHandlers() {
        self.transactionHandler.onSuccess  = { [weak self] (_, _) in self?.onSuccess?()                                                    }
        self.transactionHandler.onRestored = { [weak self] (_, _) in self?.onRestored?()                                                   }
        self.transactionHandler.onFailure  = { [weak self] (transaction, _) in self?.onFailure?(transaction.error)                         }
        self.transactionHandler.onCanceled = { [weak self] (_, _) in self?.onCanceled?()                                                   }
        self.transactionHandler.verify     = { [weak self] (handler, transaction, receipt) in self?.verify?(handler, transaction, receipt) }

        self.requestHandler.onStarted = { [weak self] (productIds, request) in self?.onStarted?(productIds, request) }
        self.requestHandler.onFailure = { [weak self] (error) in self?.onFailure?(error)                             }
        self.requestHandler.onSuccess = { [weak self] (products) in
            let product = products[0]  // FIXME: ひとまず1個だけ対応
            self?.transactionHandler.purchase(product: product)
        }
    }

    public func start(productId: String) {
        if SKPaymentQueue.canMakePayments() {
            self.requestHandler.request(productIds: Set([productId]))
        }
        else {
            self.onFailure?(NSError(domain: Aurum.ErrorDomain, code: Error.CannotMakePayments.rawValue, userInfo:nil))
        }
    }

    // this method shoud be called during application initialization
    public func startObserving() {
        self.transactionHandler.startObserving()
    }
}
