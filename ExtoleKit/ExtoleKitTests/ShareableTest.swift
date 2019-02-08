//
//  ShareableTest.swift
//  firstappTests
//
//  Created by rtibin on 1/25/19.
//  Copyright © 2019 rtibin. All rights reserved.
//

import XCTest

@testable import ExtoleKit

class ShareableTest: XCTestCase {

    let program = Program(baseUrl: URL.init(string: "https://roman-tibin-test.extole.com")!)
    var accessToken: ConsumerToken?
    
    override func setUp() {
        let promise = expectation(description: "invalid token response")
        program.getToken() { token, error in
            XCTAssert(token != nil)
            XCTAssert(!token!.access_token.isEmpty)
            self.accessToken = token
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }


    func testCreateWithCode() {
        let newShareable = MyShareable.init(label: "refer-a-friend")
        let shareableResponse = program.createShareable(accessToken: accessToken!,
                                                        shareable: newShareable)
        let shareableResult = shareableResponse.await(timeout: DispatchTime.now() + .seconds(10))
        XCTAssertGreaterThan(shareableResult!.polling_id, "111111")
        
        let pollingResult = program.pollShareable(accessToken: accessToken!,
                                                  pollingResponse: shareableResult!)
            .await(timeout: DispatchTime.now() + .seconds(10))
        let shareableCode = pollingResult!.code!
        
        XCTAssertGreaterThan(shareableCode, "1111")
        XCTAssertEqual(pollingResult?.status, "SUCCEEDED")
        
        let shareablesResponse = program.getShareables(accessToken: accessToken!)
            .await(timeout: DispatchTime.now() + .seconds(10))
        XCTAssertNotNil(shareablesResponse)
        XCTAssertEqual(1, shareablesResponse?.count)
        XCTAssertEqual("refer-a-friend", shareablesResponse?.first?.label)
        
        let duplicateShareable = MyShareable(label:"refer-a-friend", code: shareableCode)
        
        let duplicateShareableResponse = program.createShareable(accessToken: accessToken!, shareable: duplicateShareable)
            .await(timeout: DispatchTime.now() + .seconds(10))
        
        let duplicatePollingResult = program.pollShareable(accessToken: accessToken!,
                                                           pollingResponse: duplicateShareableResponse!)
            .await(timeout: DispatchTime.now() + .seconds(10))
        XCTAssertEqual(duplicatePollingResult?.status, "FAILED")
        
    }

}