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
    private init() {
    }

    public typealias CallbackType = () -> ()

    public var verify    : PaymentTransactionHandler.VerifyHookType?
    public var onSuccess : CallbackType?
    public var onFailure : CallbackType?

    var requestHandler     : ProductsRequestHandler?
    var transactionHandler : PaymentTransactionHandler?

    public func start(productId: NSString) {
        weak var weakSelf = self

        self.transactionHandler = PaymentTransactionHandler(
            onSuccess: { (transaction, message) in
                if let succeed = weakSelf?.onSuccess { succeed() }
            },
            onFailure: { (transaction, message) in
                if let fail = weakSelf?.onFailure { fail() }
            },
            verify: weakSelf?.verify
        )

        self.requestHandler = ProductsRequestHandler(
            onSuccess: { (products, invalidIds) in
                // TODO: hookが欲しい？
                if (invalidIds.count > 0) { return }
                // FIXME: ひとまず1個だけ対応
                let product = products[0]
                weakSelf?.transactionHandler?.purchase(product: product)
            },
            onFailure: { _ in
                if let fail = weakSelf?.onFailure { fail() }
            }
        )

        self.requestHandler?.request(productIds: Set([productId]))
    }

    public func fix() {
        self.transactionHandler = PaymentTransactionHandler()
        self.transactionHandler?.fix()
    }
}
