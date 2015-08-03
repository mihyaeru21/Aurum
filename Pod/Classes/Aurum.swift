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
    private init() {}

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

    var requestHandler     : ProductsRequestHandler?
    var transactionHandler : PaymentTransactionHandler?

    public func start(productId: String) {
        self.transactionHandler = PaymentTransactionHandler(
            onSuccess:  { [weak self] (_, _) in self?.onSuccess?() },
            onRestored: { [weak self] (_, _) in self?.onRestored?() },
            onFailure:  { [weak self] (transaction, _) in self?.onFailure?(transaction.error) },
            onCanceled: { [weak self] (_, _) in self?.onCanceled?() },
            verify: self.verify
        )
        self.requestHandler = ProductsRequestHandler(
            onStarted: self.onStarted,
            onSuccess: { [weak self] (products, invalidIds) in
                if (invalidIds.count <= 0) {
                    let product = products[0]  // FIXME: ひとまず1個だけ対応
                    self?.transactionHandler?.purchase(product: product)
                }
                else {
                    self?.onFailure?(NSError(domain: Aurum.ErrorDomain, code: Error.InvalidProductId.rawValue, userInfo:["invalidIds": invalidIds]))
                }
            },
            onFailure: { [weak self] error in
                self?.onFailure?(error)
            }
        )

        if SKPaymentQueue.canMakePayments() {
            self.requestHandler?.request(productIds: Set([productId]))
        }
        else {
            self.onFailure?(NSError(domain: Aurum.ErrorDomain, code: Error.CannotMakePayments.rawValue, userInfo:nil))
        }
    }

    public func fix() {
        self.transactionHandler = PaymentTransactionHandler(
            onSuccess:  { [weak self] (_, _) in self?.onSuccess?() },
            onRestored: { [weak self] (_, _) in self?.onRestored?() },
            onFailure:  { [weak self] (transaction, _) in self?.onFailure?(transaction.error) },
            onCanceled: { [weak self] (_, _) in self?.onCanceled?() },
            verify: self.verify
        )

        if SKPaymentQueue.canMakePayments() {
            self.transactionHandler?.fix()
        }
        else {
            self.onFailure?(NSError(domain: Aurum.ErrorDomain, code: Error.CannotMakePayments.rawValue, userInfo:nil))
        }
    }
}
