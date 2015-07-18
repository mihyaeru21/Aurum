//
//  ProductsRequestHandler.swift
//  Pods
//
//  Created by Mihyaeru on 7/19/15.
//
//

import StoreKit

public class ProductsRequestHandler : NSObject {
    public typealias OnStartedType = (Set<NSString>, SKProductsRequest) -> ()
    public typealias OnSuccessType = ([SKProduct], [SKProduct]) -> ()
    public typealias OnFailureType = (NSError) -> ()

    public var onSuccess : OnSuccessType?
    public var onFailure : OnFailureType?

    public override init() {
        super.init()
    }

    public func request(
        #productIds: Set<NSString>,
        onStarted: OnStartedType? = nil,
        onSuccess: OnSuccessType? = nil,
        onFailure: OnFailureType? = nil
    ) {
        if (onSuccess != nil) { self.onSuccess = onSuccess }
        if (onFailure != nil) { self.onFailure = onFailure }

        let request = SKProductsRequest(productIdentifiers: productIds)
        request.delegate = self
        request.start()

        onStarted?(productIds, request)
    }
}

extension ProductsRequestHandler : SKProductsRequestDelegate {
    public func productsRequest(request: SKProductsRequest!, didReceiveResponse response: SKProductsResponse!) {
        if let onSuccess = self.onSuccess {
            onSuccess(
                response.products as! [SKProduct],
                response.invalidProductIdentifiers as! [SKProduct]
            )
        }
    }

    public func request(request: SKRequest!, didFailWithError error: NSError!) {
        if let onFailure = self.onFailure {
            onFailure(error)
        }
    }
}
