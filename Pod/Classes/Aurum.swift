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
        weak var weakSelf = self
        self.transactionHandler = PaymentTransactionHandler(
            onSuccess:  { (_, _) in weakSelf?.onSuccess?() },
            onRestored: { (_, _) in weakSelf?.onRestored?() },
            onFailure:  { (transaction, _) in weakSelf?.onFailure?(transaction.error) },
            onCanceled: { (_, _) in weakSelf?.onCanceled?() },
            verify: weakSelf?.verify
        )
        self.requestHandler = ProductsRequestHandler(
            onStarted: weakSelf?.onStarted,
            onSuccess: { (products, invalidIds) in
                if (invalidIds.count <= 0) {
                    let product = products[0]  // FIXME: ひとまず1個だけ対応
                    weakSelf?.transactionHandler?.purchase(product: product)
                }
                else {
                    weakSelf?.onFailure?(NSError(domain: Aurum.ErrorDomain, code: Error.InvalidProductId.rawValue, userInfo:["invalidIds": invalidIds]))
                }
            },
            onFailure: { error in
                weakSelf?.onFailure?(error)
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
        weak var weakSelf = self
        self.transactionHandler = PaymentTransactionHandler(
            onSuccess:  { (_, _) in weakSelf?.onSuccess?() },
            onRestored: { (_, _) in weakSelf?.onRestored?() },
            onFailure:  { (transaction, _) in weakSelf?.onFailure?(transaction.error) },
            onCanceled: { (_, _) in weakSelf?.onCanceled?() },
            verify: weakSelf?.verify
        )

        if SKPaymentQueue.canMakePayments() {
            self.transactionHandler?.fix()
        }
        else {
            self.onFailure?(NSError(domain: Aurum.ErrorDomain, code: Error.CannotMakePayments.rawValue, userInfo:nil))
        }
    }
}
