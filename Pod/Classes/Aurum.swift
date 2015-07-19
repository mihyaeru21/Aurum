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
        self.requestHandler     = ProductsRequestHandler()
        self.transactionHandler = PaymentTransactionHandler()

        weak var weak_self = self
        self.requestHandler?.request(productIds: Set([productId]),
            onSuccess: { (products, invalidIds) in
                if (invalidIds.count > 0) {
                    // TODO: hookが欲しい？
                    return
                }

                // FIXME: ひとまず1個だけ対応
                let product = products[0]
                weak_self?.transactionHandler?.purchase(
                    product: product,
                    onSuccess: { (transaction, message) in
                        if let succeed = weak_self?.onSuccess { succeed() }
                    },
                    onFailure: { (transaction, message) in
                        if let fail = weak_self?.onFailure { fail() }
                    },
                    verify: weak_self?.verify
                )

            },
            onFailure: { _ in
                if let fail = weak_self?.onFailure { fail() }
            }
        )
    }

    public func fix() {
        self.transactionHandler = PaymentTransactionHandler()
        weak var weak_self = self
        self.transactionHandler?.fix(
            onSuccess: { (transaction, message) in
                if let succeed = weak_self?.onSuccess { succeed() }
            },
            onFailure: { (transaction, message) in
                if let fail = weak_self?.onFailure { fail() }
            }
        )
    }
}
