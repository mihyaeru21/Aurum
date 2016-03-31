//
//  ProductsRequestHandlerSpec.swift
//  Aurum
//
//  Created by Mihyaeru on 7/19/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import StoreKit
import Quick
import Nimble
import Aurum

private var dummyStart : () -> () = {}
extension SKProductsRequest {
    override public func start() { dummyStart() }
}

class DummyResponse: SKProductsResponse {
    override var products : [SKProduct] { get { return [] } }
    override var invalidProductIdentifiers : [String] { get{ return [] } }

    override init() {
        super.init()
    }
}


class ProductsRequestHandlerSpec: QuickSpec {
    override func spec() {
        let handler = ProductsRequestHandler()

        describe("request") {
            it ("calls SKProcuctsRequest#start") {
                var called = 0
                dummyStart = { called += 1 }
                handler.request(productIds: Set(["hoge_id"]))
                expect(called) == 1
            }

            it("calls onStarted callback") {
                var called = 0
                handler.onStarted = { (_, _) in called += 1 }
                handler.request(productIds: Set(["hoge_id"]))
                expect(called) == 1
            }
        }

        describe("productsRequest:didReceiveResponse:") {
            it("calls onSuccess callback") {
                var called = 0
                handler.onSuccess = { _ in called += 1 }
                handler.productsRequest(SKProductsRequest(productIdentifiers: Set([])), didReceiveResponse: DummyResponse())
                expect(called) == 1
            }
        }

        describe("request:didFailWithError:") {
            it("calls onFailure callback") {
                var called = 0
                handler.onFailure = { _ in called += 1 }
                handler.request(SKProductsRequest(productIdentifiers: Set([])), didFailWithError: NSError(domain: Aurum.ErrorDomain, code: Aurum.Error.InvalidProductId.rawValue, userInfo: [:] as [NSObject: AnyObject]))
                expect(called) == 1
            }
        }
    }
}
