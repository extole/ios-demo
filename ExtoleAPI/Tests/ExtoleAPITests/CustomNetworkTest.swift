//Copyright © 2019 Extole. All rights reserved.

import Foundation
import XCTest
@testable import ExtoleAPI

class CustomNetworkTest : XCTestCase {
    
    class CustomExecutor : NetworkExecutor {
        func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
            let token = ExtoleAPI.Authorization.TokenResponse(access_token: "custom_executor", expires_in: 100, scopes: ["UPDATE_PROFILE"])
            let response = HTTPURLResponse.init(url: request.url!,
                                                statusCode: 200,
                                                httpVersion: "HTTP/1.1",
                                                headerFields: nil)
            let encoded = try? JSONEncoder().encode(token)
            completionHandler(encoded, response, nil)
        }
    }
    
    class CustomNetwork: Network {
        override func processRequest<T>(with request: URLRequest,
                                           success: @escaping (T) -> Void,
                                           error: @escaping (ExtoleAPI.Error) -> Void)
            where T : Decodable, T : Encodable {
                let token = ExtoleAPI.Authorization.TokenResponse(access_token: "custom", expires_in: 100, scopes: ["UPDATE_PROFILE"])
                success(token as! T)
        }
    }

    func testCustomToken() {
        let network = CustomNetwork()
        
        let extoleApi = ExtoleAPI(programDomain: "virtual.extole.io",
                              network: network)
        let promise = expectation(description: "get token response")
        extoleApi.createSession(success: { session in
            XCTAssertEqual("custom", session.accessToken)
            promise.fulfill()
        }, error: { error in
            XCTFail(String(reflecting: error))
        })
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDataToken() {
        let network = Network(executor: CustomExecutor())
        
        let extoleApi = ExtoleAPI(programDomain: "virtual.extole.io", network: network)
        let promise = expectation(description: "get token response")
        extoleApi.createSession(success: { session in
            XCTAssertEqual("custom_executor", session.accessToken)
            promise.fulfill()
        }, error: { error in
            XCTFail(String(reflecting: error))
        })
        waitForExpectations(timeout: 5, handler: nil)
    }
}