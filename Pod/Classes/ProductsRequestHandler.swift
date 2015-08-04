//
//  ProductsRequestHandler.swift
//  Pods
//
//  Created by Mihyaeru on 7/19/15.
//
//

import StoreKit

public class ProductsRequestHandler : NSObject {
    public typealias OnStartedType = (Set<String>, SKProductsRequest) -> ()
    public typealias OnSuccessType = ([SKProduct]) -> ()
    public typealias OnFailureType = (NSError?) -> ()

    public var onStarted : OnStartedType?
    public var onSuccess : OnSuccessType?
    public var onFailure : OnFailureType?

    public init(
        onStarted: OnStartedType? = nil,
        onSuccess: OnSuccessType? = nil,
        onFailure: OnFailureType? = nil
    ) {
        if (onStarted != nil) { self.onStarted = onStarted }
        if (onSuccess != nil) { self.onSuccess = onSuccess }
        if (onFailure != nil) { self.onFailure = onFailure }
        super.init()
    }

    public func request(#productIds: Set<String>) {
        let request = SKProductsRequest(productIdentifiers: productIds)
        request.delegate = self
        request.start()
        self.onStarted?(productIds, request)
    }
}

extension ProductsRequestHandler : SKProductsRequestDelegate {
    public func productsRequest(request: SKProductsRequest!, didReceiveResponse response: SKProductsResponse!) {
        let invalidIds = response.invalidProductIdentifiers as! [SKProduct]
        if (invalidIds.count > 0) {
            self.onFailure?(NSError(domain: Aurum.ErrorDomain, code: Aurum.Error.InvalidProductId.rawValue, userInfo:["invalidIds": invalidIds]))
        }
        else {
            self.onSuccess?(response.products as! [SKProduct])
        }
    }

    public func request(request: SKRequest!, didFailWithError error: NSError!) {
        self.onFailure?(error)
    }
}
