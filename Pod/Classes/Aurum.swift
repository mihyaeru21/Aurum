//
//  Aurum.swift
//  Pods
//
//  Created by Mihyaeru on 7/18/15.
//
//

import Foundation

public class Aurum {
    public static let sharedInstance = Aurum()
    private init() {}

    public typealias OnStartedType  = ProductsRequestHandler.OnStartedType
    public typealias OnSuccessType  = () -> ()
    public typealias OnRestoredType = () -> ()
    public typealias OnFailureType  = (NSError) -> ()
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

    public func start(productId: NSString) {
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
                if (invalidIds.count > 0) { return } // TODO: hookが欲しい？
                let product = products[0]            // FIXME: ひとまず1個だけ対応
                weakSelf?.transactionHandler?.purchase(product: product)
            },
            onFailure: {
                error in weakSelf?.onFailure?(error)
            }
        )
        self.requestHandler?.request(productIds: Set([productId]))
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
        self.transactionHandler?.fix()
    }
}
