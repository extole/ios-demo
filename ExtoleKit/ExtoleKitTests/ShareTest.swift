//
//  ShareTest.swift
//  firstappTests
//
//  Created by rtibin on 1/25/19.
//  Copyright © 2019 rtibin. All rights reserved.
//

import XCTest

@testable import ExtoleKit

class ShareTest: XCTestCase {

    let program = Program(baseUrl: URL.init(string: "https://roman-tibin-test.extole.com")!)
    var accessToken: ConsumerToken?
    var advocateCode: String?
    
    override func setUp() {
        let promise = expectation(description: "invalid token response")
        program.getToken() { token, error in
            XCTAssert(token != nil)
            XCTAssert(!token!.access_token.isEmpty)
            self.accessToken = token
            promise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        let newShareable = MyShareable.init(label: "refer-a-friend")
        let shareableResponse = program.createShareable(accessToken: accessToken!,
                                                        shareable: newShareable)
        let shareableResult = shareableResponse.await(timeout: DispatchTime.now() + .seconds(10))
        XCTAssertGreaterThan(shareableResult!.polling_id, "111111")
        
        let pollingResult = program.pollShareable(accessToken: accessToken!,
                                                  pollingResponse: shareableResult!)
            .await(timeout: DispatchTime.now() + .seconds(10))
        advocateCode = pollingResult!.code!
    }
    
    func testCustomShare() {
        let customShare = CustomShare(advocate_code: advocateCode!,
                                      channel: "test",
                                      message: "testmessage",
                                      recipient_email: "rtibin@extole.com",
                                      data: [:])
        
        let shareExpectation = expectation(description: "share")
        var sharePollingId : PollingIdResponse!
        program.customShare(accessToken : accessToken!, share: customShare) {
            shareResponse, error in
            if let error = error {
                XCTFail("\(error)")
                return
            }
            XCTAssertGreaterThan(shareResponse!.polling_id, "1111")
            sharePollingId = shareResponse!
            shareExpectation.fulfill()
        }
        wait(for: [shareExpectation], timeout: 10)

        let pollingExpectation = expectation(description: "share polling")
        program.pollCustomShare(accessToken: accessToken!, pollingResponse: sharePollingId) {
                        customShareResult, error in
            if let error = error {
                XCTFail("\(error)")
                return
            }
            XCTAssertGreaterThan(customShareResult!.share_id, "1111")
            pollingExpectation.fulfill()
        }
        wait(for: [pollingExpectation], timeout: 10)

    }

}